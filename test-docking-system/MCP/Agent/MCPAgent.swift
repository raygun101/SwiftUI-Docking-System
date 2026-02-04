import Foundation
import Combine
import SwiftUI

// MARK: - MCP Agent

/// The main AI agent that orchestrates tool execution, reasoning, and conversation
@MainActor
public final class MCPAgent: ObservableObject {
    public static let shared = MCPAgent()
    
    // MARK: - Published State
    
    @Published public private(set) var messages: [AgentMessage] = []
    @Published public private(set) var isProcessing: Bool = false
    @Published public private(set) var isThinking: Bool = false
    @Published public private(set) var currentThought: String = ""
    @Published public private(set) var streamingContent: String = ""
    @Published public private(set) var pendingToolCalls: [ToolCall] = []
    @Published public private(set) var suggestions: [AgentSuggestion] = []
    @Published public private(set) var error: ToolError?
    
    @Published public var autoExecuteTools: Bool = true
    @Published public var showThinking: Bool = true
    @Published public var maxToolIterations: Int = 10
    
    // MARK: - Context
    
    @Published public var projectContext: ProjectContext?
    
    public struct ProjectContext {
        public let rootURL: URL
        public let openFiles: [URL]
        public let activeFile: URL?
        public let selectedText: String?
        
        public init(rootURL: URL, openFiles: [URL] = [], activeFile: URL? = nil, selectedText: String? = nil) {
            self.rootURL = rootURL
            self.openFiles = openFiles
            self.activeFile = activeFile
            self.selectedText = selectedText
        }
    }
    
    // MARK: - Private
    
    private let toolRegistry = MCPToolRegistry.shared
    private let toolExecutor = MCPToolExecutor.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentTask: Task<Void, Never>?
    private var hasInitializedIntro = false
    private let introMessageText = "I'm your AI assistant ready to help! I can create files, generate code, images, and audio for your projects."
    
    // MARK: - System Prompt
    
    private var systemPrompt: String {
        """
        You are an expert AI coding assistant integrated into an IDE. You help users build beautiful websites with images and sounds.
        
        ## Capabilities
        - Create, edit, and manage project files
        - Generate code (HTML, CSS, JavaScript, Swift, etc.)
        - Generate images using AI (DALL-E)
        - Generate audio/speech using AI (TTS)
        - Execute project commands
        - Search and analyze code
        
        ## Guidelines
        1. Always think step-by-step before taking actions
        2. Use tools to accomplish tasks - don't just describe what could be done
        3. When creating websites, make them visually stunning with modern design
        4. Proactively suggest improvements and next steps
        5. Explain what you're doing and why
        6. Handle errors gracefully and suggest alternatives
        
        ## Project Context
        \(projectContextDescription)
        
        ## Available Tools
        \(availableToolsDescription)
        
        Be helpful, creative, and thorough. Build amazing things!
        """
    }
    
    private var projectContextDescription: String {
        guard let context = projectContext else {
            return "No project currently open."
        }
        var desc = "Project root: \(context.rootURL.path)"
        if !context.openFiles.isEmpty {
            desc += "\nOpen files: \(context.openFiles.map { $0.lastPathComponent }.joined(separator: ", "))"
        }
        if let active = context.activeFile {
            desc += "\nActive file: \(active.lastPathComponent)"
        }
        if let selected = context.selectedText, !selected.isEmpty {
            desc += "\nSelected text: \(selected.prefix(200))..."
        }
        return desc
    }
    
    private var availableToolsDescription: String {
        let tools = toolRegistry.allDefinitions()
        return tools.map { "- \($0.name): \($0.description)" }.joined(separator: "\n")
    }
    
    // MARK: - Initialization
    
    private init() {
        registerBuiltInTools()
        ensureIntroMessage()
    }
    
    private func registerBuiltInTools() {
        registerBuiltInTool(ImageGenerationTool())
        registerBuiltInTool(TextToSpeechTool())
        registerBuiltInTool(TranscriptionTool())
    }

