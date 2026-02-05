import Foundation
import Combine
import SwiftUI

// MARK: - Project Model

/// Represents an IDE project with its files and metadata
public class IDEProject: ObservableObject, Identifiable {
    public let id: UUID
    public let name: String
    public let rootURL: URL
    
    @Published public var rootNode: IDEFileNode?
    @Published public var openDocuments: [IDEDocument] = []
    @Published public var activeDocument: IDEDocument?
    @Published public var isLoading: Bool = false
    
    private var fileWatcher: IDEFileWatcher?
    private var cancellables = Set<AnyCancellable>()
    
    public init(name: String, rootURL: URL) {
        self.id = UUID()
        self.name = name
        self.rootURL = rootURL
    }
    
    // MARK: - File Tree
    
    public func loadFileTree() async {
        await MainActor.run { isLoading = true }
        
        let node = await IDEFileSystemManager.shared.buildFileTree(at: rootURL)
        
        await MainActor.run {
            self.rootNode = node
            self.isLoading = false
        }
    }
    
    public func refreshFileTree() async {
        await loadFileTree()
    }
    
    // MARK: - Document Management
    
    private let contentStore = IDEContentStore.shared
    
    public func openDocument(at url: URL) async -> IDEDocument? {
        // Check if already open
        if let existing = openDocuments.first(where: { $0.fileURL == url }) {
            await MainActor.run { activeDocument = existing }
            return existing
        }
        
        // Acquire buffer from content store
        guard let buffer = await contentStore.acquireBuffer(for: url) else {
            return nil
        }
        
        // Create document backed by buffer
        let document = await MainActor.run {
            let doc = IDEDocument(fileURL: url, buffer: buffer)
            openDocuments.append(doc)
            activeDocument = doc
            return doc
        }
        
        return document
    }
    
    @MainActor
    public func closeDocument(_ document: IDEDocument) {
        openDocuments.removeAll { $0.id == document.id }
        if activeDocument?.id == document.id {
            activeDocument = openDocuments.last
        }
        // Release buffer reference (buffer persists if dirty or has other references)
        contentStore.releaseBuffer(for: document.fileURL)
    }
    
    public func saveDocument(_ document: IDEDocument) async -> Bool {
        return await contentStore.save(url: document.fileURL)
    }
    
    public func saveAllDocuments() async {
        _ = await contentStore.saveAll()
    }
    
    // MARK: - File Watching
    
    public func startWatching() {
        fileWatcher = IDEFileWatcher(rootURL: rootURL)
        fileWatcher?.onChange = { [weak self] changeType, url in
            Task { @MainActor in
                self?.handleFileChange(changeType, at: url)
            }
        }
        fileWatcher?.start()
    }
    
    public func stopWatching() {
        fileWatcher?.stop()
        fileWatcher = nil
    }
    
    private func handleFileChange(_ changeType: IDEFileWatcher.ChangeType, at url: URL) {
        Task {
            // Refresh file tree
            await refreshFileTree()
            
            // Update open documents if modified externally
            if changeType == .modified {
                if let document = openDocuments.first(where: { $0.fileURL == url }) {
                    await document.reloadFromDisk()
                }
            }
        }
    }
    
    // MARK: - File Operations
    
    public func createFile(named name: String, in directory: URL, content: String = "") async -> URL? {
        return await IDEFileSystemManager.shared.createFile(named: name, in: directory, content: content)
    }
    
    public func createFolder(named name: String, in directory: URL) async -> URL? {
        return await IDEFileSystemManager.shared.createFolder(named: name, in: directory)
    }
    
    public func deleteItem(at url: URL) async -> Bool {
        // Close document if open
        if let document = openDocuments.first(where: { $0.fileURL == url }) {
            await MainActor.run { closeDocument(document) }
        }
        return await IDEFileSystemManager.shared.deleteItem(at: url)
    }
    
