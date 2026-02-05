import SwiftUI
import WebKit

// MARK: - Monaco Editor View

/// A SwiftUI wrapper for the Monaco code editor using WKWebView
public struct MonacoEditorView: View {
    @Binding var code: String
    let language: String
    let theme: MonacoTheme
    let readOnly: Bool
    let comparisonContent: String?
    let onContentChange: ((String) -> Void)?
    
    public init(
        code: Binding<String>,
        language: String = "swift",
        theme: MonacoTheme = .vs,
        readOnly: Bool = false,
        comparisonContent: String? = nil,
        onContentChange: ((String) -> Void)? = nil
    ) {
        self._code = code
        self.language = language
        self.theme = theme
        self.readOnly = readOnly
        self.comparisonContent = comparisonContent
        self.onContentChange = onContentChange
    }
    
    public var body: some View {
        MonacoEditorRepresentable(
            code: $code,
            language: language,
            theme: theme,
            readOnly: readOnly,
            comparisonContent: comparisonContent,
            onContentChange: onContentChange
        )
    }
}

// MARK: - Monaco Theme

public enum MonacoTheme: String {
    case vs = "vs"
    case vsDark = "vs-dark"
    case hcBlack = "hc-black"
    case hcLight = "hc-light"
}

// MARK: - UIViewRepresentable for WKWebView

struct MonacoEditorRepresentable: UIViewRepresentable {
    @Binding var code: String
    let language: String
    let theme: MonacoTheme
    let readOnly: Bool
    let comparisonContent: String?
    let onContentChange: ((String) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: "monacoHandler")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        
        // Load Monaco editor HTML
        let html = generateMonacoHTML()
        webView.loadHTMLString(html, baseURL: nil)

        context.coordinator.webView = webView
        context.coordinator.lastComparisonContent = comparisonContent
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self

        // Rebuild editor if diff mode changed
        if context.coordinator.lastComparisonContent != comparisonContent {
            context.coordinator.lastComparisonContent = comparisonContent
            context.coordinator.lastKnownCode = code
            context.coordinator.pendingCode = code
            context.coordinator.pendingComparison = comparisonContent
            context.coordinator.isEditorReady = false
            let html = generateMonacoHTML()
            webView.loadHTMLString(html, baseURL: nil)
            return
        }

        // Update code if changed externally
        if context.coordinator.lastKnownCode != code {
            context.coordinator.lastKnownCode = code
            context.coordinator.pendingCode = code
        }
        context.coordinator.pendingComparison = comparisonContent
        context.coordinator.applyPendingContentIfReady()
        
        // Update theme
        let themeJS = "if (window.monaco) { monaco.editor.setTheme('" + theme.rawValue + "'); }"
        webView.evaluateJavaScript(themeJS, completionHandler: nil)
        
