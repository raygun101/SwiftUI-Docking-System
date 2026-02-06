import Foundation
import Combine

// MARK: - Tool Protocol

/// Protocol for implementing executable tools
public protocol MCPTool: Sendable {
    var definition: ToolDefinition { get }
    func execute(with invocation: ToolInvocation) async throws -> ToolResult
    func validate(parameters: [String: ToolParameterValue]) -> [ToolError]
}

extension MCPTool {
    public func validate(parameters: [String: ToolParameterValue]) -> [ToolError] {
        var errors: [ToolError] = []
        for param in definition.parameters where param.required {
            if parameters[param.name] == nil {
                errors.append(.missingParameter(param.name))
            }
        }
        return errors
    }
}

// MARK: - Tool Registry

/// Central registry for all MCP tools
@MainActor
public final class MCPToolRegistry: ObservableObject {
    public static let shared = MCPToolRegistry()
    
    @Published public private(set) var tools: [ToolID: any MCPTool] = [:]
    @Published public private(set) var categories: [ToolDefinition.ToolCategory: [ToolDefinition]] = [:]
    
    private var toolFactories: [ToolID: () -> any MCPTool] = [:]
    
    private init() {
        // Register built-in tools on init
        registerBuiltInTools()
    }
    
    // MARK: - Registration
    
    /// Register a tool with the registry
    public func register(_ tool: any MCPTool) {
        let def = tool.definition
        guard tools[def.id] == nil else {
            print("[MCPToolRegistry] Skipping duplicate tool id: \(def.id)")
            return
        }
        tools[def.id] = tool
        
        var categoryTools = categories[def.category] ?? []
        categoryTools.append(def)
        categories[def.category] = categoryTools
        
        print("[MCPToolRegistry] Registered tool: \(def.name) (\(def.id))")
    }
    
    /// Register a tool factory for lazy instantiation
    public func registerFactory(id: ToolID, factory: @escaping () -> any MCPTool) {
        toolFactories[id] = factory
    }
    
    /// Unregister a tool
    public func unregister(id: ToolID) {
        if let tool = tools.removeValue(forKey: id) {
            let category = tool.definition.category
            categories[category]?.removeAll { $0.id == id }
            pruneCategoryIfNeeded(category)
        }
        toolFactories.removeValue(forKey: id)
    }

    private func pruneCategoryIfNeeded(_ category: ToolDefinition.ToolCategory) {
        if categories[category]?.isEmpty == true {
            categories.removeValue(forKey: category)
        }
    }
    
    /// Get a tool by ID
    public func tool(for id: ToolID) -> (any MCPTool)? {
        if let tool = tools[id] {
            return tool
        }
        // Try factory
        if let factory = toolFactories[id] {
            let tool = factory()
            tools[id] = tool
            return tool
        }
        return nil
    }
    
    /// Get all tool definitions
    public func allDefinitions() -> [ToolDefinition] {
        tools.values.map { $0.definition }
    }
    
    /// Get definitions for a category
    public func definitions(for category: ToolDefinition.ToolCategory) -> [ToolDefinition] {
        categories[category] ?? []
    }
    
    /// Search tools by name or description
    public func search(query: String) -> [ToolDefinition] {
        let lowercased = query.lowercased()
        return allDefinitions().filter { def in
            def.name.lowercased().contains(lowercased) ||
            def.description.lowercased().contains(lowercased)
        }
    }
    
    // MARK: - Built-in Tools Registration
    
    private func registerBuiltInTools() {
        // These will be registered when the respective tool modules are loaded
    }
}

// MARK: - Tool Executor

/// Executes tools and manages invocation lifecycle
@MainActor
public final class MCPToolExecutor: ObservableObject {
    public static let shared = MCPToolExecutor()
    
    @Published public private(set) var activeInvocations: [UUID: ToolInvocation] = [:]
    @Published public private(set) var invocationHistory: [ToolInvocation] = []
    @Published public private(set) var results: [UUID: ToolResult] = [:]
    
