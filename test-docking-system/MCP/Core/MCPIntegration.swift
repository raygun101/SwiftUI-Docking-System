import Foundation
import SwiftUI
import Combine

// MARK: - MCP Integration Manager

/// Main integration point for MCP system with the IDE
@MainActor
public final class MCPIntegration: ObservableObject {
    public static let shared = MCPIntegration()
    
    // Services
    public let toolRegistry = MCPToolRegistry.shared
    public let toolExecutor = MCPToolExecutor.shared
    public let agent = MCPAgent.shared
    public let chatService = ChatServiceManager.shared
    public let imageService = ImageServiceManager.shared
    public let audioService = AudioServiceManager.shared
    
    // State
    @Published public var isInitialized = false
    @Published public var projectContext: MCPAgent.ProjectContext?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Initialization
    
    /// Initialize the MCP system with all tools
    public func initialize() {
        guard !isInitialized else { return }
        
        print("[MCP] Initializing MCP system...")
        
        // Register all tools
        registerAllTools()
        
        isInitialized = true
        print("[MCP] MCP system initialized with \(toolRegistry.tools.count) tools")
    }
    
    /// Update project context for the agent
    public func updateProjectContext(
        rootURL: URL,
        openFiles: [URL] = [],
        activeFile: URL? = nil,
        selectedText: String? = nil
    ) {
        let context = MCPAgent.ProjectContext(
            rootURL: rootURL,
            openFiles: openFiles,
            activeFile: activeFile,
            selectedText: selectedText
        )
        self.projectContext = context
        agent.projectContext = context
    }
    
    // MARK: - Tool Registration
    
    private func registerAllTools() {
        // File tools
        registerToolIfNeeded(CreateFileTool())
        registerToolIfNeeded(ReadFileTool())
        registerToolIfNeeded(EditFileTool())
        registerToolIfNeeded(DeleteFileTool())
        registerToolIfNeeded(ListDirectoryTool())
        registerToolIfNeeded(SearchFilesTool())
        registerToolIfNeeded(CopyFileTool())
        registerToolIfNeeded(MoveFileTool())
        
        // Code/Web tools
        registerToolIfNeeded(CreateHTMLPageTool())
        registerToolIfNeeded(CreateCSSTool())
        registerToolIfNeeded(CreateJavaScriptTool())
        registerToolIfNeeded(ExecuteCommandTool())
        
        // AI tools (already registered in agent, but ensure they're in registry)
        registerToolIfNeeded(ImageGenerationTool())
        registerToolIfNeeded(TextToSpeechTool())
        registerToolIfNeeded(TranscriptionTool())
        
        // Project-specific tools
        registerProjectTools()
        
        // Helper/Utility tools
        registerUtilityTools()
    }
    
