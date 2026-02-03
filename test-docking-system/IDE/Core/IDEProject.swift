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
    
    public func openDocument(at url: URL) async -> IDEDocument? {
        // Check if already open
        if let existing = openDocuments.first(where: { $0.fileURL == url }) {
            await MainActor.run { activeDocument = existing }
            return existing
        }
        
        // Load document
        guard let document = await IDEDocument.load(from: url) else {
            return nil
        }
        
        await MainActor.run {
            openDocuments.append(document)
            activeDocument = document
        }
        
        return document
    }
    
    public func closeDocument(_ document: IDEDocument) {
        openDocuments.removeAll { $0.id == document.id }
        if activeDocument?.id == document.id {
            activeDocument = openDocuments.last
        }
    }
    
    public func saveDocument(_ document: IDEDocument) async -> Bool {
        return await document.save()
    }
    
    public func saveAllDocuments() async {
        for document in openDocuments where document.isDirty {
            _ = await document.save()
        }
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

/// Represents an open document in the IDE
public class IDEDocument: ObservableObject, Identifiable {
    public let id: UUID
    public let fileURL: URL
    public let fileType: IDEFileType
    
    @Published public var content: String
    @Published public var isDirty: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var lastModified: Date?
    @Published public var agentChange: AgentChangeSnapshot?
    
    private var originalContent: String
    
    public var name: String { fileURL.lastPathComponent }
    public var icon: String { fileType.icon }
    
    public init(fileURL: URL, content: String) {
        self.id = UUID()
        self.fileURL = fileURL
        self.content = content
        self.originalContent = content
        self.fileType = IDEFileTypeRegistry.shared.fileType(for: fileURL)
        self.lastModified = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date
    }
    
    public static func load(from url: URL) async -> IDEDocument? {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return await MainActor.run {
                IDEDocument(fileURL: url, content: content)
            }
        } catch {
            print("Failed to load document: \(error)")
            return nil
        }
    }
    
    public func save() async -> Bool {
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            await MainActor.run {
                originalContent = content
                isDirty = false
                lastModified = Date()
            }
            return true
        } catch {
            print("Failed to save document: \(error)")
            return false
        }
    }
    
    public func reloadFromDisk(force: Bool = false) async {
        await MainActor.run { isLoading = true }
        
        do {
            let newContent = try String(contentsOf: fileURL, encoding: .utf8)
            await MainActor.run {
                if force || !isDirty {
                    content = newContent
                    originalContent = newContent
                    isDirty = false
                }
                lastModified = Date()
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
    
    public func updateContent(_ newContent: String) {
        content = newContent
        isDirty = content != originalContent
    }
    
    public func revert() {
        content = originalContent
        isDirty = false
    }
    
    public func recordAgentChange(oldContent: String, newContent: String) {
        let preservedOrigin = agentChange?.oldContent ?? oldContent
        agentChange = AgentChangeSnapshot(
            oldContent: preservedOrigin,
            newContent: newContent,
            timestamp: Date()
        )
    }
    
    public func clearAgentChange() {
        agentChange = nil
    }

    public func acceptAgentChange() {
        guard agentChange != nil else { return }
        agentChange = nil
        originalContent = content
        isDirty = false
        lastModified = Date()
    }

    public func rejectAgentChange() async {
        guard let snapshot = agentChange else { return }
        do {
            try snapshot.oldContent.write(to: fileURL, atomically: true, encoding: .utf8)
            await MainActor.run {
                content = snapshot.oldContent
                originalContent = snapshot.oldContent
                isDirty = false
                agentChange = nil
                lastModified = Date()
            }
        } catch {
            print("Failed to reject agent change: \(error.localizedDescription)")
        }
    }
}

public struct AgentChangeSnapshot {
    public let oldContent: String
    public let newContent: String
    public let timestamp: Date
}
