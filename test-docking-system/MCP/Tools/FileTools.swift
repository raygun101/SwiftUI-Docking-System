import Foundation

// MARK: - File Operation Tools

/// Tool for creating new files
public struct CreateFileTool: MCPTool {
    public let definition = ToolDefinition(
        id: "create_file",
        name: "Create File",
        description: "Create a new file with the specified content",
        category: .file,
        parameters: [
            ToolParameter(name: "path", description: "File path relative to project root", type: .string),
            ToolParameter(name: "content", description: "File content", type: .string),
            ToolParameter(name: "overwrite", description: "Overwrite if exists", type: .boolean, required: false, defaultValue: "false")
        ],
        icon: "doc.badge.plus"
    )
    
    public init() {}
    
    public func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        guard let path = invocation.parameters["path"]?.stringValue else {
            return .error(.missingParameter("path"))
        }
        guard let content = invocation.parameters["content"]?.stringValue else {
            return .error(.missingParameter("content"))
        }
        
        let overwrite = invocation.parameters["overwrite"]?.boolValue ?? false
        
        let fileURL: URL
        if let projectRoot = invocation.context.projectRoot {
            fileURL = projectRoot.appendingPathComponent(path)
        } else {
            fileURL = URL(fileURLWithPath: path)
        }
        
        // Check if file exists
        if FileManager.default.fileExists(atPath: fileURL.path) && !overwrite {
            return .error(ToolError(
                code: "FILE_EXISTS",
                message: "File already exists: \(path)",
                suggestions: ["Set overwrite to true to replace the file"]
            ))
        }
        
        // Create parent directories if needed
        let parentDir = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        
        // Write file
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return .success(.text("Created file: \(path)"))
        } catch {
            return .error(.executionFailed("Failed to create file: \(error.localizedDescription)"))
        }
    }
}

/// Tool for reading file contents
public struct ReadFileTool: MCPTool {
    public let definition = ToolDefinition(
        id: "read_file",
        name: "Read File",
        description: "Read the contents of a file",
        category: .file,
        parameters: [
            ToolParameter(name: "path", description: "File path relative to project root", type: .string),
            ToolParameter(name: "encoding", description: "Text encoding", type: .string, required: false, defaultValue: "utf8")
        ],
        icon: "doc.text"
    )
    
    public init() {}
    
    public func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        guard let path = invocation.parameters["path"]?.stringValue else {
            return .error(.missingParameter("path"))
        }
        
        let fileURL: URL
        if let projectRoot = invocation.context.projectRoot {
            fileURL = projectRoot.appendingPathComponent(path)
        } else {
            fileURL = URL(fileURLWithPath: path)
        }
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .error(ToolError(
                code: "FILE_NOT_FOUND",
                message: "File not found: \(path)"
            ))
        }
        
        // Check IDEContentStore first for in-memory content (user edits)
        let contentStore = await IDEContentStore.shared
        if let buffer = await MainActor.run(body: { contentStore.buffer(for: fileURL) }) {
            let content = await MainActor.run { buffer.currentContent }
            let language = detectLanguage(for: fileURL.pathExtension)
            return .success(.code(content, language: language))
        }
        
        // Fall back to disk
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let language = detectLanguage(for: fileURL.pathExtension)
            return .success(.code(content, language: language))
        } catch {
            return .error(.executionFailed("Failed to read file: \(error.localizedDescription)"))
        }
    }
    
    private func detectLanguage(for ext: String) -> String {
        switch ext.lowercased() {
        case "swift": return "swift"
        case "js": return "javascript"
        case "ts": return "typescript"
        case "html", "htm": return "html"
        case "css": return "css"
        case "json": return "json"
        case "py": return "python"
        case "md": return "markdown"
        case "xml": return "xml"
        case "yaml", "yml": return "yaml"
        default: return "plaintext"
        }
    }
}

/// Tool for editing/updating file contents
public struct EditFileTool: MCPTool {
    public let definition = ToolDefinition(
        id: "edit_file",
        name: "Edit File",
        description: "Edit a file by replacing content or inserting at a position",
        category: .file,
        parameters: [
            ToolParameter(name: "path", description: "File path relative to project root", type: .string),
            ToolParameter(name: "old_content", description: "Content to replace (leave empty for append)", type: .string, required: false),
            ToolParameter(name: "new_content", description: "New content to insert", type: .string),
            ToolParameter(name: "position", description: "Insert position: 'start', 'end', or line number", type: .string, required: false, defaultValue: "end")
        ],
        icon: "pencil"
    )
    
