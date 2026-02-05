import Foundation
import SwiftUI
import Combine

// MARK: - Content Panel Descriptor

/// Describes a type of content panel that can display file content
public struct ContentPanelDescriptor: Identifiable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let icon: String
    public let isEditable: Bool
    public let supportedFileTypes: [String]  // File type IDs, empty means all types
    public let priority: Int  // Higher priority = shown first in menus
    
    public init(
        id: String,
        name: String,
        icon: String,
        isEditable: Bool = false,
        supportedFileTypes: [String] = [],
        priority: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isEditable = isEditable
        self.supportedFileTypes = supportedFileTypes
        self.priority = priority
    }
    
    public static func == (lhs: ContentPanelDescriptor, rhs: ContentPanelDescriptor) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// Check if this panel supports a given file type
    public func supports(fileType: IDEFileType) -> Bool {
        supportedFileTypes.isEmpty || supportedFileTypes.contains(fileType.id)
    }
}

// MARK: - Built-in Panel Descriptors

extension ContentPanelDescriptor {
    /// Code editor panel (default for most file types)
    public static let codeEditor = ContentPanelDescriptor(
        id: "code_editor",
        name: "Code Editor",
        icon: "chevron.left.forwardslash.chevron.right",
        isEditable: true,
        supportedFileTypes: [],  // Supports all text files
        priority: 100
    )
    
    /// HTML live preview panel
    public static let htmlPreview = ContentPanelDescriptor(
        id: "html_preview",
        name: "HTML Preview",
        icon: "globe",
        isEditable: false,
        supportedFileTypes: ["html"],
        priority: 90
    )
    
    /// Markdown preview panel
    public static let markdownPreview = ContentPanelDescriptor(
        id: "markdown_preview",
        name: "Markdown Preview",
        icon: "doc.richtext",
        isEditable: false,
        supportedFileTypes: ["markdown"],
        priority: 90
    )
    
    /// Image viewer panel
    public static let imageViewer = ContentPanelDescriptor(
        id: "image_viewer",
        name: "Image Viewer",
        icon: "photo",
        isEditable: false,
        supportedFileTypes: ["image"],
        priority: 100
    )
    
    /// Diff viewer panel
    public static let diffViewer = ContentPanelDescriptor(
        id: "diff_viewer",
        name: "Diff Viewer",
        icon: "arrow.left.arrow.right",
        isEditable: false,
        supportedFileTypes: [],
        priority: 50
    )
    
    /// Raw text viewer (read-only)
    public static let rawViewer = ContentPanelDescriptor(
        id: "raw_viewer",
        name: "Raw Text",
        icon: "doc.plaintext",
        isEditable: false,
        supportedFileTypes: [],
        priority: 10
    )
}

// MARK: - Content Panel Context

/// Context provided to content panels
public struct ContentPanelContext {
    public let buffer: ContentBuffer
    public let document: IDEDocument
    public let descriptor: ContentPanelDescriptor
    public let panelInstanceID: UUID
    
    public init(
        buffer: ContentBuffer,
        document: IDEDocument,
        descriptor: ContentPanelDescriptor,
        panelInstanceID: UUID = UUID()
    ) {
        self.buffer = buffer
        self.document = document
        self.descriptor = descriptor
        self.panelInstanceID = panelInstanceID
    }
}

// MARK: - Content Panel Protocol

/// Protocol for views that display file content
public protocol ContentPanelView: View {
    var context: ContentPanelContext { get }
}

// MARK: - Base Content Panel View

/// Base SwiftUI view providing common functionality for content panels
public struct BaseContentPanel<Content: View>: View {
    @ObservedObject var buffer: ContentBuffer
    let descriptor: ContentPanelDescriptor
    let content: () -> Content
    
    @Environment(\.dockTheme) var theme
    
    public init(
        buffer: ContentBuffer,
        descriptor: ContentPanelDescriptor,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.buffer = buffer
        self.descriptor = descriptor
        self.content = content
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(theme.colors.panelBackground)
    }
}

// MARK: - Content Panel Instance

/// Represents an active instance of a content panel
public class ContentPanelInstance: ObservableObject, Identifiable {
    public let id: UUID
    public let descriptor: ContentPanelDescriptor
    public let fileURL: URL
    public weak var buffer: ContentBuffer?
    
    @Published public var scrollPosition: CGPoint = .zero
    @Published public var cursorPosition: (line: Int, column: Int)?
    @Published public var selectionRange: Range<String.Index>?
    
    public init(
        descriptor: ContentPanelDescriptor,
        fileURL: URL,
        buffer: ContentBuffer?
    ) {
        self.id = UUID()
        self.descriptor = descriptor
        self.fileURL = fileURL
        self.buffer = buffer
    }
    
    public var displayName: String {
        let fileName = fileURL.lastPathComponent
        if descriptor.id == ContentPanelDescriptor.codeEditor.id {
            return fileName
        }
        return "\(fileName) • \(descriptor.name)"
    }
}

// MARK: - Panel State for Layout Persistence

/// Serializable state for a panel instance (for layout persistence)
public struct ContentPanelState: Codable, Identifiable {
    public let id: UUID
    public let descriptorID: String
    public let fileURL: URL
    public var scrollY: CGFloat
    public var cursorLine: Int?
    public var cursorColumn: Int?
    
    public init(
        id: UUID = UUID(),
        descriptorID: String,
        fileURL: URL,
        scrollY: CGFloat = 0,
        cursorLine: Int? = nil,
        cursorColumn: Int? = nil
    ) {
        self.id = id
        self.descriptorID = descriptorID
        self.fileURL = fileURL
        self.scrollY = scrollY
        self.cursorLine = cursorLine
        self.cursorColumn = cursorColumn
    }
    
    public init(from instance: ContentPanelInstance) {
        self.id = instance.id
        self.descriptorID = instance.descriptor.id
        self.fileURL = instance.fileURL
        self.scrollY = instance.scrollPosition.y
        self.cursorLine = instance.cursorPosition?.line
        self.cursorColumn = instance.cursorPosition?.column
    }
}
