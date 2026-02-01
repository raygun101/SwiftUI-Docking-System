import Foundation

// MARK: - File Watcher

/// Watches a directory for file changes
public class IDEFileWatcher {
    public enum ChangeType {
        case created
        case modified
        case deleted
        case renamed
    }
    
    public var onChange: ((ChangeType, URL) -> Void)?
    
    private struct TrackedItem {
        let modifiedDate: Date
        let isDirectory: Bool
    }
    
    private let rootURL: URL
    private var source: DispatchSourceFileSystemObject?
    private var directoryHandle: CInt = -1
    private var isRunning = false
    private var knownFiles: [String: TrackedItem] = [:]
    private var timer: Timer?
    
    public init(rootURL: URL) {
        self.rootURL = rootURL
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Control
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        
        // Build initial file list
        knownFiles = scanDirectory()
        
        // Use polling for simplicity on iOS (DispatchSource for directories is limited)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    public func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        if directoryHandle >= 0 {
            close(directoryHandle)
            directoryHandle = -1
        }
        
        source?.cancel()
        source = nil
    }
    
    // MARK: - Scanning
    
    private func scanDirectory() -> [String: TrackedItem] {
        var files: [String: TrackedItem] = [:]
        
        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return files
        }
        
        while let url = enumerator.nextObject() as? URL {
            let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey])
            let isDirectory = resourceValues?.isDirectory ?? false
            let modifiedDate = resourceValues?.contentModificationDate ?? Date()
            let relativePath = relativePath(for: url)
            if relativePath.isEmpty { continue }
            files[relativePath] = TrackedItem(modifiedDate: modifiedDate, isDirectory: isDirectory)
        }
        
        return files
    }
    
    private func checkForChanges() {
        let currentFiles = scanDirectory()
        let previousPaths = Set(knownFiles.keys)
        let currentPaths = Set(currentFiles.keys)
        
        let addedFiles = currentPaths.subtracting(previousPaths)
        for path in addedFiles {
            emitChange(.created, relativePath: path)
        }
        
        let deletedFiles = previousPaths.subtracting(currentPaths)
        for path in deletedFiles {
            emitChange(.deleted, relativePath: path)
        }
        
        let potentiallyModified = currentPaths.intersection(previousPaths)
        for path in potentiallyModified {
            guard let newInfo = currentFiles[path], let oldInfo = knownFiles[path] else { continue }
            guard !newInfo.isDirectory else { continue }
            if newInfo.modifiedDate > oldInfo.modifiedDate {
                emitChange(.modified, relativePath: path)
            }
        }
        
        knownFiles = currentFiles
    }
    
    private func emitChange(_ type: ChangeType, relativePath: String) {
        let trimmedPath = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmedPath.isEmpty else { return }
        let url = rootURL.appendingPathComponent(trimmedPath)
        onChange?(type, url)
    }
    
    private func relativePath(for url: URL) -> String {
        let rootPath = rootURL.path.hasSuffix("/") ? rootURL.path : rootURL.path + "/"
        var fullPath = url.path
        if fullPath.hasPrefix(rootPath) {
            fullPath.removeFirst(rootPath.count)
        } else if fullPath.hasPrefix(rootURL.path) {
            fullPath.removeFirst(rootURL.path.count)
        }
        return fullPath
    }
}
