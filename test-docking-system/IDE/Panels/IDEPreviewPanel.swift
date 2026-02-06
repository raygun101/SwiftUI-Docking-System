import SwiftUI
import Combine
import WebKit

// MARK: - Preview Panel

/// Live preview panel for HTML and other previewable content bound to a specific document
public struct IDEPreviewPanel: View {
    @ObservedObject var document: IDEDocument
    @Environment(\.dockTheme) var theme
    
    @State private var refreshTrigger: UUID = UUID()
    @State private var isAutoRefresh: Bool = true
    @State private var scale: CGFloat = 1.0
    @State private var lastAutoRefreshedDocumentID: UUID?
    @State private var lastAutoRefreshedContentHash: Int?
    @State private var contentSubscription: AnyCancellable?
    @State private var subscribedDocumentID: UUID?
    
    public init(document: IDEDocument) {
        self.document = document
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            DockPanelToolbar { previewToolbar }
            previewContent
        }
        .background(theme.colors.panelBackground)
        .onAppear(perform: subscribeToDocument)
    }
    
    // MARK: - Toolbar
    
    private var previewToolbar: some View {
        DockToolbarScaffold(leading: {
            DockToolbarChip(icon: "display", title: document.name)
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
        PreviewWebView(
            document: document,
            refreshTrigger: refreshTrigger,
            scale: scale
        )
    }
    
    // MARK: - Helpers
    
    private func refreshPreview() {
        refreshTrigger = UUID()
    }

    private func subscribeToDocument() {
        guard subscribedDocumentID != document.id else { return }
        subscribedDocumentID = document.id
        contentSubscription?.cancel()
        let documentID = document.id
        contentSubscription = document.buffer.$currentContent
            .debounce(for: .milliseconds(75), scheduler: RunLoop.main)
            .sink { latestContent in
                guard isAutoRefresh else { return }
                let contentHash = latestContent.hashValue
                guard documentID != lastAutoRefreshedDocumentID || contentHash != lastAutoRefreshedContentHash else {
                    return
                }
                lastAutoRefreshedDocumentID = documentID
                lastAutoRefreshedContentHash = contentHash
                refreshPreview()
            }
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
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
        // Apply scale only when it actually changes so we don't reset scroll offset each update
        let scrollView = webView.scrollView
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 2.0
        if abs(scrollView.zoomScale - scale) > 0.001 {
            scrollView.setZoomScale(scale, animated: false)
        }
        
        // Load content only when it actually changed or a manual refresh was requested
        if context.coordinator.lastHTML != htmlContent || context.coordinator.lastRefreshTrigger != refreshTrigger {
            context.coordinator.lastHTML = htmlContent
            context.coordinator.lastRefreshTrigger = refreshTrigger
            webView.loadHTMLString(htmlContent, baseURL: baseURL)
        }
    }
    
    final class Coordinator {
        var lastHTML: String?
        var lastRefreshTrigger: UUID?
    }
}