        // Update language
        let langJS = "if (window.editor && window.monaco) { monaco.editor.setModelLanguage(window.editor.getModel(), '\(language)'); }"
        webView.evaluateJavaScript(langJS, completionHandler: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Generate Monaco HTML
    
    private func generateMonacoHTML() -> String {
        let escapedCode = code.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "</script>", with: "<\\/script>")
        let escapedComparison = (comparisonContent ?? "").replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "</script>", with: "<\\/script>")
        let hasComparison = comparisonContent != nil
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { width: 100%; height: 100%; overflow: hidden; }
                #container { width: 100%; height: 100%; }
                .monaco-editor { padding-top: 4px; }
            </style>
        </head>
        <body>
            <div id="container"></div>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.45.0/min/vs/loader.min.js"></script>
            <script>
                require.config({ paths: { vs: 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.45.0/min/vs' } });
                
                require(['vs/editor/editor.main'], function() {
                    const baseOptions = {
                        language: '\(language)',
                        theme: '\(theme.rawValue)',
                        readOnly: \(readOnly ? "true" : "false"),
                        automaticLayout: true,
                        minimap: { enabled: true },
                        fontSize: 13,
                        fontFamily: 'SF Mono, Menlo, Monaco, Courier New, monospace',
                        lineNumbers: 'on',
                        scrollBeyondLastLine: false,
                        wordWrap: 'on',
                        tabSize: 4,
                        insertSpaces: true,
                        renderWhitespace: 'selection',
                        smoothScrolling: true,
                        cursorBlinking: 'smooth',
                        cursorSmoothCaretAnimation: 'on',
                        padding: { top: 8, bottom: 8 }
                    };

                    window.isDiffMode = \(hasComparison ? "true" : "false");
                    
                    if (window.isDiffMode) {
                        const diffEditor = monaco.editor.createDiffEditor(document.getElementById('container'), {
                            ...baseOptions,
                            renderSideBySide: true,
                            enableSplitViewResizing: true,
                            readOnly: false
                        });
                        const originalModel = monaco.editor.createModel(`\(escapedComparison)`, '\(language)');
                        const modifiedModel = monaco.editor.createModel(`\(escapedCode)`, '\(language)');
                        diffEditor.setModel({ original: originalModel, modified: modifiedModel });
                        window.editor = diffEditor;
                        window.modifiedModel = modifiedModel;
                        window.originalModel = originalModel;
                        
                        window.modifiedModel.onDidChangeContent(function() {
                            const content = window.modifiedModel.getValue();
                            window.webkit.messageHandlers.monacoHandler.postMessage({
                                type: 'contentChange',
                                content: content
                            });
                        });
                    } else {
                        const editor = monaco.editor.create(document.getElementById('container'), {
                            ...baseOptions,
                            value: `\(escapedCode)`
                        });
                        window.editor = editor;
                        
                        // Send content changes to Swift
                        window.editor.onDidChangeModelContent(function() {
                            const content = window.editor.getValue();
                            window.webkit.messageHandlers.monacoHandler.postMessage({
                                type: 'contentChange',
                                content: content
                            });
                        });
                    }
                    
                    // Notify that editor is ready
                    window.webkit.messageHandlers.monacoHandler.postMessage({
                        type: 'ready'
                    });
                });
            </script>
        </body>
        </html>
        """
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: MonacoEditorRepresentable
        var webView: WKWebView?
        var lastKnownCode: String = ""
        var lastComparisonContent: String?
        var isEditorReady = false
        var pendingCode: String?
        var pendingComparison: String?
        var lastAppliedCode: String
        var lastAppliedComparison: String?
        
        init(_ parent: MonacoEditorRepresentable) {
            self.parent = parent
            self.lastKnownCode = parent.code
            self.lastComparisonContent = parent.comparisonContent
            self.lastAppliedCode = parent.code
            self.lastAppliedComparison = parent.comparisonContent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let dict = message.body as? [String: Any],
                  let type = dict["type"] as? String else { return }
            
            switch type {
            case "ready":
                isEditorReady = true
                applyPendingContentIfReady()
                
            case "contentChange":
                if let content = dict["content"] as? String {
                    lastKnownCode = content
                    lastAppliedCode = content
                    DispatchQueue.main.async {
                        self.parent.code = content
                        self.parent.onContentChange?(content)
                    }
                }
                
            default:
                break
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Editor loaded
        }
        
        func applyPendingContentIfReady() {
            guard isEditorReady, let webView else { return }
            let codeToApply = pendingCode ?? lastKnownCode
            let comparisonToApply = pendingComparison ?? parent.comparisonContent
            let shouldUpdateCode = pendingCode != nil && codeToApply != lastAppliedCode
            let shouldUpdateComparison: Bool
            if let comparisonToApply {
                shouldUpdateComparison = (lastAppliedComparison ?? "") != comparisonToApply
            } else {
                shouldUpdateComparison = false
            }
            guard shouldUpdateCode || shouldUpdateComparison else {
                pendingCode = nil
                pendingComparison = nil
                return
            }
            var jsSegments: [String] = ["if (window.editor && window.monaco) {"]
            if shouldUpdateCode {
                let escapedCode = codeToApply
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "`", with: "\\`")
                    .replacingOccurrences(of: "$", with: "\\$")
                if parent.comparisonContent != nil || windowIsDiffMode() {
                    jsSegments.append("    if (window.isDiffMode) { const models = window.editor.getModel(); if (models && models.modified) { models.modified.setValue(`\(escapedCode)`); } } else { window.editor.setValue(`\(escapedCode)`); }")
                } else {
                    jsSegments.append("    window.editor.setValue(`\(escapedCode)`);")
                }
            }
            if shouldUpdateComparison, let comparisonString = comparisonToApply {
                let escapedComparison = comparisonString
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "`", with: "\\`")
                    .replacingOccurrences(of: "$", with: "\\$")
                jsSegments.append("    if (window.isDiffMode) { const models = window.editor.getModel(); if (models && models.original) { models.original.setValue(`\(escapedComparison)`); } }")
            }
            jsSegments.append("}")
            let js = jsSegments.joined(separator: "\n")
            webView.evaluateJavaScript(js, completionHandler: nil)
            if shouldUpdateCode {
                lastAppliedCode = codeToApply
            }
            if shouldUpdateComparison, let comparisonToApply {
                lastAppliedComparison = comparisonToApply
            }
            pendingCode = nil
            pendingComparison = nil
        }
        
        private func windowIsDiffMode() -> Bool {
            // We can't query JS synchronously; rely on current parent comparison state
            return parent.comparisonContent != nil || lastComparisonContent != nil
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct MonacoEditorView_Previews: PreviewProvider {
    static var previews: some View {
        MonacoEditorView(
            code: .constant("func hello() {\n    print(\"Hello, World!\")\n}"),
            language: "swift",
            theme: .vsDark
        )
        .frame(height: 300)
    }
}
#endif
