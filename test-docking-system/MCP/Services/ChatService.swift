import Foundation
import Combine
import OSLog

// MARK: - Chat Service Protocol

public protocol ChatServiceProtocol: Sendable {
    func sendMessage(_ message: String, context: ChatContext) async throws -> AsyncThrowingStream<StreamEvent, Error>
    func sendMessages(_ messages: [ChatMessage], context: ChatContext) async throws -> AsyncThrowingStream<StreamEvent, Error>
}

// MARK: - Chat Types

public struct ChatMessage: Codable, Sendable {
    public let role: String
    public let content: String
    public let name: String?
    public let toolCalls: [ChatToolCall]?
    public let toolCallId: String?
    
    public init(role: String, content: String, name: String? = nil, toolCalls: [ChatToolCall]? = nil, toolCallId: String? = nil) {
        self.role = role
        self.content = content
        self.name = name
        self.toolCalls = toolCalls
        self.toolCallId = toolCallId
    }
    
    public static func user(_ content: String) -> ChatMessage {
        ChatMessage(role: "user", content: content)
    }
    
    public static func assistant(_ content: String) -> ChatMessage {
        ChatMessage(role: "assistant", content: content)
    }
    
    public static func system(_ content: String) -> ChatMessage {
        ChatMessage(role: "system", content: content)
    }
    
    public static func tool(_ content: String, toolCallId: String) -> ChatMessage {
        ChatMessage(role: "tool", content: content, toolCallId: toolCallId)
    }
    
    enum CodingKeys: String, CodingKey {
        case role, content, name
        case toolCalls = "tool_calls"
        case toolCallId = "tool_call_id"
    }
}

public struct ChatToolCall: Codable, Sendable {
    public let id: String
    public let type: String
    public let function: ChatFunction
    
    public struct ChatFunction: Codable, Sendable {
        public let name: String
        public let arguments: String
    }
}

public struct ChatContext: Sendable {
    public let systemPrompt: String?
    public let tools: [ToolDefinition]
    public let maxTokens: Int
    public let temperature: Double
    public let projectContext: String?
    
    public init(
        systemPrompt: String? = nil,
        tools: [ToolDefinition] = [],
        maxTokens: Int = 4096,
        temperature: Double = 0.7,
        projectContext: String? = nil
    ) {
        self.systemPrompt = systemPrompt
        self.tools = tools
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.projectContext = projectContext
    }
}

// MARK: - OpenAI Chat Service

