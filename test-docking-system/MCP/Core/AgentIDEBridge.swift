import Foundation
import SwiftUI
import Combine

// MARK: - Agent IDE Bridge

/// Bridges the MCP Agent with the IDE, handling notifications and actions
@MainActor
public final class AgentIDEBridge: ObservableObject {
    public static let shared = AgentIDEBridge()
    
    private var cancellables = Set<AnyCancellable>()
    private weak var ideState: IDEState?
    
    private init() {
        setupNotificationHandlers()
    }
    
    // MARK: - Connection
    
    public func connect(to ideState: IDEState) {
        self.ideState = ideState
        
        // Observe document changes to update MCP context
        observeDocumentChanges()
    }
    
    // MARK: - Notification Handlers
    
    private func setupNotificationHandlers() {
        // Handle code insertion requests from agent
        NotificationCenter.default.publisher(for: .agentInsertCode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleInsertCode(notification)
            }
            .store(in: &cancellables)
        
        // Handle file open requests from agent
        NotificationCenter.default.publisher(for: .agentOpenFile)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleOpenFile(notification)
            }
            .store(in: &cancellables)
        
        // Handle file creation requests from agent
        NotificationCenter.default.publisher(for: .agentCreateFile)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleCreateFile(notification)
            }
            .store(in: &cancellables)
        
        // Handle refresh project requests
        NotificationCenter.default.publisher(for: .agentRefreshProject)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleRefreshProject()
            }
            .store(in: &cancellables)
        
        // Handle file change notifications (agent edits)
        NotificationCenter.default.publisher(for: .agentFileDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleFileChanged(notification)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Action Handlers
    
    private func handleInsertCode(_ notification: Notification) {
        guard let code = notification.userInfo?["code"] as? String,
              let language = notification.userInfo?["language"] as? String else {
            print("[AgentBridge] Insert code: missing code or language")
            return
        }
        
        print("[AgentBridge] Inserting \(language) code: \(code.prefix(50))...")
        
        // Get the active document and insert code
        if let project = ideState?.workspaceManager.project,
           let activeDoc = project.activeDocument {
            // Append code to current content (dirty state managed automatically by buffer)
            let newContent = activeDoc.content + "\n\n" + code
            activeDoc.updateContent(newContent)
            
            print("[AgentBridge] Inserted \(language) code into \(activeDoc.name)")
        } else {
            // No active document - create a new file with the code
            createFileWithContent(code: code, language: language)
        }
    }
    
    private func handleOpenFile(_ notification: Notification) {
        guard let url = notification.userInfo?["url"] as? URL else {
            // Try path string
            if let path = notification.userInfo?["path"] as? String,
               let projectRoot = ideState?.workspaceManager.project?.rootURL {
                let fileURL = projectRoot.appendingPathComponent(path)
                openFile(at: fileURL)
            }
            return
        }
        
        openFile(at: url)
    }
    
    private func handleCreateFile(_ notification: Notification) {
        guard let filename = notification.userInfo?["filename"] as? String else {
            print("[AgentBridge] Create file: missing filename")
            return
        }
        
        let content = notification.userInfo?["content"] as? String ?? ""
        let directory = notification.userInfo?["directory"] as? String
        
        createFile(name: filename, content: content, inDirectory: directory)
    }
    
    private func handleRefreshProject() {
        Task {
            await ideState?.refreshProject()
            updateMCPContext()
        }
    }
    
    private func handleFileChanged(_ notification: Notification) {
        guard let url = notification.userInfo?["url"] as? URL else {
            return
        }
        let oldContent = notification.userInfo?["oldContent"] as? String
        let newContent = notification.userInfo?["newContent"] as? String
        Task { @MainActor in
            guard let ideState else { return }
            guard let project = ideState.workspaceManager.project else { return }
            var document = project.openDocuments.first(where: { $0.fileURL == url })
            if document == nil {
                await ideState.openFile(url)
                document = project.openDocuments.first(where: { $0.fileURL == url })
            } else {
                project.activeDocument = document
                ideState.selectedFileURL = url
            }
            if let document, let oldContent, let newContent {
                document.recordAgentChange(oldContent: oldContent, newContent: newContent)
            }
            if let document {
                await document.reloadFromDisk(force: true)
            }
            await project.refreshFileTree()
            updateMCPContext()
        }
    }
    
    // MARK: - File Operations
    
    private func openFile(at url: URL) {
        Task {
            await ideState?.openFile(url)
            updateMCPContext()
        }
    }
    
    private func createFile(name: String, content: String, inDirectory: String?) {
        guard let projectRoot = ideState?.workspaceManager.project?.rootURL else {
            print("[AgentBridge] No project loaded")
            return
        }
        
        var targetURL = projectRoot
        if let dir = inDirectory {
            targetURL = projectRoot.appendingPathComponent(dir)
            // Create directory if needed
            try? FileManager.default.createDirectory(at: targetURL, withIntermediateDirectories: true)
        }
        
        let fileURL = targetURL.appendingPathComponent(name)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            
            print("[AgentBridge] Created file: \(name)")
            
            // Open the new file
            Task {
                await ideState?.openFile(fileURL)
                await ideState?.refreshProject()
                updateMCPContext()
            }
        } catch {
            print("[AgentBridge] Failed to create file: \(error.localizedDescription)")
        }
    }
    
    private func createFileWithContent(code: String, language: String) {
        let ext = extensionForLanguage(language)
        let filename = "new_file_\(Int(Date().timeIntervalSince1970)).\(ext)"
        createFile(name: filename, content: code, inDirectory: nil)
    }
    
    private func extensionForLanguage(_ language: String) -> String {
        switch language.lowercased() {
        case "html": return "html"
        case "css": return "css"
        case "javascript", "js": return "js"
        case "json": return "json"
        case "swift": return "swift"
        case "python": return "py"
        case "markdown", "md": return "md"
        default: return "txt"
        }
    }
    
    // MARK: - Context Management
    
    private func observeDocumentChanges() {
        // Observe when documents open/close
        ideState?.workspaceManager.project?.$openDocuments
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMCPContext()
            }
            .store(in: &cancellables)
        
        // Observe active document changes
        ideState?.workspaceManager.project?.$activeDocument
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMCPContext()
            }
            .store(in: &cancellables)
    }
    
    public func updateMCPContext() {
        guard let project = ideState?.workspaceManager.project else { return }
        
        MCP.setProjectContext(
            rootURL: project.rootURL,
            openFiles: project.openDocuments.map { $0.fileURL },
            activeFile: project.activeDocument?.fileURL
        )
    }
}

