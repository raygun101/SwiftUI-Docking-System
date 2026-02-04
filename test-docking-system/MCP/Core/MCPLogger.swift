import OSLog

/// Centralized loggers for MCP/Agent components
enum MCPLog {
    static let agent = Logger(subsystem: "test-docking-system", category: "Agent")
    static let chatService = Logger(subsystem: "test-docking-system", category: "ChatService")
    static let integration = Logger(subsystem: "test-docking-system", category: "Integration")
    static let settings = Logger(subsystem: "test-docking-system", category: "Settings")
}