    private func registerBuiltInTool(_ tool: some MCPTool) {
        let toolID = tool.definition.id
        guard toolRegistry.tool(for: toolID) == nil else {
            MCPLog.agent.debug("Skipping built-in tool registration for already-registered id \(toolID)")
            return
        }
        toolRegistry.register(tool)
    }
    
    // MARK: - Public API
    
    /// Send a message to the agent
    public func send(_ message: String) async {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Cancel any ongoing processing
        currentTask?.cancel()
        
        // Add user message
        let userMessage = AgentMessage(role: .user, content: .text(message))
        messages.append(userMessage)
        MCPLog.agent.info("Queued user message: \(message, privacy: .public)")
        
        // Clear previous state
        streamingContent = ""
        suggestions = []
        error = nil
        
        // Start processing
        MCPLog.agent.info("Starting agent processing for \(self.messages.count) messages")
        currentTask = Task {
            await processConversation()
        }
    }
    
    /// Execute a suggestion
    public func executeSuggestion(_ suggestion: AgentSuggestion) async {
        switch suggestion.action {
        case .runTool(let toolID, let parameters):
            let result = await toolExecutor.execute(toolID: toolID, parameters: parameters)
            handleToolResult(result, for: toolID)
            
        case .insertCode(let code, let language):
            // Notify IDE to insert code
            NotificationCenter.default.post(
                name: .agentInsertCode,
                object: nil,
                userInfo: ["code": code, "language": language]
            )
            
        case .openFile(let url):
            NotificationCenter.default.post(
                name: .agentOpenFile,
                object: nil,
                userInfo: ["url": url]
            )
            
        case .executeCommand(let command):
            await send("Execute: \(command)")
            
        case .askFollowUp(let question):
            await send(question)
            
        case .custom(let action):
            await send(action)
        }
    }
    
    /// Clear conversation history
    public func clearHistory() {
        messages.removeAll()
        suggestions.removeAll()
        streamingContent = ""
        currentThought = ""
        error = nil
        hasInitializedIntro = false
        ensureIntroMessage()
        MCPLog.agent.info("Cleared conversation history")
    }
    
    /// Stop current processing
    public func stop() {
        currentTask?.cancel()
        isProcessing = false
        isThinking = false
    }
    
    // MARK: - Processing
    
    private func processConversation() async {
        isProcessing = true
        MCPLog.agent.info("Process conversation loop started")
        defer {
            isProcessing = false
            MCPLog.agent.info("Process conversation loop finished")
        }
        
        var iteration = 0
        var needsMoreProcessing = true
        
        while needsMoreProcessing && iteration < maxToolIterations {
            iteration += 1
            
            do {
                needsMoreProcessing = try await runAgentLoop()
            } catch {
                self.error = ToolError.executionFailed(error.localizedDescription)
                break
            }
            
            if Task.isCancelled { break }
        }
    }
    
    private func runAgentLoop() async throws -> Bool {
        isThinking = true
        currentThought = "Analyzing request..."
        MCPLog.agent.debug("Running agent loop (iteration start)")
        
        let context = buildChatContext()
        let chatMessages = buildChatMessages()
        let outcome = try await streamResponse(messages: chatMessages, context: context)
        appendAssistantMessageIfNeeded(outcome)
        return await handleToolCallsIfNeeded(outcome.toolCalls)
    }

    private func buildChatContext() -> ChatContext {
        ChatContext(
            systemPrompt: systemPrompt,
            tools: toolRegistry.allDefinitions(),
            maxTokens: 4096,
            temperature: 0.7,
            projectContext: projectContextDescription
        )
    }

    private func buildChatMessages() -> [ChatMessage] {
        messages.compactMap { msg -> ChatMessage? in
            switch msg.role {
            case .user:
                if let text = msg.textContent {
                    return .user(text)
                }
            case .assistant:
                if let text = msg.textContent {
                    let chatToolCalls = chatToolCalls(from: msg.toolCalls)
                    return ChatMessage(role: "assistant", content: text, toolCalls: chatToolCalls)
                }
            case .tool:
                if case .toolResult(let result) = msg.content,
                   let toolCall = msg.toolCalls?.first {
                    let resultText = resultToString(result)
                    return .tool(resultText, toolCallId: toolCall.id.uuidString)
                }
            case .system:
                if let text = msg.textContent {
                    return .system(text)
                }
            }
            return nil
        }
    }