// MARK: - Additional Notification Names
// Note: agentInsertCode, agentOpenFile, agentCreateFile defined in MCPAgent.swift

public extension Notification.Name {
    static let agentRefreshProject = Notification.Name("MCPAgentRefreshProject")
    static let agentShowSuggestion = Notification.Name("MCPAgentShowSuggestion")
    static let presentMCPSettings = Notification.Name("MCPPresentSettings")
}

// MARK: - Agent Actions Helper

public struct AgentActions {
    
    /// Request the agent to insert code at the current cursor position
    public static func insertCode(_ code: String, language: String) {
        NotificationCenter.default.post(
            name: .agentInsertCode,
            object: nil,
            userInfo: ["code": code, "language": language]
        )
    }
    
    /// Request the agent to open a file
    public static func openFile(at url: URL) {
        NotificationCenter.default.post(
            name: .agentOpenFile,
            object: nil,
            userInfo: ["url": url]
        )
    }
    
    /// Request the agent to open a file by path
    public static func openFile(path: String) {
        NotificationCenter.default.post(
            name: .agentOpenFile,
            object: nil,
            userInfo: ["path": path]
        )
    }
    
    /// Request the agent to create a new file
    public static func createFile(name: String, content: String = "", directory: String? = nil) {
        var userInfo: [String: Any] = ["filename": name, "content": content]
        if let dir = directory {
            userInfo["directory"] = dir
        }
        NotificationCenter.default.post(
            name: .agentCreateFile,
            object: nil,
            userInfo: userInfo
        )
    }
    
    /// Request project refresh
    public static func refreshProject() {
        NotificationCenter.default.post(name: .agentRefreshProject, object: nil)
    }
    
    /// Request presentation of the MCP settings dialog
    public static func showSettings() {
        NotificationCenter.default.post(name: .presentMCPSettings, object: nil)
    }
}
