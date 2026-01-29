import SwiftUI
import WebKit

// MARK: - Preview Panel

/// Live preview panel for HTML and other previewable content
public struct IDEPreviewPanel: View {
    @ObservedObject var project: IDEProject
    @EnvironmentObject var ideState: IDEState
    @Environment(\.dockTheme) var theme
    
    @State private var refreshTrigger: UUID = UUID()
    @State private var isAutoRefresh: Bool = true
    @State private var scale: CGFloat = 1.0
    
    public init(project: IDEProject) {
        self.project = project
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Preview toolbar
            previewToolbar
            
            Divider()
            
            // Preview content
            previewContent
        }
        .background(theme.colors.panelBackground)
        .onChange(of: project.activeDocument?.content) { _, _ in
            if isAutoRefresh {
                refreshPreview()
            }
        }
    }
    
    // MARK: - Toolbar
    
    private var previewToolbar: some View {
        HStack(spacing: 12) {
            // Preview info
            if let document = previewDocument {
                HStack(spacing: 6) {
                    Image(systemName: "eye")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.accent)
                    
                    Text("Preview: \(document.name)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.colors.text)
                        .lineLimit(1)
                }
            } else {
                Text("Preview")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.colors.secondaryText)
            }
            
            Spacer()
            
            // Auto-refresh toggle
            Toggle(isOn: $isAutoRefresh) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12))
            }
            .toggleStyle(.button)
            .buttonStyle(.plain)
            .foregroundColor(isAutoRefresh ? theme.colors.accent : theme.colors.tertiaryText)
            
            // Manual refresh
            Button(action: refreshPreview) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundColor(theme.colors.secondaryText)
            
            // Scale controls
            HStack(spacing: 4) {
                Button(action: { scale = max(0.5, scale - 0.25) }) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(theme.colors.secondaryText)
                
                Text("\(Int(scale * 100))%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.colors.tertiaryText)
                    .frame(width: 36)
                
                Button(action: { scale = min(2.0, scale + 0.25) }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(theme.colors.secondaryText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.colors.headerBackground)
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var previewContent: some View {
        if let document = previewDocument {
            PreviewWebView(
                document: document,
                refreshTrigger: refreshTrigger,
                scale: scale
            )
        } else {
            emptyPreviewView
        }
    }
    
    private var emptyPreviewView: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye.slash")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.tertiaryText)
            
            Text("No preview available")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(theme.colors.secondaryText)
            
            Text("Open an HTML file to see a live preview")
                .font(.system(size: 13))
                .foregroundColor(theme.colors.tertiaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    
    private var previewDocument: IDEDocument? {
        // First check if there's a specific preview URL set
        if let previewURL = ideState.previewURL,
           let doc = project.openDocuments.first(where: { $0.fileURL == previewURL }) {
            return doc
        }
        // Otherwise use active document if it's previewable
        if let activeDoc = project.activeDocument, activeDoc.fileType.canPreview {
            return activeDoc
        }
        // Fall back to first previewable document
        return project.openDocuments.first { $0.fileType.canPreview }
    }
    
    private func refreshPreview() {
        refreshTrigger = UUID()
    }
}

// MARK: - Preview Web View

struct PreviewWebView: View {
    @ObservedObject var document: IDEDocument
    let refreshTrigger: UUID
    let scale: CGFloat
    
    var body: some View {
        LiveHTMLPreviewRepresentable(
            htmlContent: document.content,
            baseURL: document.fileURL.deletingLastPathComponent(),
            refreshTrigger: refreshTrigger,
            scale: scale
        )
    }
}

// MARK: - Live HTML Preview

struct LiveHTMLPreviewRepresentable: UIViewRepresentable {
    let htmlContent: String
    let baseURL: URL
    let refreshTrigger: UUID
    let scale: CGFloat
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Apply scale
        webView.scrollView.zoomScale = scale
        webView.scrollView.minimumZoomScale = 0.5
        webView.scrollView.maximumZoomScale = 2.0
        
        // Load content
        webView.loadHTMLString(htmlContent, baseURL: baseURL)
    }
}