    private func registerProjectTools() {
        // Create Component Tool
        let createComponentTool = ToolBuilder()
            .id("create_component")
            .name("Create Web Component")
            .description("Create a reusable web component with HTML, CSS, and JavaScript")
            .category(.web)
            .icon("square.stack.3d.up")
            .parameter(name: "name", description: "Component name", type: .string)
            .parameter(name: "type", description: "Component type", type: .string, required: false, defaultValue: "card", options: ["card", "button", "modal", "navbar", "footer", "form", "hero"])
            .parameter(name: "description", description: "Component description", type: .string, required: false)
            .handler { invocation in
                let name = invocation.parameters["name"]?.stringValue ?? "Component"
                let type = invocation.parameters["type"]?.stringValue ?? "card"
                
                let html = self.generateComponentHTML(name: name, type: type)
                let css = self.generateComponentCSS(name: name, type: type)
                
                if let projectRoot = invocation.context.projectRoot {
                    let componentDir = projectRoot.appendingPathComponent("components/\(name.lowercased())")
                    try? FileManager.default.createDirectory(at: componentDir, withIntermediateDirectories: true)
                    
                    try? html.write(to: componentDir.appendingPathComponent("\(name.lowercased()).html"), atomically: true, encoding: .utf8)
                    try? css.write(to: componentDir.appendingPathComponent("\(name.lowercased()).css"), atomically: true, encoding: .utf8)
                    
                    return .success(.text("Created component '\(name)' in components/\(name.lowercased())/"))
                }
                
                return .success(.compound([
                    .code(html, language: "html"),
                    .code(css, language: "css")
                ]))
            }
            .build()
        
        toolRegistry.register(createComponentTool)
        
        // Build Website Tool
        let buildWebsiteTool = ToolBuilder()
            .id("build_website")
            .name("Build Complete Website")
            .description("Generate a complete website with multiple pages and assets")
            .category(.web)
            .icon("globe")
            .parameter(name: "name", description: "Website name", type: .string)
            .parameter(name: "description", description: "Website description", type: .string)
            .parameter(name: "pages", description: "Comma-separated page names", type: .string, required: false, defaultValue: "home,about,contact")
            .parameter(name: "style", description: "Design style", type: .string, required: false, defaultValue: "modern", options: ["modern", "minimal", "colorful", "corporate"])
            .handler { invocation in
                let name = invocation.parameters["name"]?.stringValue ?? "My Website"
                let description = invocation.parameters["description"]?.stringValue ?? ""
                let pagesStr = invocation.parameters["pages"]?.stringValue ?? "home,about,contact"
                let pages = pagesStr.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                
                var createdFiles: [String] = []
                
                if let projectRoot = invocation.context.projectRoot {
                    // Create directory structure
                    let dirs = ["css", "js", "images", "components"]
                    for dir in dirs {
                        try? FileManager.default.createDirectory(
                            at: projectRoot.appendingPathComponent(dir),
                            withIntermediateDirectories: true
                        )
                    }
                    
                    // Create main CSS
                    let mainCSS = self.generateMainCSS()
                    try? mainCSS.write(to: projectRoot.appendingPathComponent("css/style.css"), atomically: true, encoding: .utf8)
                    createdFiles.append("css/style.css")
                    
                    // Create main JS
                    let mainJS = self.generateMainJS()
                    try? mainJS.write(to: projectRoot.appendingPathComponent("js/main.js"), atomically: true, encoding: .utf8)
                    createdFiles.append("js/main.js")
                    
                    // Create pages
                    for page in pages {
                        let pageHTML = self.generatePageHTML(name: name, page: page, allPages: pages)
                        let filename = page == "home" ? "index.html" : "\(page).html"
                        try? pageHTML.write(to: projectRoot.appendingPathComponent(filename), atomically: true, encoding: .utf8)
                        createdFiles.append(filename)
                    }
                    
                    return .success(.text("Created website '\(name)' with files:\n" + createdFiles.map { "• \($0)" }.joined(separator: "\n")))
                }
                
                return .error(.executionFailed("No project root available"))
            }
            .build()
        
        toolRegistry.register(buildWebsiteTool)
        
        // Add Asset Tool
        let addAssetTool = ToolBuilder()
            .id("add_asset")
            .name("Add Asset")
            .description("Add an image or audio asset to the project")
            .category(.project)
            .icon("photo.badge.plus")
            .parameter(name: "type", description: "Asset type", type: .string, options: ["image", "audio"])
            .parameter(name: "prompt", description: "Description for AI generation", type: .string)
            .parameter(name: "filename", description: "Output filename", type: .string)
            .handler { invocation in
                let type = invocation.parameters["type"]?.stringValue ?? "image"
                let prompt = invocation.parameters["prompt"]?.stringValue ?? ""
                let filename = invocation.parameters["filename"]?.stringValue ?? "asset"
                
                if type == "image" {
                    let service = await ImageServiceManager.shared.service
                    let result = try await service.generateImage(prompt: prompt, options: .default)
                    
                    if let imageData = result.imageData, let projectRoot = invocation.context.projectRoot {
                        let imagesDir = projectRoot.appendingPathComponent("images")
                        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
                        
                        let fileURL = imagesDir.appendingPathComponent("\(filename).png")
                        try? imageData.write(to: fileURL)
                        
                        return .success(.compound([
                            .text("Generated and saved image: images/\(filename).png"),
                            .image(imageData, mimeType: "image/png")
                        ]))
                    }
                    
                    return .success(.image(result.imageData ?? Data(), mimeType: "image/png"))
                } else {
                    let service = await AudioServiceManager.shared.service
                    let result = try await service.generateSpeech(text: prompt, options: .default)
                    
                    if let projectRoot = invocation.context.projectRoot {
                        let audioDir = projectRoot.appendingPathComponent("audio")
                        try? FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)
                        
                        let fileURL = audioDir.appendingPathComponent("\(filename).mp3")
                        try? result.audioData.write(to: fileURL)
                        
                        return .success(.text("Generated and saved audio: audio/\(filename).mp3"))
                    }
                    
                    return .success(.audio(result.audioData, mimeType: "audio/mpeg"))
                }
            }
            .build()
        
