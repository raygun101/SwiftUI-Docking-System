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
    @Published public var preferredEditorPosition: DockPosition = .center
    
    private weak var dockState: DockState?
    private var documentPanelMap: [UUID: [DockPanelID: ContentPanelDescriptor]] = [:]
    private var openDocumentsCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private var isClosingPanelsProgrammatically = false
    
    private init() {
        setupBindings()
    }
    
    private func setupBindings() {
        workspaceManager.$project
            .receive(on: RunLoop.main)
            .sink { [weak self] project in
                guard let self else { return }
                self.isProjectLoaded = project != nil
                self.observeOpenDocuments(in: project)
            }
            .store(in: &cancellables)
    }
    
    public func attachDockState(_ state: DockState) {
        dockState = state
    }
    
    // MARK: - Document Observing
    
    private func observeOpenDocuments(in project: IDEProject?) {
        openDocumentsCancellable = nil
        if let project {
            openDocumentsCancellable = project.$openDocuments
                .receive(on: RunLoop.main)
                .sink { [weak self] documents in
                    guard let self else { return }
                    Task { @MainActor in
                        self.syncPanels(with: documents)
                    }
                }
        } else {
            closeAllDocumentPanels()
            documentPanelMap.removeAll()
        }
    }
    
    @MainActor
    private func syncPanels(with documents: [IDEDocument]) {
        guard let dockState else { return }
        let currentIDs = Set(documents.map { $0.id })
        for document in documents {
            if documentPanelMap[document.id] == nil {
                documentPanelMap[document.id] = [:]
            }
        }
        let knownIDs = Set(documentPanelMap.keys)
        let removed = knownIDs.subtracting(currentIDs)
        for documentID in removed {
            guard let panelEntries = documentPanelMap[documentID] else { continue }
            for panelID in panelEntries.keys {
                if let panel = dockState.panel(withID: panelID) {
                    isClosingPanelsProgrammatically = true
                    dockState.closePanel(panel)
                    isClosingPanelsProgrammatically = false
                }
            }
            documentPanelMap.removeValue(forKey: documentID)
        }
    }
    
    private func closeAllDocumentPanels() {
        guard let dockState else { return }
        isClosingPanelsProgrammatically = true
        for panelEntries in documentPanelMap.values {
            for panelID in panelEntries.keys {
                if let panel = dockState.panel(withID: panelID) {
                    dockState.closePanel(panel)
                }
            }
        }
        documentPanelMap.removeAll()
        isClosingPanelsProgrammatically = false
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
    
    public func openFile(_ url: URL, using descriptor: ContentPanelDescriptor? = nil) async {
        guard let project = workspaceManager.project else { return }
        
        await MainActor.run {
            statusMessage = "Opening \(url.lastPathComponent)..."
        }
        
        if let document = await project.openDocument(at: url) {
            await MainActor.run {
                selectedFileURL = url
                statusMessage = "Opened \(document.name)"
                presentPanel(for: document, using: descriptor)
            }
        }
    }
    
    public func saveCurrentDocument() async {
        guard let project = workspaceManager.project,
              let document = project.activeDocument else { return }
        await saveDocument(document)
    }
    
    public func saveDocument(_ document: IDEDocument) async {
        guard workspaceManager.project != nil else { return }
        await MainActor.run { statusMessage = "Saving..." }
        let success = await document.save()
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
    
    // MARK: - Document Panels
    
    @MainActor
    public func presentPanel(for document: IDEDocument, using descriptor: ContentPanelDescriptor? = nil, preferredPosition: DockPosition? = nil) {
        guard let dockState, let project = workspaceManager.project else { return }
        let descriptor = descriptor ?? ContentPanelRegistry.shared.defaultPanel(for: document.fileType)
        let existingPanelID = documentPanelMap[document.id]?.first(where: { $0.value == descriptor })?.key
        if let panelID = existingPanelID,
           let panel = dockState.panel(withID: panelID) {
            dockState.activatePanel(panel)
            return
        }
        let panel = createPanel(for: document, descriptor: descriptor, in: project)
        documentPanelMap[document.id, default: [:]][panel.id] = descriptor
        dockState.addPanel(panel, to: preferredPosition ?? preferredEditorPosition)
    }
    
    @MainActor
    private func createPanel(for document: IDEDocument, descriptor: ContentPanelDescriptor, in project: IDEProject) -> DockPanel {
        let panelID = "document-\(descriptor.id)-\(document.id.uuidString)"
        let title = descriptor.isEditable ? document.name : "\(descriptor.name): \(document.name)"
        return DockPanel(
            id: panelID,
            title: title,
            icon: descriptor.icon,
            position: preferredEditorPosition,
            visibility: [.showHeader, .showCloseButton, .allowDrag, .allowResize, .allowFloat, .allowTabbing],
            userInfo: lifecycleHandlers(for: document, panelID: panelID, project: project)
        ) {
            ContentPanelRegistry.shared.makeView(for: document, using: descriptor)
                .environmentObject(self)
        }
    }
    
    private func lifecycleHandlers(for document: IDEDocument, panelID: DockPanelID, project: IDEProject) -> [String: Any] {
        let onClose: () -> Void = { [weak self, weak project] in
            Task { @MainActor in
                guard let self else { return }
                self.documentPanelMap[document.id]?.removeValue(forKey: panelID)
                if self.documentPanelMap[document.id]?.isEmpty == true {
                    self.documentPanelMap.removeValue(forKey: document.id)
                }
                if !self.isClosingPanelsProgrammatically {
                    project?.closeDocument(document)
                }
                if self.selectedFileURL == document.fileURL {
                    self.selectedFileURL = project?.activeDocument?.fileURL
                }
            }
        }
        let onActivate: () -> Void = { [weak self, weak project] in
            guard let self else { return }
            project?.activeDocument = document
            self.selectedFileURL = document.fileURL
        }
        let isDirtyProvider: () -> Bool = { [weak document] in
            document?.isDirty ?? false
        }
        return [
            DockPanelUserInfoKey.onCloseHandler: onClose,
            DockPanelUserInfoKey.onActivateHandler: onActivate,
            DockPanelUserInfoKey.isDirtyProvider: isDirtyProvider,
            DockPanelUserInfoKey.fileURL: document.fileURL
        ]
    }
}
