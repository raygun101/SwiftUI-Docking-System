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
    
    private let rootURL: URL
    private var source: DispatchSourceFileSystemObject?
    private var directoryHandle: CInt = -1
    private var isRunning = false
    private var knownFiles: Set<String> = []
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
    
    private func scanDirectory() -> Set<String> {
        var files = Set<String>()
        
        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return files
        }
        
        while let url = enumerator.nextObject() as? URL {
            let relativePath = url.path.replacingOccurrences(of: rootURL.path, with: "")
            files.insert(relativePath)
        }
        
        return files
    }
    
    private func checkForChanges() {
        let currentFiles = scanDirectory()
        
        // Check for new files
        let addedFiles = currentFiles.subtracting(knownFiles)
        for path in addedFiles {
            let url = rootURL.appendingPathComponent(path)
            onChange?(.created, url)
        }
        
        // Check for deleted files
        let deletedFiles = knownFiles.subtracting(currentFiles)
        for path in deletedFiles {
            let url = rootURL.appendingPathComponent(path)
            onChange?(.deleted, url)
        }
        
        // For existing files, we could check modification dates
        // but for simplicity, we'll just detect add/delete for now
        
        knownFiles = currentFiles
    }
}