public actor OpenAIChatService: ChatServiceProtocol {
    private let apiKey: String
    private let baseURL: URL
    private let model: String
    private let session: URLSession
    
    public init(
        apiKey: String,
        baseURL: URL = URL(string: "https://api.openai.com/v1")!,
        model: String = MCPDefaults.defaultChatModel
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        self.session = URLSession(configuration: config)
    }
    
    public func sendMessage(_ message: String, context: ChatContext) async throws -> AsyncThrowingStream<StreamEvent, Error> {
        let messages = [ChatMessage.user(message)]
        return try await sendMessages(messages, context: context)
    }
    
    public func sendMessages(_ messages: [ChatMessage], context: ChatContext) async throws -> AsyncThrowingStream<StreamEvent, Error> {
        let url = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var allMessages = messages
        if let systemPrompt = context.systemPrompt {
            allMessages.insert(.system(systemPrompt), at: 0)
        }
        
        var body: [String: Any] = [
            "model": model,
            "messages": allMessages.map { openAIMessagePayload(from: $0) },
            "max_completion_tokens": context.maxTokens,
            "temperature": context.temperature,
            "modalities": ["text"],
            "stream": true
        ]
        
        if !context.tools.isEmpty {
            body["tools"] = context.tools.map { toolToOpenAIFormat($0) }
            body["tool_choice"] = "auto"
        }
        
        let payloadData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = payloadData
        if let payloadString = String(data: payloadData, encoding: .utf8) {
            MCPLog.chatService.debug("Sending request: \(payloadString)")
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: ToolError.networkError("Invalid response"))
                        return
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        var errorData = Data()
                        for try await byte in bytes {
                            errorData.append(byte)
                        }
                        let apiErrorMessage = parseAPIError(from: errorData)
                        MCPLog.chatService.error("HTTP error: \(httpResponse.statusCode) - \(apiErrorMessage)")
                        continuation.finish(throwing: ToolError.networkError("HTTP \(httpResponse.statusCode): \(apiErrorMessage)"))
                        return
                    }
                    
                    var currentToolCall: (id: String, name: String, arguments: String)?
                    
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))
                        
                        if jsonString == "[DONE]" {
                            if let toolCall = currentToolCall {
                                let call = ToolCall(
                                    toolID: toolCall.name,
                                    parameters: parseToolArguments(toolCall.arguments)
                                )
                                continuation.yield(.toolCallComplete(call))
                            }
                            continuation.yield(.complete)
                            continuation.finish()
                            return
                        }
                        
                        guard let data = jsonString.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any] else {
                            continue
                        }
                        
                        // Handle content (new responses format sends array of content parts)
                        if let contentArray = delta["content"] as? [[String: Any]] {
                            for item in contentArray {
                                if let text = item["text"] as? String {
                                    continuation.yield(.delta(text))
                                }
                            }
                        } else if let content = delta["content"] as? String {
                            continuation.yield(.delta(content))
                        }
                        
                        // Handle tool calls
                        if let toolCalls = delta["tool_calls"] as? [[String: Any]],
                           let toolCall = toolCalls.first {
                            if let function = toolCall["function"] as? [String: Any] {
                                if let name = function["name"] as? String {
                                    let id = toolCall["id"] as? String ?? UUID().uuidString
                                    currentToolCall = (id, name, "")
                                    let call = ToolCall(toolID: name, parameters: [:])
                                    continuation.yield(.toolCallStart(call))
                                }
                                if let args = function["arguments"] as? String {
                                    currentToolCall?.arguments += args
                                }
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    MCPLog.chatService.error("Streaming error: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func toolToOpenAIFormat(_ tool: ToolDefinition) -> [String: Any] {
        var properties: [String: Any] = [:]
        var required: [String] = []
        
        for param in tool.parameters {
            properties[param.name] = schema(for: param)
            if param.required {
                required.append(param.name)
            }
        }
        
        return [
            "type": "function",
            "function": [
                "name": tool.id,
                "description": tool.description,
                "parameters": [
                    "type": "object",
                    "properties": properties,
                    "required": required
                ]
            ]
        ]
    }
    
    private func parseToolArguments(_ jsonString: String) -> [String: ToolParameterValue] {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        
        var params: [String: ToolParameterValue] = [:]
        for (key, value) in json {
            if let s = value as? String {
                params[key] = .string(s)
            } else if let n = value as? Double {
                params[key] = .number(n)
            } else if let b = value as? Bool {
                params[key] = .boolean(b)
            }
        }
        return params
    }
    
    private func schema(for parameter: ToolParameter) -> [String: Any] {
        var schema: [String: Any] = [
            "type": jsonSchemaType(for: parameter.type),
            "description": parameter.description
        ]
        
        switch parameter.type {
        case .array:
            schema["items"] = ["type": "string"]
        case .object:
            schema["additionalProperties"] = true
        case .file, .image, .audio:
            schema["format"] = parameter.type.rawValue
        default:
            break
        }
        
        if let options = parameter.options, !options.isEmpty {
            schema["enum"] = options
        }
        
        if let defaultValue = parameter.defaultValue {
            schema["default"] = defaultValue
        }
        
        return schema
    }
    
    private func jsonSchemaType(for type: ToolParameter.ParameterType) -> String {
        switch type {
        case .string: return "string"
        case .number: return "number"
        case .boolean: return "boolean"
        case .array: return "array"
        case .object: return "object"
        case .file, .image, .audio: return "string"
        }
    }
    
    private func parseAPIError(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any] {
            return error["message"] as? String ?? "Unknown error"
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }
    
    private func openAIMessagePayload(from message: ChatMessage) -> [String: Any] {
        var dict: [String: Any] = [
            "role": message.role,
            "content": message.content
        ]
        
        if let name = message.name {
            dict["name"] = name
        }
        
        if let toolCallId = message.toolCallId {
            dict["tool_call_id"] = toolCallId
        }
        
        if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
            dict["tool_calls"] = toolCalls.map { call in
                [
                    "id": call.id,
                    "type": call.type,
                    "function": [
                        "name": call.function.name,
                        "arguments": call.function.arguments
                    ]
                ]
            }
        }
        
        return dict
    }
}

// MARK: - Chat Service Manager

@MainActor
public final class ChatServiceManager: ObservableObject {
    public static let shared = ChatServiceManager()
    private static let apiKeyDefaultsKey = "mcp_openai_api_key"
    private static let modelDefaultsKey = "mcp_chat_model"
    private var hasFinishedInitializing = false
    
    @Published public var apiKey: String = "" {
        didSet {
            guard hasFinishedInitializing else { return }
            UserDefaults.standard.set(apiKey, forKey: Self.apiKeyDefaultsKey)
            updateService()
        }
    }
    @Published public var model: String = MCPDefaults.defaultChatModel {
        didSet {
            guard hasFinishedInitializing else { return }
            UserDefaults.standard.set(model, forKey: Self.modelDefaultsKey)
            updateService()
        }
    }
    
    public private(set) var service: any ChatServiceProtocol
    
    private init() {
        let storedKey = UserDefaults.standard.string(forKey: Self.apiKeyDefaultsKey) ?? ""
        let storedModel = UserDefaults.standard.string(forKey: Self.modelDefaultsKey) ?? MCPDefaults.defaultChatModel
        self.apiKey = storedKey
        self.model = storedModel
        self.service = OpenAIChatService(apiKey: storedKey, model: storedModel)
        hasFinishedInitializing = true
    }
    
    private func updateService() {
        service = OpenAIChatService(apiKey: apiKey, model: model)
        MCPLog.chatService.info("Configured OpenAI service with model \(self.model, privacy: .public)")
    }
    
    public func setAPIKey(_ key: String) {
        apiKey = key
    }
}
