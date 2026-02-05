import Foundation
import SwiftUI

// MARK: - File Type Definition

/// Defines a file type with its associated metadata and editor
public struct IDEFileType: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let extensions: [String]
    public let icon: String
    public let iconColor: Color
    public let language: String?
    public let editorType: IDEEditorType
    public let canPreview: Bool
    
    public init(
        id: String,
        name: String,
        extensions: [String],
        icon: String,
        iconColor: Color,
        language: String? = nil,
        editorType: IDEEditorType = .code,
        canPreview: Bool = false
    ) {
        self.id = id
        self.name = name
        self.extensions = extensions
        self.icon = icon
        self.iconColor = iconColor
        self.language = language
        self.editorType = editorType
        self.canPreview = canPreview
    }
    
    public static func == (lhs: IDEFileType, rhs: IDEFileType) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Whether this file type represents binary (non-text) content
    public var isBinary: Bool {
        switch editorType {
        case .image, .binary:
            return true
        default:
            return false
        }
    }
}

// MARK: - Editor Types

public enum IDEEditorType: String, CaseIterable {
    case code
    case markdown
    case image
    case html
    case json
    case text
    case binary
    case unknown
}

// MARK: - File Type Registry

/// Central registry for all file types and their editors
public class IDEFileTypeRegistry {
    public static let shared = IDEFileTypeRegistry()
    
    private var fileTypes: [String: IDEFileType] = [:]
    private var extensionMap: [String: IDEFileType] = [:]
    
    private init() {
        registerBuiltInTypes()
    }
    
    // MARK: - Registration
    
    public func register(_ fileType: IDEFileType) {
        fileTypes[fileType.id] = fileType
        for ext in fileType.extensions {
            extensionMap[ext.lowercased()] = fileType
        }
    }
    
    public func unregister(_ id: String) {
        guard let fileType = fileTypes[id] else { return }
        fileTypes.removeValue(forKey: id)
        for ext in fileType.extensions {
            extensionMap.removeValue(forKey: ext.lowercased())
        }
    }
    
    // MARK: - Lookup
    
    public func fileType(for url: URL) -> IDEFileType {
        let ext = url.pathExtension.lowercased()
        return extensionMap[ext] ?? .unknown
    }
    
    public func fileType(forExtension ext: String) -> IDEFileType {
        return extensionMap[ext.lowercased()] ?? .unknown
    }
    
    public func fileType(withID id: String) -> IDEFileType? {
        return fileTypes[id]
    }
    
    public var allFileTypes: [IDEFileType] {
        Array(fileTypes.values).sorted { $0.name < $1.name }
    }
    
    // MARK: - Built-in Types
    
    private func registerBuiltInTypes() {
        // HTML
        register(IDEFileType(
            id: "html",
            name: "HTML",
            extensions: ["html", "htm"],
            icon: "globe",
            iconColor: .orange,
            language: "html",
            editorType: .html,
            canPreview: true
        ))
        
        // CSS
        register(IDEFileType(
            id: "css",
            name: "CSS",
            extensions: ["css"],
            icon: "paintbrush",
            iconColor: .blue,
            language: "css",
            editorType: .code
        ))
        
        // JavaScript
        register(IDEFileType(
            id: "javascript",
            name: "JavaScript",
            extensions: ["js", "mjs"],
            icon: "curlybraces",
            iconColor: .yellow,
            language: "javascript",
            editorType: .code
        ))
        
        // TypeScript
        register(IDEFileType(
            id: "typescript",
            name: "TypeScript",
            extensions: ["ts", "tsx"],
            icon: "curlybraces",
            iconColor: .blue,
            language: "typescript",
            editorType: .code
        ))
        
        // JSON
        register(IDEFileType(
            id: "json",
            name: "JSON",
            extensions: ["json"],
            icon: "curlybraces.square",
            iconColor: .green,
            language: "json",
            editorType: .json
        ))
        
        // Markdown
        register(IDEFileType(
            id: "markdown",
            name: "Markdown",
            extensions: ["md", "markdown"],
            icon: "doc.richtext",
            iconColor: .purple,
            language: "markdown",
            editorType: .markdown,
            canPreview: true
        ))
        
        // Swift
        register(IDEFileType(
            id: "swift",
            name: "Swift",
            extensions: ["swift"],
            icon: "swift",
            iconColor: .orange,
            language: "swift",
            editorType: .code
        ))
        
        // Python
        register(IDEFileType(
            id: "python",
            name: "Python",
            extensions: ["py"],
            icon: "chevron.left.forwardslash.chevron.right",
            iconColor: .green,
            language: "python",
            editorType: .code
        ))
        
        // XML
        register(IDEFileType(
            id: "xml",
            name: "XML",
            extensions: ["xml", "plist", "svg"],
            icon: "chevron.left.forwardslash.chevron.right",
            iconColor: .teal,
            language: "xml",
            editorType: .code
        ))
        
        // Plain Text
        register(IDEFileType(
            id: "text",
            name: "Plain Text",
            extensions: ["txt", "text"],
            icon: "doc.text",
            iconColor: .gray,
            language: nil,
            editorType: .text
        ))
        
        // Images
        register(IDEFileType(
            id: "image",
            name: "Image",
            extensions: ["png", "jpg", "jpeg", "gif", "webp", "ico"],
            icon: "photo",
            iconColor: .pink,
            language: nil,
            editorType: .image,
            canPreview: true
        ))
        
        // YAML
        register(IDEFileType(
            id: "yaml",
            name: "YAML",
            extensions: ["yaml", "yml"],
            icon: "list.bullet.indent",
            iconColor: .red,
            language: "yaml",
            editorType: .code
        ))
    }
}

// MARK: - Default Unknown Type

extension IDEFileType {
    public static let unknown = IDEFileType(
        id: "unknown",
        name: "Unknown",
        extensions: [],
        icon: "doc",
        iconColor: .gray,
        language: nil,
        editorType: .unknown
    )
}