    public func renameItem(at url: URL, to newName: String) async -> URL? {
        return await IDEFileSystemManager.shared.renameItem(at: url, to: newName)
    }
}

// MARK: - File Node Model

/// Represents a file or folder in the project hierarchy
public class IDEFileNode: ObservableObject, Identifiable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let fileType: IDEFileType
    
    @Published public var children: [IDEFileNode]?
    @Published public var isExpanded: Bool = false
    
    public init(url: URL, isDirectory: Bool, children: [IDEFileNode]? = nil) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.children = children
        self.fileType = IDEFileTypeRegistry.shared.fileType(for: url)
    }
    
    public var icon: String {
        if isDirectory {
            return isExpanded ? "folder.fill" : "folder"
        }
        return fileType.icon
    }
    
    public var iconColor: Color {
        if isDirectory {
            return .blue
        }
        return fileType.iconColor
    }
    
    public var sortedChildren: [IDEFileNode]? {
        children?.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}

// MARK: - Document Model

/// Represents an open document in the IDE, backed by a ContentBuffer
public class IDEDocument: ObservableObject, Identifiable {
    public let id: UUID
    public let fileURL: URL
    public let fileType: IDEFileType
    
    /// The underlying content buffer from IDEContentStore
    public let buffer: ContentBuffer
    
    @Published public var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    public var name: String { fileURL.lastPathComponent }
    public var icon: String { fileType.icon }
    
    // MARK: - Buffer-Delegated Properties
    
    public var content: String {
        get { buffer.currentContent }
        set { buffer.updateContent(newValue, source: .user) }
    }
    
    public var isDirty: Bool { buffer.isDirty }
    public var lastModified: Date? { buffer.lastModified }
    public var agentChange: AgentChangeInfo? { buffer.agentChangeSnapshot }
    
    // MARK: - Initialization
    
    public init(fileURL: URL, buffer: ContentBuffer) {
        self.id = UUID()
        self.fileURL = fileURL
        self.buffer = buffer
        self.fileType = IDEFileTypeRegistry.shared.fileType(for: fileURL)
        
        // Forward buffer changes to trigger SwiftUI updates
        buffer.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    /// Legacy initializer for compatibility - creates a detached buffer
    public convenience init(fileURL: URL, content: String) {
        let buffer = ContentBuffer(url: fileURL, diskContent: content, currentContent: content)
        self.init(fileURL: fileURL, buffer: buffer)
    }
    
    public static func load(from url: URL) async -> IDEDocument? {
        guard let buffer = await IDEContentStore.shared.acquireBuffer(for: url) else {
            return nil
        }
        return await MainActor.run {
            IDEDocument(fileURL: url, buffer: buffer)
        }
    }
    
    // MARK: - Content Operations
    
    public func save() async -> Bool {
        return await IDEContentStore.shared.save(url: fileURL)
    }
    
    public func reloadFromDisk(force: Bool = false) async {
        await MainActor.run { isLoading = true }
        
        if force || !isDirty {
            await IDEContentStore.shared.revert(url: fileURL)
        }
        
        await MainActor.run { isLoading = false }
    }
    
    public func updateContent(_ newContent: String) {
        buffer.updateContent(newContent, source: .user)
    }
    
    public func revert() {
        buffer.revertToDisk(content: buffer.diskContent)
    }
    
    // MARK: - Agent Change Tracking
    
    public func recordAgentChange(oldContent: String, newContent: String) {
        buffer.updateContent(newContent, source: .agent(toolID: nil))
    }
    
    public func clearAgentChange() {
        buffer.acceptAgentChange()
    }

    public func acceptAgentChange() {
        buffer.acceptAgentChange()
    }

    public func rejectAgentChange() async {
        buffer.rejectAgentChange()
        _ = await save()
    }
}

// AgentChangeSnapshot is now AgentChangeInfo in IDEContentStore.swift
public typealias AgentChangeSnapshot = AgentChangeInfo