    public init() {}
    
    public func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        guard let path = invocation.parameters["path"]?.stringValue else {
            return .error(.missingParameter("path"))
        }
        guard let newContent = invocation.parameters["new_content"]?.stringValue else {
            return .error(.missingParameter("new_content"))
        }
        
        let fileURL: URL
        if let projectRoot = invocation.context.projectRoot {
            fileURL = projectRoot.appendingPathComponent(path)
        } else {
            fileURL = URL(fileURLWithPath: path)
        }
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .error(ToolError(code: "FILE_NOT_FOUND", message: "File not found: \(path)"))
        }
        
        // Get content from IDEContentStore if available, otherwise from disk
        let contentStore = await IDEContentStore.shared
        let originalContent: String
        if let buffer = await MainActor.run(body: { contentStore.buffer(for: fileURL) }) {
            originalContent = await MainActor.run { buffer.currentContent }
        } else {
            do {
                originalContent = try String(contentsOf: fileURL, encoding: .utf8)
            } catch {
                return .error(.executionFailed("Failed to read file: \(error.localizedDescription)"))
            }
        }
        
        var updatedContent = originalContent
        
        if let oldContent = invocation.parameters["old_content"]?.stringValue, !oldContent.isEmpty {
            // Replace mode
            guard updatedContent.contains(oldContent) else {
                return .error(ToolError(
                    code: "CONTENT_NOT_FOUND",
                    message: "Could not find the specified content to replace"
                ))
            }
            updatedContent = updatedContent.replacingOccurrences(of: oldContent, with: newContent)
        } else {
            // Insert mode
            let position = invocation.parameters["position"]?.stringValue ?? "end"
            switch position {
            case "start":
                updatedContent = newContent + updatedContent
            case "end":
                updatedContent = updatedContent + newContent
            default:
                if let lineNum = Int(position) {
                    var lines = updatedContent.components(separatedBy: "\n")
                    let index = max(0, min(lineNum - 1, lines.count))
                    lines.insert(newContent, at: index)
                    updatedContent = lines.joined(separator: "\n")
                } else {
                    updatedContent = updatedContent + newContent
                }
            }
        }
        
        // Update through IDEContentStore (handles in-memory buffers and notification)
        await contentStore.updateContent(for: fileURL, with: updatedContent, source: .agent(toolID: "edit_file"))
        
        // Also write to disk
        do {
            try updatedContent.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            return .error(.executionFailed("Failed to write file: \(error.localizedDescription)"))
        }
        
        NotificationCenter.default.post(
            name: .agentFileDidChange,
            object: nil,
            userInfo: [
                "url": fileURL,
                "oldContent": originalContent,
                "newContent": updatedContent
            ]
        )
        return .success(.text("Updated file: \(path)"))
    }
}

/// Tool for deleting files
public struct DeleteFileTool: MCPTool {
    public let definition = ToolDefinition(
        id: "delete_file",
        name: "Delete File",
        description: "Delete a file from the project",
        category: .file,
        parameters: [
            ToolParameter(name: "path", description: "File path relative to project root", type: .string),
            ToolParameter(name: "confirm", description: "Confirm deletion", type: .boolean, required: true)
        ],
        icon: "trash"
    )
    
    public init() {}
    
    public func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        guard let path = invocation.parameters["path"]?.stringValue else {
            return .error(.missingParameter("path"))
        }
        guard let confirm = invocation.parameters["confirm"]?.boolValue, confirm else {
            return .error(ToolError(
                code: "NOT_CONFIRMED",
                message: "Deletion must be confirmed by setting confirm to true"
            ))
        }
        
        let fileURL: URL
        if let projectRoot = invocation.context.projectRoot {
            fileURL = projectRoot.appendingPathComponent(path)
        } else {
            fileURL = URL(fileURLWithPath: path)
        }
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .error(ToolError(code: "FILE_NOT_FOUND", message: "File not found: \(path)"))
        }
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            return .success(.text("Deleted file: \(path)"))
        } catch {
            return .error(.executionFailed("Failed to delete file: \(error.localizedDescription)"))
        }
    }
}