    private let registry = MCPToolRegistry.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    /// Execute a tool invocation
    public func execute(_ invocation: ToolInvocation) async -> ToolResult {
        activeInvocations[invocation.id] = invocation
        
        defer {
            activeInvocations.removeValue(forKey: invocation.id)
            invocationHistory.append(invocation)
        }
        
        guard let tool = registry.tool(for: invocation.toolID) else {
            let error = ToolError(
                code: "TOOL_NOT_FOUND",
                message: "Tool '\(invocation.toolID)' not found",
                suggestions: registry.search(query: invocation.toolID).prefix(3).map { $0.name }
            )
            let result = ToolResult.error(error)
            results[invocation.id] = result
            return result
        }
        
        // Validate parameters
        let validationErrors = tool.validate(parameters: invocation.parameters)
        if !validationErrors.isEmpty {
            let error = ToolError(
                code: "VALIDATION_ERROR",
                message: "Parameter validation failed",
                details: validationErrors.map { $0.message }.joined(separator: ", ")
            )
            let result = ToolResult.error(error)
            results[invocation.id] = result
            return result
        }
        
        // Execute
        do {
            let result = try await tool.execute(with: invocation)
            results[invocation.id] = result
            return result
        } catch let error as ToolError {
            let result = ToolResult.error(error)
            results[invocation.id] = result
            return result
        } catch {
            let toolError = ToolError.executionFailed(error.localizedDescription)
            let result = ToolResult.error(toolError)
            results[invocation.id] = result
            return result
        }
    }
    
    /// Execute a tool by ID with parameters
    public func execute(
        toolID: ToolID,
        parameters: [String: ToolParameterValue],
        context: InvocationContext = InvocationContext()
    ) async -> ToolResult {
        let invocation = ToolInvocation(
            toolID: toolID,
            parameters: parameters,
            context: context
        )
        return await execute(invocation)
    }
    
    /// Cancel an active invocation
    public func cancel(invocationID: UUID) {
        activeInvocations.removeValue(forKey: invocationID)
    }
    
    /// Clear history
    public func clearHistory() {
        invocationHistory.removeAll()
        results.removeAll()
    }
}

// MARK: - Tool Builder DSL

/// Builder for creating tools with a fluent API
public final class ToolBuilder {
    private var id: ToolID = ""
    private var name: String = ""
    private var description: String = ""
    private var category: ToolDefinition.ToolCategory = .custom
    private var parameters: [ToolParameter] = []
    private var icon: String = "wrench"
    private var isAsync: Bool = true
    private var handler: ((ToolInvocation) async throws -> ToolResult)?
    
    public init() {}
    
    @discardableResult
    public func id(_ id: ToolID) -> Self {
        self.id = id
        return self
    }
    
    @discardableResult
    public func name(_ name: String) -> Self {
        self.name = name
        return self
    }
    
    @discardableResult
    public func description(_ description: String) -> Self {
        self.description = description
        return self
    }
    
    @discardableResult
    public func category(_ category: ToolDefinition.ToolCategory) -> Self {
        self.category = category
        return self
    }
    
    @discardableResult
    public func icon(_ icon: String) -> Self {
        self.icon = icon
        return self
    }
    
    @discardableResult
    public func parameter(
        name: String,
        description: String,
        type: ToolParameter.ParameterType,
        required: Bool = true,
        defaultValue: String? = nil,
        options: [String]? = nil
    ) -> Self {
        parameters.append(ToolParameter(
            name: name,
            description: description,
            type: type,
            required: required,
            defaultValue: defaultValue,
            options: options
        ))
        return self
    }
    
    @discardableResult
    public func handler(_ handler: @escaping (ToolInvocation) async throws -> ToolResult) -> Self {
        self.handler = handler
        return self
    }
    
    public func build() -> any MCPTool {
        let definition = ToolDefinition(
            id: id,
            name: name,
            description: description,
            category: category,
            parameters: parameters,
            icon: icon,
            isAsync: isAsync
        )
        return DynamicTool(definition: definition, handler: handler ?? { _ in .success(.text("No handler")) })
    }
}

/// Dynamic tool created from builder
private struct DynamicTool: MCPTool {
    let definition: ToolDefinition
    let handler: (ToolInvocation) async throws -> ToolResult
    
    func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        try await handler(invocation)
    }
}

// MARK: - Convenience Extensions

extension ToolParameterValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension ToolParameterValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension ToolParameterValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension ToolParameterValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .boolean(value)
    }
}
