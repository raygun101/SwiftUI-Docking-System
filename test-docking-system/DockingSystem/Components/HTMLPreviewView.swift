import SwiftUI
import WebKit

// MARK: - HTML Preview View

/// A SwiftUI wrapper for previewing HTML content using WKWebView
public struct HTMLPreviewView: View {
    let htmlContent: String
    let baseURL: URL?
    let enableJavaScript: Bool
    let onNavigate: ((URL) -> Void)?
    
    public init(
        htmlContent: String,
        baseURL: URL? = nil,
        enableJavaScript: Bool = true,
        onNavigate: ((URL) -> Void)? = nil
    ) {
        self.htmlContent = htmlContent
        self.baseURL = baseURL
        self.enableJavaScript = enableJavaScript
        self.onNavigate = onNavigate
    }
    
    public var body: some View {
        HTMLPreviewRepresentable(
            htmlContent: htmlContent,
            baseURL: baseURL,
            enableJavaScript: enableJavaScript,
            onNavigate: onNavigate
        )
    }
}

// MARK: - URL Preview View

/// A SwiftUI wrapper for loading and displaying a URL
public struct URLPreviewView: View {
    let url: URL
    let enableJavaScript: Bool
    let onNavigate: ((URL) -> Void)?
    
    @State private var isLoading = true
    @State private var loadError: String?
    
    public init(
        url: URL,
        enableJavaScript: Bool = true,
        onNavigate: ((URL) -> Void)? = nil
    ) {
        self.url = url
        self.enableJavaScript = enableJavaScript
        self.onNavigate = onNavigate
    }
    
    public var body: some View {
        ZStack {
            URLPreviewRepresentable(
                url: url,
                enableJavaScript: enableJavaScript,
                isLoading: $isLoading,
                loadError: $loadError,
                onNavigate: onNavigate
            )
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            if let error = loadError {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Failed to load")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
    }
}

// MARK: - HTML Preview Representable

struct HTMLPreviewRepresentable: UIViewRepresentable {
    let htmlContent: String
    let baseURL: URL?
    let enableJavaScript: Bool
    let onNavigate: ((URL) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = enableJavaScript
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .white
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only reload if content changed
        if context.coordinator.lastHTML != htmlContent {
            context.coordinator.lastHTML = htmlContent
            webView.loadHTMLString(htmlContent, baseURL: baseURL)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: HTMLPreviewRepresentable
        var lastHTML: String = ""
        
        init(_ parent: HTMLPreviewRepresentable) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                parent.onNavigate?(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

// MARK: - URL Preview Representable

struct URLPreviewRepresentable: UIViewRepresentable {
    let url: URL
    let enableJavaScript: Bool
    @Binding var isLoading: Bool
    @Binding var loadError: String?
    let onNavigate: ((URL) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = enableJavaScript
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .white
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Reload if URL changed
        if context.coordinator.lastURL != url {
            context.coordinator.lastURL = url
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: URLPreviewRepresentable
        var lastURL: URL?
        
        init(_ parent: URLPreviewRepresentable) {
            self.parent = parent
            self.lastURL = parent.url
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.loadError = nil
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.loadError = error.localizedDescription
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.loadError = error.localizedDescription
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                parent.onNavigate?(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct HTMLPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        HTMLPreviewView(
            htmlContent: """
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: -apple-system, sans-serif; padding: 20px; }
                    h1 { color: #333; }
                    p { color: #666; line-height: 1.6; }
                </style>
            </head>
            <body>
                <h1>Hello, World!</h1>
                <p>This is a preview of HTML content.</p>
            </body>
            </html>
            """
        )
        .frame(height: 300)
    }
}
#endif
