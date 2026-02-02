import SwiftUI

// MARK: - Editor Protocol

/// Protocol for IDE editors
public protocol IDEEditor {
    associatedtype EditorView: View
    
    var supportedTypes: [IDEEditorType] { get }
    
    func makeView(for document: IDEDocument) -> EditorView
}

// MARK: - Editor Registry

/// Registry for editor components
public class IDEEditorRegistry {
    public static let shared = IDEEditorRegistry()
    
    private init() {}
    
    // MARK: - Editor View Factory
    
    @ViewBuilder
    public func editorView(for document: IDEDocument) -> some View {
        switch document.fileType.editorType {
        case .code, .json, .text:
            CodeEditorWrapper(document: document)
        case .html:
            CodeEditorWrapper(document: document)
        case .markdown:
            MarkdownEditorWrapper(document: document)
        case .image:
            ImageViewerWrapper(document: document)
        default:
            CodeEditorWrapper(document: document)
        }
    }
    
    @ViewBuilder
    public func previewView(for document: IDEDocument) -> some View {
        switch document.fileType.editorType {
        case .html:
            HTMLPreviewWrapper(document: document)
        case .markdown:
            MarkdownPreviewWrapper(document: document)
        case .image:
            ImageViewerWrapper(document: document)
        default:
            Text("No preview available")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Code Editor Wrapper

struct CodeEditorWrapper: View {
    @ObservedObject var document: IDEDocument
    
    var body: some View {
        MonacoEditorView(
            code: Binding(
                get: { document.content },
                set: { document.updateContent($0) }
            ),
            language: document.fileType.language ?? "plaintext",
            theme: .vsDark,
            readOnly: false,
            comparisonContent: document.agentChange?.oldContent
        ) { newContent in
            document.updateContent(newContent)
        }
    }
}

// MARK: - HTML Preview Wrapper

struct HTMLPreviewWrapper: View {
    @ObservedObject var document: IDEDocument
    
    var body: some View {
        HTMLPreviewView(htmlContent: document.content, baseURL: document.fileURL.deletingLastPathComponent())
    }
}

// MARK: - Markdown Editor Wrapper

struct MarkdownEditorWrapper: View {
    @ObservedObject var document: IDEDocument
    
    var body: some View {
        MonacoEditorView(
            code: Binding(
                get: { document.content },
                set: { document.updateContent($0) }
            ),
            language: "markdown",
            theme: .vsDark,
            readOnly: false,
            comparisonContent: document.agentChange?.oldContent
        ) { newContent in
            document.updateContent(newContent)
        }
    }
}

// MARK: - Markdown Preview Wrapper

struct MarkdownPreviewWrapper: View {
    @ObservedObject var document: IDEDocument
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let htmlContent = convertMarkdownToHTML(document.content)
        HTMLPreviewView(htmlContent: htmlContent, baseURL: document.fileURL.deletingLastPathComponent())
    }
    
    private func convertMarkdownToHTML(_ markdown: String) -> String {
        // Basic markdown to HTML conversion
        var html = markdown
        
        // Headers
        html = html.replacingOccurrences(of: "(?m)^### (.+)$", with: "<h3>$1</h3>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^## (.+)$", with: "<h2>$1</h2>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^# (.+)$", with: "<h1>$1</h1>", options: .regularExpression)
        
        // Bold and italic
        html = html.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: "\\*(.+?)\\*", with: "<em>$1</em>", options: .regularExpression)
        
        // Code blocks
        html = html.replacingOccurrences(of: "```([\\s\\S]*?)```", with: "<pre><code>$1</code></pre>", options: .regularExpression)
        html = html.replacingOccurrences(of: "`(.+?)`", with: "<code>$1</code>", options: .regularExpression)
        
        // Line breaks
        html = html.replacingOccurrences(of: "\n\n", with: "</p><p>")
        
        let isDark = colorScheme == .dark
        let bgColor = isDark ? "#1e1e1e" : "#ffffff"
        let textColor = isDark ? "#d4d4d4" : "#333333"
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    padding: 20px;
                    background-color: \(bgColor);
                    color: \(textColor);
                    line-height: 1.6;
                }
                code {
                    background-color: \(isDark ? "#2d2d2d" : "#f4f4f4");
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-family: 'SF Mono', Monaco, monospace;
                }
                pre {
                    background-color: \(isDark ? "#2d2d2d" : "#f4f4f4");
                    padding: 16px;
                    border-radius: 8px;
                    overflow-x: auto;
                }
                pre code {
                    background: none;
                    padding: 0;
                }
                h1, h2, h3 { margin-top: 24px; }
            </style>
        </head>
        <body>
            <p>\(html)</p>
        </body>
        </html>
        """
    }
}

// MARK: - Image Viewer Wrapper

struct ImageViewerWrapper: View {
    @ObservedObject var document: IDEDocument
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                ScrollView([.horizontal, .vertical]) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                }
            } else {
                ProgressView("Loading image...")
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        if let data = try? Data(contentsOf: document.fileURL),
           let loadedImage = UIImage(data: data) {
            image = loadedImage
        }
    }
}