    private func streamResponse(messages: [ChatMessage], context: ChatContext) async throws -> StreamOutcome {
        let service = ChatServiceManager.shared.service
        let stream = try await service.sendMessages(messages, context: context)
        var collectedContent = ""
        var toolCalls: [ToolCall] = []
        var collectedSuggestions: [AgentSuggestion] = []
        
        isThinking = false
        
        for try await event in stream {
            if Task.isCancelled { break }
            
            switch event {
            case .delta(let text):
                collectedContent += text
                streamingContent = collectedContent
                MCPLog.agent.debug("Streaming delta: \(text, privacy: .public)")
                
            case .thinking(let thought):
                isThinking = true
                currentThought = thought
                MCPLog.agent.debug("LLM thinking: \(thought, privacy: .public)")
                
            case .toolCallStart(let call):
                var mutableCall = call
                mutableCall.status = .running
                toolCalls.append(mutableCall)
                pendingToolCalls = toolCalls
                MCPLog.agent.info("Tool call started: \(call.toolID, privacy: .public)")
                
            case .toolCallComplete(var call):
                call.status = .completed
                if let index = toolCalls.firstIndex(where: { $0.toolID == call.toolID }) {
                    toolCalls[index] = call
                }
                pendingToolCalls = toolCalls
                MCPLog.agent.info("Tool call completed: \(call.toolID, privacy: .public)")
                
            case .suggestion(let suggestion):
                collectedSuggestions.append(suggestion)
                MCPLog.agent.debug("Suggestion received: \(suggestion.title, privacy: .public)")
                
            case .complete:
                MCPLog.agent.info("Stream marked complete")
                break
                
            case .error(let error):
                self.error = error
                MCPLog.agent.error("Stream error: \(error.message, privacy: .public)")
            }
        }
        
        isThinking = false
        streamingContent = ""
        
        return StreamOutcome(
            content: collectedContent,
            toolCalls: toolCalls,
            suggestions: collectedSuggestions
        )
    }

    private func appendAssistantMessageIfNeeded(_ outcome: StreamOutcome) {
        guard !outcome.content.isEmpty || !outcome.toolCalls.isEmpty else { return }
        let assistantMessage = AgentMessage(
            role: .assistant,
            content: .text(outcome.content),
            toolCalls: outcome.toolCalls.isEmpty ? nil : outcome.toolCalls,
            suggestions: outcome.suggestions
        )
        messages.append(assistantMessage)
        suggestions = outcome.suggestions
    }

    private func handleToolCallsIfNeeded(_ toolCalls: [ToolCall]) async -> Bool {
        guard !toolCalls.isEmpty else { return false }
        guard autoExecuteTools else { return false }
        for call in toolCalls {
            if Task.isCancelled { break }
            let result = await toolExecutor.execute(
                toolID: call.toolID,
                parameters: call.parameters,
                context: makeInvocationContext()
            )
            var completedCall = call
            completedCall.status = .completed
            completedCall.result = result
            let toolMessage = AgentMessage(
                role: .tool,
                content: .toolResult(result),
                toolCalls: [completedCall]
            )
            messages.append(toolMessage)
        }
        pendingToolCalls = []
        return true
    }
    
    private func makeInvocationContext() -> InvocationContext {
        InvocationContext(
            workingDirectory: projectContext?.rootURL,
            currentFile: projectContext?.activeFile,
            selectedText: projectContext?.selectedText,
            projectRoot: projectContext?.rootURL
        )
    }
    
    private func handleToolResult(_ result: ToolResult, for toolID: String) {
        let toolMessage = AgentMessage(
            role: .tool,
            content: .toolResult(result),
            toolCalls: [ToolCall(toolID: toolID, parameters: [:])]
        )
        messages.append(toolMessage)
    }
    
