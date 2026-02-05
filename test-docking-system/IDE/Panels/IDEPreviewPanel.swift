import SwiftUI
import Combine
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
            DockPanelToolbar { previewToolbar }
            previewContent
        }
        .background(theme.colors.panelBackground)
        .onReceive(activeDocumentContentPublisher) { _ in
            if isAutoRefresh {
                refreshPreview()
            }
        }
    }
    
    // MARK: - Toolbar
    
    private var previewToolbar: some View {
        DockToolbarScaffold(leading: {
            if let document = previewDocument {
                DockToolbarChip(icon: "display", title: document.name)
            } else {
                DockToolbarChip(icon: "eye.slash", title: "No Preview")
            }
        }, trailing: {
            DockToolbarIconButton(
                "arrow.triangle.2.circlepath",
                accessibilityLabel: "Toggle auto refresh",
                role: .accent,
                isActive: isAutoRefresh
            ) {
                isAutoRefresh.toggle()
            }
            
            DockToolbarIconButton(
                "arrow.clockwise",
                accessibilityLabel: "Refresh preview"
            ) {
                refreshPreview()
            }
            
            DockToolbarIconButton(
                "minus.magnifyingglass",
                accessibilityLabel: "Zoom out"
            ) {
                scale = max(0.5, scale - 0.25)
            }
            .disabled(scale <= 0.5)
            
            DockToolbarChip(title: "\(Int(scale * 100))%", subtitle: "Zoom")
                .frame(minWidth: 48)
            
            DockToolbarIconButton(
                "plus.magnifyingglass",
                accessibilityLabel: "Zoom in"
            ) {
                scale = min(2.0, scale + 0.25)
            }
            .disabled(scale >= 2.0)
        })
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

    private var activeDocumentContentPublisher: AnyPublisher<String, Never> {
        if let document = project.activeDocument {
            return document.buffer.$currentContent
                .debounce(for: .milliseconds(75), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        return Empty().eraseToAnyPublisher()
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
