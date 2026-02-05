import Foundation
import Combine
import SwiftUI

// MARK: - Content Store

/// Central authority for in-memory file content management.
/// Manages buffers, dirty tracking, and provides APIs for editors, previews, and agents.
@MainActor
public final class IDEContentStore: ObservableObject {
    public static let shared = IDEContentStore()
    
    /// All active buffers keyed by file URL
    @Published public private(set) var buffers: [URL: ContentBuffer] = [:]
    
    /// URLs of all dirty buffers
    public var dirtyURLs: [URL] {
        buffers.filter { $0.value.isDirty }.map { $0.key }
    }
    
    private init() {}
    
    // MARK: - Buffer Lifecycle
    
    /// Load or acquire an existing buffer for a file URL.
    /// If the buffer already exists, increments reference count and returns it.
    /// Otherwise, loads from disk and creates a new buffer.
    public func acquireBuffer(for url: URL) async -> ContentBuffer? {
        if let existing = buffers[url] {
            existing.retainCount += 1
            return existing
        }
        
        // Load from disk
        guard let buffer = await loadBuffer(from: url) else {
            return nil
        }
        
        buffers[url] = buffer
        return buffer
    }
    
    /// Release a buffer reference. Buffer is removed when retain count reaches zero
    /// and content is not dirty (dirty buffers persist until saved/reverted).
    public func releaseBuffer(for url: URL) {
        guard let buffer = buffers[url] else { return }
        buffer.retainCount -= 1
        
        if buffer.retainCount <= 0 && !buffer.isDirty {
            buffers.removeValue(forKey: url)
        }
    }
    
    /// Force release a buffer regardless of state (use with caution)
    public func forceReleaseBuffer(for url: URL) {
        buffers.removeValue(forKey: url)
    }
    
    /// Get buffer if it exists (does not load or increment retain count)
    public func buffer(for url: URL) -> ContentBuffer? {
        buffers[url]
    }
    
    /// Check if a buffer exists for the URL
    public func hasBuffer(for url: URL) -> Bool {
        buffers[url] != nil
    }
    
    // MARK: - Content Operations
    
    /// Update content in a buffer. Creates buffer if needed.
    /// Use this for programmatic edits (e.g., from agents).
    public func updateContent(for url: URL, with newContent: String, source: ContentBuffer.ModificationSource = .user) async {
        if let buffer = buffers[url] {
            buffer.updateContent(newContent, source: source)
        } else {
            // Create buffer on-the-fly for agent edits on unopened files, seeding with disk content
            let seedContent: String
            if let data = try? String(contentsOf: url, encoding: .utf8) {
                seedContent = data
            } else {
                seedContent = ""
            }
            let buffer = ContentBuffer(url: url, diskContent: seedContent, currentContent: seedContent)
            buffer.updateContent(newContent, source: source)
            buffers[url] = buffer
        }
    }
    
    /// Apply a mutation to existing content
    public func mutateContent(for url: URL, source: ContentBuffer.ModificationSource = .user, mutation: (String) -> String) {
        guard let buffer = buffers[url] else { return }
        let newContent = mutation(buffer.currentContent)
        buffer.updateContent(newContent, source: source)
    }
    
    /// Save buffer content to disk
    public func save(url: URL) async -> Bool {
        guard let buffer = buffers[url] else { return false }
        
        do {
            if buffer.isBinary {
                try buffer.binaryData?.write(to: url)
            } else {
                try buffer.currentContent.write(to: url, atomically: true, encoding: .utf8)
            }
            buffer.commitSave()
            return true
        } catch {
            print("[IDEContentStore] Failed to save \(url.lastPathComponent): \(error)")
            return false
        }
    }
    
    /// Revert buffer to disk content
    public func revert(url: URL) async {
        guard let buffer = buffers[url] else { return }
        
        if buffer.isBinary {
            if let data = try? Data(contentsOf: url) {
                buffer.revertToDisk(binaryData: data)
            }
        } else {
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                buffer.revertToDisk(content: content)
            }
        }
    }
    
    /// Save all dirty buffers
    public func saveAll() async -> Int {
        var savedCount = 0
        for url in dirtyURLs {
            if await save(url: url) {
                savedCount += 1
            }
        }
        return savedCount
    }
    
    // MARK: - Diff Support
    
    /// Get diff information for a buffer
    public func diffInfo(for url: URL) -> DiffInfo? {
        guard let buffer = buffers[url], buffer.isDirty else { return nil }
        return DiffInfo(
            url: url,
            originalContent: buffer.diskContent,
            currentContent: buffer.currentContent,
            lastModificationSource: buffer.lastModificationSource
        )
    }
    
    // MARK: - Private Helpers
    
    private func loadBuffer(from url: URL) async -> ContentBuffer? {
        // Determine if binary
        let isBinary = IDEFileTypeRegistry.shared.fileType(for: url).isBinary
        
        if isBinary {
            guard let data = try? Data(contentsOf: url) else { return nil }
            return ContentBuffer(url: url, binaryData: data)
        } else {
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
            return ContentBuffer(url: url, diskContent: content, currentContent: content)
        }
    }
}

