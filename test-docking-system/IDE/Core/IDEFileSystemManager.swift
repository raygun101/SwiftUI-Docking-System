import Foundation

// MARK: - File System Manager

/// Manages file system operations for the IDE
public class IDEFileSystemManager {
    public static let shared = IDEFileSystemManager()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - Project Setup
    
    /// Clones a bundled demo project to a temporary directory
    public func setupDemoProject(bundleName: String) async -> URL? {
        guard let bundleURL = Bundle.main.url(forResource: bundleName, withExtension: nil) else {
            print("Demo project '\(bundleName)' not found in bundle")
            return nil
        }
        
        let tempDir = fileManager.temporaryDirectory
        let projectDir = tempDir.appendingPathComponent("IDEProject_\(UUID().uuidString.prefix(8))")
        
        do {
            // Create project directory
            try fileManager.createDirectory(at: projectDir, withIntermediateDirectories: true)
            
            // Copy contents
            let contents = try fileManager.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)
            for item in contents {
                let destination = projectDir.appendingPathComponent(item.lastPathComponent)
                try fileManager.copyItem(at: item, to: destination)
            }
            
            return projectDir
        } catch {
            print("Failed to setup demo project: \(error)")
            return nil
        }
    }
    
    /// Opens an existing project directory
    public func openProject(at url: URL) -> IDEProject? {
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        let name = url.lastPathComponent
        return IDEProject(name: name, rootURL: url)
    }
    
    // MARK: - File Tree Building
    
    /// Builds a file tree from the given directory
    public func buildFileTree(at url: URL) async -> IDEFileNode? {
        return buildFileNode(at: url)
    }
    
    private func buildFileNode(at url: URL) -> IDEFileNode? {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return nil
        }
        
        if isDirectory.boolValue {
            var children: [IDEFileNode] = []
            
            if let contents = try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
                options: [.skipsHiddenFiles]
            ) {
                for childURL in contents {
                    if let childNode = buildFileNode(at: childURL) {
                        children.append(childNode)
                    }
                }
            }
            
            return IDEFileNode(url: url, isDirectory: true, children: children)
        } else {
            return IDEFileNode(url: url, isDirectory: false)
        }
    }
    
    // MARK: - File Operations
    
    public func createFile(named name: String, in directory: URL, content: String = "") async -> URL? {
        let fileURL = directory.appendingPathComponent(name)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to create file: \(error)")
            return nil
        }
    }
    
    public func createFolder(named name: String, in directory: URL) async -> URL? {
        let folderURL = directory.appendingPathComponent(name)
        
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            return folderURL
        } catch {
            print("Failed to create folder: \(error)")
            return nil
        }
    }
    
    public func deleteItem(at url: URL) async -> Bool {
        do {
            try fileManager.removeItem(at: url)
            return true
        } catch {
            print("Failed to delete item: \(error)")
            return false
        }
    }
    
    public func renameItem(at url: URL, to newName: String) async -> URL? {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        
        do {
            try fileManager.moveItem(at: url, to: newURL)
            return newURL
        } catch {
            print("Failed to rename item: \(error)")
            return nil
        }
    }
    
    public func copyItem(at source: URL, to destination: URL) async -> Bool {
        do {
            try fileManager.copyItem(at: source, to: destination)
            return true
        } catch {
            print("Failed to copy item: \(error)")
            return false
        }
    }
    
    public func moveItem(at source: URL, to destination: URL) async -> Bool {
        do {
            try fileManager.moveItem(at: source, to: destination)
            return true
        } catch {
            print("Failed to move item: \(error)")
            return false
        }
    }
    
    public func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }
    
    public func isDirectory(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        fileManager.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }
    
    // MARK: - Cleanup
    
    public func cleanupTempProject(at url: URL) {
        try? fileManager.removeItem(at: url)
    }
}