/// Tool for listing directory contents
public struct ListDirectoryTool: MCPTool {
    public let definition = ToolDefinition(
        id: "list_directory",
        name: "List Directory",
        description: "List files and directories in a path",
        category: .file,
        parameters: [
            ToolParameter(name: "path", description: "Directory path relative to project root", type: .string, required: false, defaultValue: "."),
            ToolParameter(name: "recursive", description: "List recursively", type: .boolean, required: false, defaultValue: "false"),
            ToolParameter(name: "include_hidden", description: "Include hidden files", type: .boolean, required: false, defaultValue: "false")
        ],
        icon: "folder"
    )
    
    public init() {}
    
    public func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        let path = invocation.parameters["path"]?.stringValue ?? "."
        let recursive = invocation.parameters["recursive"]?.boolValue ?? false
        let includeHidden = invocation.parameters["include_hidden"]?.boolValue ?? false
        
        let dirURL: URL
        if let projectRoot = invocation.context.projectRoot {
            dirURL = path == "." ? projectRoot : projectRoot.appendingPathComponent(path)
        } else {
            dirURL = URL(fileURLWithPath: path)
        }
        
        guard FileManager.default.fileExists(atPath: dirURL.path) else {
            return .error(ToolError(code: "DIR_NOT_FOUND", message: "Directory not found: \(path)"))
        }
        
        var entries: [String] = []
        
        if recursive {
            if let enumerator = FileManager.default.enumerator(
                at: dirURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: includeHidden ? [] : [.skipsHiddenFiles]
            ) {
                while let fileURL = enumerator.nextObject() as? URL {
                    let relativePath = fileURL.path.replacingOccurrences(of: dirURL.path + "/", with: "")
                    let isDir = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                    entries.append(isDir ? "📁 \(relativePath)/" : "📄 \(relativePath)")
                }
            }
        } else {
            let contents = try FileManager.default.contentsOfDirectory(
                at: dirURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: includeHidden ? [] : [.skipsHiddenFiles]
            )
            
            for fileURL in contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let isDir = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                entries.append(isDir ? "📁 \(fileURL.lastPathComponent)/" : "📄 \(fileURL.lastPathComponent)")
            }
        }
        
        if entries.isEmpty {
            return .success(.text("Directory is empty: \(path)"))
        }
        
        return .success(.text("Contents of \(path):\n\(entries.joined(separator: "\n"))"))
    }
}

/// Tool for searching files by content
public struct SearchFilesTool: MCPTool {
    public let definition = ToolDefinition(
        id: "search_files",
        name: "Search Files",
        description: "Search for files containing specific text or matching a pattern",
        category: .file,
        parameters: [
            ToolParameter(name: "query", description: "Text to search for", type: .string),
            ToolParameter(name: "path", description: "Directory to search in", type: .string, required: false, defaultValue: "."),
            ToolParameter(name: "file_pattern", description: "File pattern (e.g., *.swift)", type: .string, required: false),
            ToolParameter(name: "case_sensitive", description: "Case sensitive search", type: .boolean, required: false, defaultValue: "false")
        ],
        icon: "magnifyingglass"
    )
    
    public init() {}
    
    public func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        guard let query = invocation.parameters["query"]?.stringValue else {
            return .error(.missingParameter("query"))
        }
        
        let path = invocation.parameters["path"]?.stringValue ?? "."
        let filePattern = invocation.parameters["file_pattern"]?.stringValue
        let caseSensitive = invocation.parameters["case_sensitive"]?.boolValue ?? false
        
        let searchURL: URL
        if let projectRoot = invocation.context.projectRoot {
            searchURL = path == "." ? projectRoot : projectRoot.appendingPathComponent(path)
        } else {
            searchURL = URL(fileURLWithPath: path)
        }
        
        var results: [(file: String, line: Int, content: String)] = []
        let searchQuery = caseSensitive ? query : query.lowercased()
        
        if let enumerator = FileManager.default.enumerator(
            at: searchURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            while let fileURL = enumerator.nextObject() as? URL {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                      resourceValues.isRegularFile == true else { continue }
                
                // Check file pattern
                if let pattern = filePattern {
                    let fileName = fileURL.lastPathComponent
                    if !matchesPattern(fileName, pattern: pattern) { continue }
                }
                
                // Search file content
                guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
                
                let lines = content.components(separatedBy: "\n")
                for (index, line) in lines.enumerated() {
                    let searchLine = caseSensitive ? line : line.lowercased()
                    if searchLine.contains(searchQuery) {
                        let relativePath = fileURL.path.replacingOccurrences(of: searchURL.path + "/", with: "")
                        results.append((relativePath, index + 1, line.trimmingCharacters(in: .whitespaces)))
                        
                        if results.count >= 50 { break } // Limit results
                    }
                }
                
                if results.count >= 50 { break }
            }
        }
        