// MARK: - Content Buffer

/// Represents an in-memory buffer for a single file.
/// Tracks disk snapshot, current edits, dirty state, and modification history.
public final class ContentBuffer: ObservableObject, Identifiable {
    public let id: UUID = UUID()
    public let url: URL
    public let isBinary: Bool
    
    /// Content as it exists on disk (for diffing)
    @Published public private(set) var diskContent: String
    
    /// Current in-memory content
    @Published public var currentContent: String
    
    /// Binary data (for non-text files)
    @Published public private(set) var binaryData: Data?
    
    /// Whether buffer has unsaved changes
    @Published public private(set) var isDirty: Bool = false
    
    /// Last modification timestamp
    @Published public private(set) var lastModified: Date = Date()
    
    /// Source of the last modification
    @Published public private(set) var lastModificationSource: ModificationSource = .user
    
    /// Reference count for buffer lifecycle management
    var retainCount: Int = 1
    
    /// Agent change tracking (for diff display in editors)
    @Published public var agentChangeSnapshot: AgentChangeInfo?
    
    public enum ModificationSource: Equatable {
        case user
        case agent(toolID: String?)
        case externalReload
    }
    
    // MARK: - Initialization
    
    public init(url: URL, diskContent: String, currentContent: String) {
        self.url = url
        self.diskContent = diskContent
        self.currentContent = currentContent
        self.isBinary = false
    }
    
    public init(url: URL, binaryData: Data) {
        self.url = url
        self.diskContent = ""
        self.currentContent = ""
        self.binaryData = binaryData
        self.isBinary = true
    }
    
    // MARK: - Content Updates
    
    public func updateContent(_ newContent: String, source: ModificationSource = .user) {
        let oldContent = currentContent
        currentContent = newContent
        isDirty = currentContent != diskContent
        lastModified = Date()
        lastModificationSource = source
        notifyDirtyStateChanged()
        
        // Track agent changes for diff display
        if case .agent = source {
            recordAgentChange(oldContent: oldContent, newContent: newContent)
        }
    }
    
    public func updateBinaryData(_ data: Data, source: ModificationSource = .user) {
        binaryData = data
        isDirty = true
        lastModified = Date()
        lastModificationSource = source
        notifyDirtyStateChanged()
    }
    
    // MARK: - Save/Revert
    
    func commitSave() {
        diskContent = currentContent
        isDirty = false
        lastModified = Date()
        notifyDirtyStateChanged()
    }
    
    func revertToDisk(content: String) {
        diskContent = content
        currentContent = content
        isDirty = false
        agentChangeSnapshot = nil
        notifyDirtyStateChanged()
    }
    
    func revertToDisk(binaryData: Data) {
        self.binaryData = binaryData
        isDirty = false
        notifyDirtyStateChanged()
    }
    
    // MARK: - Agent Change Tracking
    
    private func recordAgentChange(oldContent: String, newContent: String) {
        let preservedOld = agentChangeSnapshot?.oldContent ?? oldContent
        agentChangeSnapshot = AgentChangeInfo(
            oldContent: preservedOld,
            newContent: newContent,
            timestamp: Date()
        )
    }
    
    public func acceptAgentChange() {
        agentChangeSnapshot = nil
    }
    
    public func rejectAgentChange() {
        guard let snapshot = agentChangeSnapshot else { return }
        currentContent = snapshot.oldContent
        isDirty = currentContent != diskContent
        agentChangeSnapshot = nil
        notifyDirtyStateChanged()
    }
    
    // MARK: - Computed Properties
    
    public var fileName: String { url.lastPathComponent }
    
    public var fileExtension: String { url.pathExtension }
    
    // MARK: - Notifications
    
    private func notifyDirtyStateChanged() {
        NotificationCenter.default.post(
            name: .contentBufferDirtyStateChanged,
            object: self,
            userInfo: [
                "url": url,
                "isDirty": isDirty
            ]
        )
    }
}

// MARK: - Supporting Types

public struct DiffInfo {
    public let url: URL
    public let originalContent: String
    public let currentContent: String
    public let lastModificationSource: ContentBuffer.ModificationSource
}

public struct AgentChangeInfo {
    public let oldContent: String
    public let newContent: String
    public let timestamp: Date
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let contentBufferDidChange = Notification.Name("contentBufferDidChange")
    static let contentBufferDirtyStateChanged = Notification.Name("contentBufferDirtyStateChanged")
}
