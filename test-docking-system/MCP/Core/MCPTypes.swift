import Foundation
import SwiftUI
import Combine

// MARK: - MCP Defaults

public enum MCPDefaults {
    public static let defaultChatModel = "gpt-4.1"
}

// MARK: - MCP Protocol Types

/// Unique identifier for tools
public typealias ToolID = String

/// Parameter definition for a tool
public struct ToolParameter: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let type: ParameterType
    public let required: Bool
    public let defaultValue: String?
    public let options: [String]?
    
    public enum ParameterType: String, Codable, Sendable {
        case string
        case number
        case boolean
        case array
        case object
        case file
        case image
        case audio
    }
    
    public init(
        name: String,
        description: String,
        type: ParameterType,
        required: Bool = true,
        defaultValue: String? = nil,
        options: [String]? = nil
    ) {
        self.id = name
        self.name = name
        self.description = description
        self.type = type
        self.required = required
        self.defaultValue = defaultValue
        self.options = options
    }
}

/// Tool definition that can be registered with the MCP system
public struct ToolDefinition: Identifiable, Sendable {
    public let id: ToolID
    public let name: String
    public let description: String
    public let category: ToolCategory
    public let parameters: [ToolParameter]
    public let icon: String
    public let isAsync: Bool
    
    public enum ToolCategory: String, CaseIterable, Sendable {
        case file = "File Operations"
        case code = "Code Generation"
        case image = "Image Generation"
        case audio = "Audio Generation"
        case chat = "Chat & AI"
        case project = "Project Management"
        case web = "Web Development"
        case system = "System"
        case custom = "Custom"
    }
    
    public init(
        id: ToolID,
        name: String,
        description: String,
        category: ToolCategory,
        parameters: [ToolParameter] = [],
        icon: String = "wrench",
        isAsync: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.parameters = parameters
        self.icon = icon
        self.isAsync = isAsync
    }
}

/// Result of executing a tool
public enum ToolResult: Sendable {
    case success(ToolOutput)
    case error(ToolError)
    case streaming(AsyncStream<ToolOutput>)
    
    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

/// Output types from tool execution
public enum ToolOutput: Sendable {
    case text(String)
    case markdown(String)
    case code(String, language: String)
    case image(Data, mimeType: String)
    case audio(Data, mimeType: String)
    case file(URL)
    case json(Data)
    case html(String)
    case progress(Double, message: String)
    case suggestion(AgentSuggestion)
    case compound([ToolOutput])
    
    public var textValue: String? {
        switch self {
        case .text(let s), .markdown(let s), .html(let s):
            return s
        case .code(let s, _):
            return s
        default:
            return nil
        }
    }
}

/// Error from tool execution
public struct ToolError: Error, Sendable, Equatable, LocalizedError {
    public let code: String
    public let message: String
    public let details: String?
    public let recoverable: Bool
    public let suggestions: [String]
    
    public init(
        code: String,
        message: String,
        details: String? = nil,
        recoverable: Bool = false,
        suggestions: [String] = []
    ) {
        self.code = code
        self.message = message
        self.details = details
        self.recoverable = recoverable
        self.suggestions = suggestions
    }
    
    public static func invalidParameter(_ name: String) -> ToolError {
        ToolError(code: "INVALID_PARAM", message: "Invalid parameter: \(name)")
    }
    
    public static func missingParameter(_ name: String) -> ToolError {
        ToolError(code: "MISSING_PARAM", message: "Missing required parameter: \(name)")
    }
    
    public static func executionFailed(_ message: String) -> ToolError {
        ToolError(code: "EXEC_FAILED", message: message)
    }
    
    public static func networkError(_ message: String) -> ToolError {
        ToolError(code: "NETWORK_ERROR", message: message, recoverable: true)
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        details ?? message
    }
    
    public var failureReason: String? {
        message
    }
    
    public var recoverySuggestion: String? {
        suggestions.isEmpty ? nil : suggestions.joined(separator: "\n")
    }
}

/// Tool invocation request
public struct ToolInvocation: Identifiable, Sendable {
    public let id: UUID
    public let toolID: ToolID
    public let parameters: [String: ToolParameterValue]
    public let timestamp: Date
    public let context: InvocationContext
    
    public init(
        toolID: ToolID,
        parameters: [String: ToolParameterValue],
        context: InvocationContext = InvocationContext()
    ) {
        self.id = UUID()
        self.toolID = toolID
        self.parameters = parameters
        self.timestamp = Date()
        self.context = context
    }
}

/// Value types for tool parameters
public enum ToolParameterValue: Sendable, Codable {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case array([ToolParameterValue])
    case object([String: ToolParameterValue])
    case null
    
    public var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }
    
    public var numberValue: Double? {
        if case .number(let n) = self { return n }
        return nil
    }
    
    public var boolValue: Bool? {
        if case .boolean(let b) = self { return b }
        return nil
    }
    