        toolRegistry.register(addAssetTool)
    }
    
    private func registerUtilityTools() {
        // Format Code Tool
        let formatCodeTool = ToolBuilder()
            .id("format_code")
            .name("Format Code")
            .description("Format and beautify code")
            .category(.code)
            .icon("text.alignleft")
            .parameter(name: "code", description: "Code to format", type: .string)
            .parameter(name: "language", description: "Programming language", type: .string, options: ["html", "css", "javascript", "json", "swift"])
            .handler { invocation in
                let code = invocation.parameters["code"]?.stringValue ?? ""
                let language = invocation.parameters["language"]?.stringValue ?? "javascript"
                
                // Simple formatting (in production, use proper formatters)
                let formatted = code
                    .replacingOccurrences(of: "  ", with: "    ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                return .success(.code(formatted, language: language))
            }
            .build()
        
        toolRegistry.register(formatCodeTool)
        
        // Get Current Time Tool
        let timeTool = ToolBuilder()
            .id("get_time")
            .name("Get Current Time")
            .description("Get the current date and time")
            .category(.system)
            .icon("clock")
            .handler { _ in
                let formatter = DateFormatter()
                formatter.dateStyle = .full
                formatter.timeStyle = .medium
                return .success(.text(formatter.string(from: Date())))
            }
            .build()
        
        toolRegistry.register(timeTool)
        
        // Calculate Tool
        let calcTool = ToolBuilder()
            .id("calculate")
            .name("Calculate")
            .description("Perform mathematical calculations")
            .category(.system)
            .icon("function")
            .parameter(name: "expression", description: "Mathematical expression", type: .string)
            .handler { invocation in
                let expression = invocation.parameters["expression"]?.stringValue ?? ""
                
                let expr = NSExpression(format: expression)
                if let result = expr.expressionValue(with: nil, context: nil) as? NSNumber {
                    return .success(.text("\(expression) = \(result)"))
                }
                
                return .error(.executionFailed("Could not evaluate expression"))
            }
            .build()
        
        registerToolIfNeeded(calcTool)
    }

    private func registerToolIfNeeded(_ tool: some MCPTool) {
        let id = tool.definition.id
        guard toolRegistry.tool(for: id) == nil else {
            MCPLog.integration.debug("Skipping duplicate tool registration for id \(id)")
            return
        }
        toolRegistry.register(tool)
    }
    
    // MARK: - Code Generation Helpers
    
    private func generateComponentHTML(name: String, type: String) -> String {
        switch type {
        case "card":
            return """
            <!-- \(name) Component -->
            <div class="\(name.lowercased())-card">
                <div class="\(name.lowercased())-card__image">
                    <img src="" alt="\(name)">
                </div>
                <div class="\(name.lowercased())-card__content">
                    <h3 class="\(name.lowercased())-card__title">Title</h3>
                    <p class="\(name.lowercased())-card__description">Description goes here.</p>
                    <button class="\(name.lowercased())-card__button">Learn More</button>
                </div>
            </div>
            """
        case "button":
            return """
            <!-- \(name) Button Component -->
            <button class="\(name.lowercased())-btn">
                <span class="\(name.lowercased())-btn__text">Click Me</span>
                <span class="\(name.lowercased())-btn__icon">→</span>
            </button>
            """
        case "modal":
            return """
            <!-- \(name) Modal Component -->
            <div class="\(name.lowercased())-modal" id="\(name.lowercased())Modal">
                <div class="\(name.lowercased())-modal__overlay"></div>
                <div class="\(name.lowercased())-modal__content">
                    <button class="\(name.lowercased())-modal__close">&times;</button>
                    <h2 class="\(name.lowercased())-modal__title">Modal Title</h2>
                    <div class="\(name.lowercased())-modal__body">
                        <p>Modal content goes here.</p>
                    </div>
                    <div class="\(name.lowercased())-modal__footer">
                        <button class="btn btn-secondary">Cancel</button>
                        <button class="btn btn-primary">Confirm</button>
                    </div>
                </div>
            </div>
            """
        default:
            return "<!-- \(name) Component -->\n<div class=\"\(name.lowercased())\">\n    <!-- Content -->\n</div>"
        }
    }
    
    private func generateComponentCSS(name: String, type: String) -> String {
        let base = name.lowercased()
        switch type {
        case "card":
            return """
            .\(base)-card {
                background: var(--surface, #1e293b);
                border-radius: 16px;
                overflow: hidden;
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
                transition: transform 0.3s, box-shadow 0.3s;
            }
            
            .\(base)-card:hover {
                transform: translateY(-4px);
                box-shadow: 0 8px 30px rgba(0, 0, 0, 0.3);
            }
            
            .\(base)-card__image img {
                width: 100%;
                height: 200px;
                object-fit: cover;
            }
            
            .\(base)-card__content {
                padding: 24px;
            }
            
            .\(base)-card__title {
                font-size: 1.25rem;
                font-weight: 600;
                margin-bottom: 8px;
            }
            
            .\(base)-card__description {
                color: var(--text-muted, #94a3b8);
                margin-bottom: 16px;
            }
            
            .\(base)-card__button {
                background: var(--primary, #6366f1);
                color: white;
                border: none;
                padding: 10px 20px;
                border-radius: 8px;
                cursor: pointer;
                font-weight: 500;
                transition: background 0.3s;
            }
            
            .\(base)-card__button:hover {
                background: var(--primary-dark, #4f46e5);
            }
            """
        default:
            return "/* \(name) Component Styles */\n.\(base) {\n    /* Add styles */\n}"
        }
    }
    
    private func generateMainCSS() -> String {
        return """
        /* Main Stylesheet */
        :root {
            --primary: #6366f1;
            --primary-dark: #4f46e5;
            --secondary: #ec4899;
            --background: #0f172a;
            --surface: #1e293b;
            --text: #f8fafc;
            --text-muted: #94a3b8;
            --border: #334155;
        }
        
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: var(--background);
            color: var(--text);
            line-height: 1.6;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 24px;
        }
        
        /* Utility Classes */
        .text-center { text-align: center; }
        .mt-1 { margin-top: 8px; }
        .mt-2 { margin-top: 16px; }
        .mt-3 { margin-top: 24px; }
        .mt-4 { margin-top: 32px; }
        """
    }
    
    private func generateMainJS() -> String {
        return """
        // Main JavaScript
        document.addEventListener('DOMContentLoaded', () => {
            console.log('Website loaded');
            initNavigation();
            initAnimations();
        });
        
        function initNavigation() {
            document.querySelectorAll('a[href^="#"]').forEach(anchor => {
                anchor.addEventListener('click', function(e) {
                    e.preventDefault();
                    const target = document.querySelector(this.getAttribute('href'));
                    if (target) {
                        target.scrollIntoView({ behavior: 'smooth' });
                    }
                });
            });
        }
        
        function initAnimations() {
            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        entry.target.classList.add('visible');
                    }
                });
            }, { threshold: 0.1 });
            
            document.querySelectorAll('.animate').forEach(el => observer.observe(el));
        }
        """
    }
    
    private func generatePageHTML(name: String, page: String, allPages: [String]) -> String {
        let nav = allPages.map { p -> String in
            let href = p == "home" ? "index.html" : "\(p).html"
            let active = p == page ? " class=\"active\"" : ""
            return "<a href=\"\(href)\"\(active)>\(p.capitalized)</a>"
        }.joined(separator: "\n                ")
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(page.capitalized) - \(name)</title>
            <link rel="stylesheet" href="css/style.css">
        </head>
        <body>
            <header>
                <nav class="container">
                    <div class="logo">\(name)</div>
                    <div class="nav-links">
                        \(nav)
                    </div>
                </nav>
            </header>
            
            <main>
                <section class="hero">
                    <div class="container">
                        <h1>\(page.capitalized)</h1>
                        <p>Welcome to the \(page) page.</p>
                    </div>
                </section>
            </main>
            
            <footer>
                <div class="container">
                    <p>&copy; 2024 \(name). All rights reserved.</p>
                </div>
            </footer>
            
            <script src="js/main.js"></script>
        </body>
        </html>
        """
    }
    
    // Notification handling is centralized in AgentIDEBridge
}

// MARK: - MCP Export (All-in-one import)

@MainActor
public struct MCP {
    public static let integration = MCPIntegration.shared
    public static let agent = MCPAgent.shared
    public static let tools = MCPToolRegistry.shared
    public static let executor = MCPToolExecutor.shared
    public static let chat = ChatServiceManager.shared
    public static let images = ImageServiceManager.shared
    public static let audio = AudioServiceManager.shared
    
    public static func initialize() {
        integration.initialize()
    }
    
    public static func setProjectContext(rootURL: URL, openFiles: [URL] = [], activeFile: URL? = nil) {
        integration.updateProjectContext(rootURL: rootURL, openFiles: openFiles, activeFile: activeFile)
    }
}