    private func resultToString(_ result: ToolResult) -> String {
        switch result {
        case .success(let output):
            return outputToString(output)
        case .error(let error):
            return "Error: \(error.message)"
        case .streaming:
            return "[Streaming result]"
        }
    }
    
    private func outputToString(_ output: ToolOutput) -> String {
        switch output {
        case .text(let s), .markdown(let s), .html(let s):
            return s
        case .code(let code, let lang):
            return "```\(lang)\n\(code)\n```"
        case .image:
            return "[Image generated]"
        case .audio:
            return "[Audio generated]"
        case .file(let url):
            return "File: \(url.path)"
        case .json(let data):
            return String(data: data, encoding: .utf8) ?? "[JSON data]"
        case .progress(let value, let msg):
            return "Progress: \(Int(value * 100))% - \(msg)"
        case .suggestion(let s):
            return "Suggestion: \(s.title)"
        case .compound(let outputs):
            return outputs.map { outputToString($0) }.joined(separator: "\n")
        }
    }
    
    private func chatToolCalls(from toolCalls: [ToolCall]?) -> [ChatToolCall]? {
        guard let toolCalls, !toolCalls.isEmpty else { return nil }
        return toolCalls.map { call in
            ChatToolCall(
                id: call.id.uuidString,
                type: "function",
                function: .init(
                    name: call.toolID,
                    arguments: call.parameters.jsonString() ?? "{}"
                )
            )
        }
    }
    
    public func ensureIntroMessage() {
        guard !hasInitializedIntro, messages.isEmpty else { return }
        let intro = AgentMessage(role: .assistant, content: .text(introMessageText))
        messages.append(intro)
        hasInitializedIntro = true
    }
}

// MARK: - Notifications

public extension Notification.Name {
    static let agentInsertCode = Notification.Name("MCPAgentInsertCode")
    static let agentOpenFile = Notification.Name("MCPAgentOpenFile")
    static let agentCreateFile = Notification.Name("MCPAgentCreateFile")
    static let agentExecuteCommand = Notification.Name("MCPAgentExecuteCommand")
    static let agentFileDidChange = Notification.Name("MCPAgentFileDidChange")
}

// MARK: - Agent Reasoning Engine

/// Handles complex reasoning and planning for multi-step tasks
public actor AgentReasoningEngine {
    public struct Plan {
        public let goal: String
        public var steps: [PlanStep]
        public var currentStepIndex: Int = 0
        
        public var currentStep: PlanStep? {
            guard currentStepIndex < steps.count else { return nil }
            return steps[currentStepIndex]
        }
        
        public var isComplete: Bool {
            currentStepIndex >= steps.count
        }
        
        public var progress: Double {
            guard !steps.isEmpty else { return 1.0 }
            return Double(currentStepIndex) / Double(steps.count)
        }
    }
    
    public struct PlanStep: Identifiable {
        public let id = UUID()
        public let description: String
        public let toolID: ToolID?
        public let parameters: [String: ToolParameterValue]
        public var status: Status = .pending
        public var result: ToolResult?
        
        public enum Status {
            case pending
            case inProgress
            case completed
            case failed
            case skipped
        }
    }
    
    public func createPlan(for goal: String, context: String) async -> Plan {
        // In a full implementation, this would use the LLM to create a plan
        // For now, return a simple plan structure
        
        var steps: [PlanStep] = []
        
        // Analyze the goal and create appropriate steps
        let lowercased = goal.lowercased()
        
        if lowercased.contains("website") || lowercased.contains("webpage") || lowercased.contains("page") {
            steps.append(PlanStep(
                description: "Create HTML structure",
                toolID: "create_file",
                parameters: ["type": "html"]
            ))
            steps.append(PlanStep(
                description: "Add CSS styling",
                toolID: "create_file",
                parameters: ["type": "css"]
            ))
            if lowercased.contains("image") {
                steps.append(PlanStep(
                    description: "Generate images",
                    toolID: "generate_image",
                    parameters: [:]
                ))
            }
            if lowercased.contains("sound") || lowercased.contains("audio") {
                steps.append(PlanStep(
                    description: "Add audio elements",
                    toolID: "text_to_speech",
                    parameters: [:]
                ))
            }
        }
        
        return Plan(goal: goal, steps: steps)
    }
    
    public func executePlan(_ plan: inout Plan, executor: MCPToolExecutor) async {
        while !plan.isComplete {
            guard var step = plan.currentStep else { break }
            
            step.status = .inProgress
            plan.steps[plan.currentStepIndex] = step
            
            if let toolID = step.toolID {
                let result = await executor.execute(
                    toolID: toolID,
                    parameters: step.parameters
                )
                
                step.result = result
                step.status = result.isSuccess ? .completed : .failed
            } else {
                step.status = .completed
            }
            
            plan.steps[plan.currentStepIndex] = step
            plan.currentStepIndex += 1
        }
    }
}

