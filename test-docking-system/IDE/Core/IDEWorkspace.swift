import Foundation
import SwiftUI
import Combine

// MARK: - Workspace Manager

/// Manages multiple workspace layouts (desktops) for the IDE
public class IDEWorkspaceManager: ObservableObject {
    public static let shared = IDEWorkspaceManager()
    
    @Published public var workspaces: [IDEWorkspace] = []
    @Published public var activeWorkspaceIndex: Int = 0
    @Published public var project: IDEProject?
    
    public var activeWorkspace: IDEWorkspace? {
        guard activeWorkspaceIndex >= 0 && activeWorkspaceIndex < workspaces.count else {
            return nil
        }
        return workspaces[activeWorkspaceIndex]
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupDefaultWorkspaces()
    }
    
    // MARK: - Setup
    
    private func setupDefaultWorkspaces() {
        workspaces = [
            IDEWorkspace(id: "code", name: "Code", icon: "chevron.left.forwardslash.chevron.right", layoutType: .coding),
            IDEWorkspace(id: "preview", name: "Preview", icon: "eye", layoutType: .preview),
            IDEWorkspace(id: "debug", name: "Debug", icon: "ant", layoutType: .debug),
            IDEWorkspace(id: "design", name: "Design", icon: "paintbrush", layoutType: .design)
        ]
    }
    
    // MARK: - Workspace Management
    
    public func switchToWorkspace(at index: Int) {
        guard index >= 0 && index < workspaces.count else { return }
        activeWorkspaceIndex = index
    }
    
    public func switchToWorkspace(withID id: String) {
        if let index = workspaces.firstIndex(where: { $0.id == id }) {
            activeWorkspaceIndex = index
        }
    }
    
    public func addWorkspace(_ workspace: IDEWorkspace) {
        workspaces.append(workspace)
    }
    
    public func removeWorkspace(at index: Int) {
        guard index > 0 && index < workspaces.count else { return } // Don't remove first workspace
        workspaces.remove(at: index)
        if activeWorkspaceIndex >= workspaces.count {
            activeWorkspaceIndex = workspaces.count - 1
        }
    }
    
    // MARK: - Project Management
    
    public func loadDemoProject() async {
        if let projectURL = await IDEFileSystemManager.shared.setupDemoProject(bundleName: "DemoProject") {
            let newProject = IDEProject(name: "Demo Project", rootURL: projectURL)
            await newProject.loadFileTree()
            newProject.startWatching()
            
            await MainActor.run {
                self.project = newProject
            }
        }
    }
    
    public func closeProject() {
        project?.stopWatching()
        if let url = project?.rootURL {
            IDEFileSystemManager.shared.cleanupTempProject(at: url)
        }
        project = nil
    }
}

// MARK: - Workspace Model

/// Represents a single workspace layout configuration
public class IDEWorkspace: ObservableObject, Identifiable {
    public let id: String
    public let name: String
    public let icon: String
    public let layoutType: IDELayoutType
    
    @Published public var dockState: DockState?
    @Published public var customLayout: DockLayout?
    
    public init(id: String, name: String, icon: String, layoutType: IDELayoutType) {
        self.id = id
        self.name = name
        self.icon = icon
        self.layoutType = layoutType
    }
}

// MARK: - Layout Types

public enum IDELayoutType: String, CaseIterable {
    case coding
    case preview
    case debug
    case design
    case custom
    
    public var description: String {
        switch self {
        case .coding: return "Code Editor Layout"
        case .preview: return "Preview Layout"
        case .debug: return "Debug Layout"
        case .design: return "Design Layout"
        case .custom: return "Custom Layout"
        }
    }
}

// MARK: - IDE State

/// Main IDE state object that coordinates all IDE components
public class IDEState: ObservableObject {
    public static let shared = IDEState()
    
    @Published public var workspaceManager = IDEWorkspaceManager.shared
    @Published public var isProjectLoaded: Bool = false
    @Published public var statusMessage: String = "Ready"
    @Published public var isLoading: Bool = false
    
    // Editor state
    @Published public var selectedFileURL: URL?
    @Published public var previewURL: URL?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
    }
    
    private func setupBindings() {
        workspaceManager.$project
            .map { $0 != nil }
            .assign(to: &$isProjectLoaded)
    }
    
    // MARK: - Actions
    
    public func initialize() async {
        await MainActor.run {
            isLoading = true
            statusMessage = "Loading project..."
        }
        
        await workspaceManager.loadDemoProject()
        
        await MainActor.run {
            isLoading = false
            statusMessage = "Project loaded"
        }
    }
    
    public func openFile(_ url: URL) async {
        guard let project = workspaceManager.project else { return }
        
        await MainActor.run {
            statusMessage = "Opening \(url.lastPathComponent)..."
        }
        
        if let document = await project.openDocument(at: url) {
            await MainActor.run {
                selectedFileURL = url
                statusMessage = "Opened \(document.name)"
                
                // Auto-set preview for HTML files
                if document.fileType.canPreview && document.fileType.id == "html" {
                    previewURL = url
                }
            }
        }
    }
    
    public func saveCurrentDocument() async {
        guard let project = workspaceManager.project,
              let document = project.activeDocument else { return }
        
        await MainActor.run {
            statusMessage = "Saving..."
        }
        
        let success = await project.saveDocument(document)
        
        await MainActor.run {
            statusMessage = success ? "Saved \(document.name)" : "Failed to save"
        }
    }
    
    public func saveAllDocuments() async {
        guard let project = workspaceManager.project else { return }
        
        await MainActor.run {
            statusMessage = "Saving all..."
        }
        
        await project.saveAllDocuments()
        
        await MainActor.run {
            statusMessage = "All files saved"
        }
    }
    
    public func refreshProject() async {
        guard let project = workspaceManager.project else { return }
        
        await MainActor.run {
            statusMessage = "Refreshing..."
        }
        
        await project.refreshFileTree()
        
        await MainActor.run {
            statusMessage = "Project refreshed"
        }
    }
}