        if results.isEmpty {
            return .success(.text("No matches found for '\(query)'"))
        }
        
        var output = "Found \(results.count) matches for '\(query)':\n\n"
        for result in results {
            output += "\(result.file):\(result.line): \(result.content.prefix(100))\n"
        }
        
        return .success(.text(output))
    }
    
    private func matchesPattern(_ filename: String, pattern: String) -> Bool {
        // Simple glob matching
        let regex = pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")
        return filename.range(of: "^\(regex)$", options: .regularExpression, range: nil, locale: nil) != nil
    }
}

/// Tool for copying files
public struct CopyFileTool: MCPTool {
    public let definition = ToolDefinition(
        id: "copy_file",
        name: "Copy File",
        description: "Copy a file to a new location",
        category: .file,
        parameters: [
            ToolParameter(name: "source", description: "Source file path", type: .string),
            ToolParameter(name: "destination", description: "Destination file path", type: .string),
            ToolParameter(name: "overwrite", description: "Overwrite if exists", type: .boolean, required: false, defaultValue: "false")
        ],
        icon: "doc.on.doc"
    )
    
    public init() {}
    
    public func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        guard let source = invocation.parameters["source"]?.stringValue else {
            return .error(.missingParameter("source"))
        }
        guard let destination = invocation.parameters["destination"]?.stringValue else {
            return .error(.missingParameter("destination"))
        }
        
        let overwrite = invocation.parameters["overwrite"]?.boolValue ?? false
        
        let sourceURL: URL
        let destURL: URL
        
        if let projectRoot = invocation.context.projectRoot {
            sourceURL = projectRoot.appendingPathComponent(source)
            destURL = projectRoot.appendingPathComponent(destination)
        } else {
            sourceURL = URL(fileURLWithPath: source)
            destURL = URL(fileURLWithPath: destination)
        }
        
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            return .error(ToolError(code: "FILE_NOT_FOUND", message: "Source file not found: \(source)"))
        }
        
        if FileManager.default.fileExists(atPath: destURL.path) {
            if overwrite {
                try? FileManager.default.removeItem(at: destURL)
            } else {
                return .error(ToolError(
                    code: "FILE_EXISTS",
                    message: "Destination file exists: \(destination)",
                    suggestions: ["Set overwrite to true"]
                ))
            }
        }
        
        // Create parent directories
        try? FileManager.default.createDirectory(at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            return .success(.text("Copied \(source) to \(destination)"))
        } catch {
            return .error(.executionFailed("Failed to copy file: \(error.localizedDescription)"))
        }
    }
}

/// Tool for moving/renaming files
public struct MoveFileTool: MCPTool {
    public let definition = ToolDefinition(
        id: "move_file",
        name: "Move/Rename File",
        description: "Move or rename a file",
        category: .file,
        parameters: [
            ToolParameter(name: "source", description: "Source file path", type: .string),
            ToolParameter(name: "destination", description: "Destination file path", type: .string)
        ],
        icon: "arrow.right.doc.on.clipboard"
    )
    
    public init() {}
    
    public func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        guard let source = invocation.parameters["source"]?.stringValue else {
            return .error(.missingParameter("source"))
        }
        guard let destination = invocation.parameters["destination"]?.stringValue else {
            return .error(.missingParameter("destination"))
        }
        
        let sourceURL: URL
        let destURL: URL
        
        if let projectRoot = invocation.context.projectRoot {
            sourceURL = projectRoot.appendingPathComponent(source)
            destURL = projectRoot.appendingPathComponent(destination)
        } else {
            sourceURL = URL(fileURLWithPath: source)
            destURL = URL(fileURLWithPath: destination)
        }
        
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            return .error(ToolError(code: "FILE_NOT_FOUND", message: "Source file not found: \(source)"))
        }
        
        // Create parent directories
        try? FileManager.default.createDirectory(at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        do {
            try FileManager.default.moveItem(at: sourceURL, to: destURL)
            return .success(.text("Moved \(source) to \(destination)"))
        } catch {
            return .error(.executionFailed("Failed to move file: \(error.localizedDescription)"))
        }
    }
}