// MARK: - Suggestion Generator

/// Generates contextual suggestions based on current state
@MainActor
public final class SuggestionGenerator: ObservableObject {
    public static let shared = SuggestionGenerator()
    
    private let registry = MCPToolRegistry.shared
    
    private init() {}
    
    public func generateSuggestions(for context: MCPAgent.ProjectContext?) -> [AgentSuggestion] {
        var suggestions: [AgentSuggestion] = []
        
        // Always available suggestions
        suggestions.append(AgentSuggestion(
            title: "Create New File",
            description: "Create a new file in the project",
            action: .runTool("create_file", parameters: [:]),
            priority: .medium,
            icon: "doc.badge.plus"
        ))
        
        suggestions.append(AgentSuggestion(
            title: "Generate Image",
            description: "Create an AI-generated image",
            action: .askFollowUp("Generate an image of..."),
            priority: .medium,
            icon: "photo.artframe"
        ))
        
        suggestions.append(AgentSuggestion(
            title: "Build Website",
            description: "Start building a beautiful website",
            action: .askFollowUp("Help me create a modern website with..."),
            priority: .high,
            icon: "globe"
        ))
        
        // Context-specific suggestions
        if let ctx = context {
            if ctx.activeFile?.pathExtension == "html" {
                suggestions.insert(AgentSuggestion(
                    title: "Add Styling",
                    description: "Create or update CSS for this page",
                    action: .runTool("create_css", parameters: ["for_file": .string(ctx.activeFile!.path)]),
                    priority: .high,
                    icon: "paintbrush"
                ), at: 0)
            }
            
            if let selected = ctx.selectedText, !selected.isEmpty {
                suggestions.insert(AgentSuggestion(
                    title: "Explain Code",
                    description: "Explain the selected code",
                    action: .askFollowUp("Explain this code: \(selected.prefix(100))..."),
                    priority: .high,
                    icon: "questionmark.circle"
                ), at: 0)
            }
        }
        
        return suggestions
    }
    
    public func suggestionsForMessage(_ message: String) -> [AgentSuggestion] {
        var suggestions: [AgentSuggestion] = []
        let lowercased = message.lowercased()
        
        if lowercased.contains("image") || lowercased.contains("picture") {
            suggestions.append(AgentSuggestion(
                title: "Generate Image",
                description: "Generate an AI image based on your description",
                action: .runTool("generate_image", parameters: ["prompt": .string(message)]),
                priority: .high,
                icon: "photo.artframe"
            ))
        }
        
        if lowercased.contains("audio") || lowercased.contains("voice") || lowercased.contains("speak") {
            suggestions.append(AgentSuggestion(
                title: "Generate Audio",
                description: "Convert text to speech",
                action: .runTool("text_to_speech", parameters: ["text": .string(message)]),
                priority: .high,
                icon: "speaker.wave.3"
            ))
        }
        
        if lowercased.contains("html") || lowercased.contains("website") || lowercased.contains("page") {
            suggestions.append(AgentSuggestion(
                title: "Create HTML Page",
                description: "Generate an HTML page",
                action: .runTool("create_html_page", parameters: ["description": .string(message)]),
                priority: .high,
                icon: "doc.text"
            ))
        }
        
        return suggestions
    }
}