    // Codable implementation
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let n = try? container.decode(Double.self) {
            self = .number(n)
        } else if let b = try? container.decode(Bool.self) {
            self = .boolean(b)
        } else if container.decodeNil() {
            self = .null
        } else {
            self = .null
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .number(let n): try container.encode(n)
        case .boolean(let b): try container.encode(b)
        case .array(let values): try container.encode(values)
        case .object(let dict): try container.encode(dict)
        case .null: try container.encodeNil()
        }
    }
    
    // MARK: - JSON Conversion Helpers
    func jsonValue() -> Any? {
        switch self {
        case .string(let s): return s
        case .number(let n): return n
        case .boolean(let b): return b
        case .array(let values):
            return values.compactMap { $0.jsonValue() }
        case .object(let dict):
            var result: [String: Any] = [:]
            for (key, value) in dict {
                result[key] = value.jsonValue() ?? NSNull()
            }
            return result
        case .null:
            return NSNull()
        }
    }
}

public extension Dictionary where Key == String, Value == ToolParameterValue {
    func jsonObject() -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in self {
            result[key] = value.jsonValue() ?? NSNull()
        }
        return result
    }
    
    func jsonString(prettyPrinted: Bool = false) -> String? {
        let object = jsonObject()
        guard JSONSerialization.isValidJSONObject(object) else { return nil }
        if let data = try? JSONSerialization.data(withJSONObject: object, options: prettyPrinted ? [.prettyPrinted] : []) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}

/// Context for tool invocation
public struct InvocationContext: Sendable {
    public let workingDirectory: URL?
    public let currentFile: URL?
    public let selectedText: String?
    public let projectRoot: URL?
    public let environment: [String: String]
    
    public init(
        workingDirectory: URL? = nil,
        currentFile: URL? = nil,
        selectedText: String? = nil,
        projectRoot: URL? = nil,
        environment: [String: String] = [:]
    ) {
        self.workingDirectory = workingDirectory
        self.currentFile = currentFile
        self.selectedText = selectedText
        self.projectRoot = projectRoot
        self.environment = environment
    }
}

// MARK: - Agent Types

/// Suggestion from the agent to help the user
public struct AgentSuggestion: Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let description: String
    public let action: SuggestionAction
    public let priority: Priority
    public let icon: String
    
    public enum Priority: Int, Comparable, Sendable {
        case low = 0
        case medium = 1
        case high = 2
        
        public static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    public enum SuggestionAction: Sendable {
        case runTool(ToolID, parameters: [String: ToolParameterValue])
        case insertCode(String, language: String)
        case openFile(URL)
        case executeCommand(String)
        case askFollowUp(String)
        case custom(String)
    }
    
    public init(
        title: String,
        description: String,
        action: SuggestionAction,
        priority: Priority = .medium,
        icon: String = "lightbulb"
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.action = action
        self.priority = priority
        self.icon = icon
    }
}

/// Message in agent conversation
public struct AgentMessage: Identifiable, Sendable {
    public let id: UUID
    public let role: Role
    public let content: MessageContent
    public let timestamp: Date
    public let toolCalls: [ToolCall]?
    public let suggestions: [AgentSuggestion]
    
    public enum Role: String, Sendable {
        case user
        case assistant
        case system
        case tool
    }
    
    public enum MessageContent: Sendable {
        case text(String)
        case toolResult(ToolResult)
        case thinking(String)
        case image(Data)
        case audio(Data)
        case compound([MessageContent])
    }
    
    public init(
        role: Role,
        content: MessageContent,
        toolCalls: [ToolCall]? = nil,
        suggestions: [AgentSuggestion] = []
    ) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.toolCalls = toolCalls
        self.suggestions = suggestions
    }
    
    public var textContent: String? {
        if case .text(let s) = content { return s }
        return nil
    }
}

/// Tool call from agent
public struct ToolCall: Identifiable, Sendable {
    public let id: UUID
    public let toolID: ToolID
    public let parameters: [String: ToolParameterValue]
    public var status: Status
    public var result: ToolResult?
    
    public enum Status: Sendable {
        case pending
        case running
        case completed
        case failed
    }
    
    public init(toolID: ToolID, parameters: [String: ToolParameterValue]) {
        self.id = UUID()
        self.toolID = toolID
        self.parameters = parameters
        self.status = .pending
    }
}

// MARK: - Streaming Types

/// Stream event for real-time updates
public enum StreamEvent: Sendable {
    case delta(String)
    case toolCallStart(ToolCall)
    case toolCallComplete(ToolCall)
    case thinking(String)
    case suggestion(AgentSuggestion)
    case complete
    case error(ToolError)
}

/// Aggregated result produced after consuming the streaming response
public struct StreamOutcome: Sendable {
    public let content: String
    public let toolCalls: [ToolCall]
    public let suggestions: [AgentSuggestion]

    public init(
        content: String = "",
        toolCalls: [ToolCall] = [],
        suggestions: [AgentSuggestion] = []
    ) {
        self.content = content
        self.toolCalls = toolCalls
        self.suggestions = suggestions
    }
}

/// Configuration for API services
public struct APIConfiguration: Sendable {
    public let apiKey: String
    public let baseURL: URL
    public let model: String
    public let maxTokens: Int
    public let temperature: Double
    
    public init(
        apiKey: String,
        baseURL: URL,
        model: String = MCPDefaults.defaultChatModel,
        maxTokens: Int = 4096,
        temperature: Double = 0.7
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
    
    public static var openAI: APIConfiguration {
        APIConfiguration(
            apiKey: "",
            baseURL: URL(string: "https://api.openai.com/v1")!,
            model: MCPDefaults.defaultChatModel
        )
    }
}
