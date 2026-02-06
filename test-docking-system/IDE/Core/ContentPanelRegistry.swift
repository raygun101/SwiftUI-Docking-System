import SwiftUI
import Combine

// MARK: - Content Panel Registry

/// Central registry for content panel types and their view factories
@MainActor
public final class ContentPanelRegistry: ObservableObject {
    public static let shared = ContentPanelRegistry()
    
    /// All registered panel descriptors
    @Published public private(set) var descriptors: [String: ContentPanelDescriptor] = [:]
    
    /// Mapping from file type ID to available panel descriptor IDs
    private var fileTypePanelMap: [String: [String]] = [:]
    
    /// View factories keyed by descriptor ID
    private var viewFactories: [String: (IDEDocument) -> AnyView] = [:]
    
    private init() {
        registerBuiltInPanels()
    }
    
    // MARK: - Registration
    
    /// Register a panel descriptor with its view factory
    public func register<V: View>(
        _ descriptor: ContentPanelDescriptor,
        viewFactory: @escaping (IDEDocument) -> V
    ) {
        descriptors[descriptor.id] = descriptor
        viewFactories[descriptor.id] = { doc in AnyView(viewFactory(doc)) }
        
        // Update file type mappings
        if descriptor.supportedFileTypes.isEmpty {
            // Supports all types - add to universal panels
            for fileTypeID in IDEFileTypeRegistry.shared.allFileTypes.map({ $0.id }) {
                addPanelToFileType(descriptor.id, fileTypeID: fileTypeID)
            }
        } else {
            for fileTypeID in descriptor.supportedFileTypes {
                addPanelToFileType(descriptor.id, fileTypeID: fileTypeID)
            }
        }
    }
    
    /// Unregister a panel descriptor
    public func unregister(_ descriptorID: String) {
        descriptors.removeValue(forKey: descriptorID)
        viewFactories.removeValue(forKey: descriptorID)
        
        // Remove from all file type mappings
        for (fileTypeID, panelIDs) in fileTypePanelMap {
            fileTypePanelMap[fileTypeID] = panelIDs.filter { $0 != descriptorID }
        }
    }
    
    private func addPanelToFileType(_ panelID: String, fileTypeID: String) {
        var panels = fileTypePanelMap[fileTypeID] ?? []
        if !panels.contains(panelID) {
            panels.append(panelID)
            fileTypePanelMap[fileTypeID] = panels
        }
    }
    
    // MARK: - Lookup
    
    /// Get all available panel descriptors for a file type
    public func availablePanels(for fileType: IDEFileType) -> [ContentPanelDescriptor] {
        let panelIDs = fileTypePanelMap[fileType.id] ?? []
        return panelIDs
            .compactMap { descriptors[$0] }
            .sorted { $0.priority > $1.priority }
    }
    
    /// Get all available panel descriptors for a document
    public func availablePanels(for document: IDEDocument) -> [ContentPanelDescriptor] {
        availablePanels(for: document.fileType)
    }
    
    /// Get the default panel descriptor for a file type
    public func defaultPanel(for fileType: IDEFileType) -> ContentPanelDescriptor {
        availablePanels(for: fileType).first ?? .codeEditor
    }
    
    /// Get a specific panel descriptor by ID
    public func panel(withID id: String) -> ContentPanelDescriptor? {
        descriptors[id]
    }
    
    // MARK: - View Factory
    
    /// Create a view for a document using a specific panel descriptor
    @ViewBuilder
    public func makeView(for document: IDEDocument, using descriptor: ContentPanelDescriptor) -> some View {
        if let factory = viewFactories[descriptor.id] {
            factory(document)
        } else {
            // Fallback to code editor
            CodeEditorWrapper(document: document)
        }
    }
    
    /// Create the default view for a document
    @ViewBuilder
    public func makeDefaultView(for document: IDEDocument) -> some View {
        let descriptor = defaultPanel(for: document.fileType)
        makeView(for: document, using: descriptor)
    }
    
    // MARK: - Built-in Panel Registration
    
    private func registerBuiltInPanels() {
        // Code Editor - supports all text types
        register(.codeEditor) { document in
            CodeEditorWrapper(document: document)
        }
        
        // HTML Preview
        register(.htmlPreview) { document in
            IDEPreviewPanel(document: document)
        }
        
        // Markdown Preview
        register(.markdownPreview) { document in
            MarkdownPreviewWrapper(document: document)
        }
        
        // Image Viewer
        register(.imageViewer) { document in
            ImageViewerWrapper(document: document)
        }
        
        // Raw Text Viewer
        register(.rawViewer) { document in
            RawTextViewer(document: document)
        }
    }
}

// MARK: - Raw Text Viewer

struct RawTextViewer: View {
    @ObservedObject var document: IDEDocument
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        ScrollView {
            Text(document.content)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(theme.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(theme.colors.panelBackground)
    }
}

// MARK: - Convenience Extensions

extension IDEEditorRegistry {
    /// Bridge to ContentPanelRegistry for backwards compatibility
    @MainActor
    @ViewBuilder
    public func panelView(for document: IDEDocument, panelID: String? = nil) -> some View {
        if let panelID = panelID,
           let descriptor = ContentPanelRegistry.shared.panel(withID: panelID) {
            ContentPanelRegistry.shared.makeView(for: document, using: descriptor)
        } else {
            ContentPanelRegistry.shared.makeDefaultView(for: document)
        }
    }
}
