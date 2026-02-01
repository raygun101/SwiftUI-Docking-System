import Foundation

// MARK: - Code Generation Tools

/// Tool for generating HTML pages
public struct CreateHTMLPageTool: MCPTool {
    public let definition = ToolDefinition(
        id: "create_html_page",
        name: "Create HTML Page",
        description: "Generate a complete HTML page with modern structure and styling",
        category: .web,
        parameters: [
            ToolParameter(name: "title", description: "Page title", type: .string),
            ToolParameter(name: "description", description: "Description of the page content", type: .string),
            ToolParameter(name: "template", description: "Template type", type: .string, required: false, defaultValue: "landing", options: ["landing", "portfolio", "blog", "dashboard", "minimal"]),
            ToolParameter(name: "filename", description: "Output filename", type: .string, required: false, defaultValue: "index.html"),
            ToolParameter(name: "include_css", description: "Include inline CSS", type: .boolean, required: false, defaultValue: "true")
        ],
        icon: "doc.text"
    )
    
    public init() {}
    
    public func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        let title = invocation.parameters["title"]?.stringValue ?? "My Website"
        let description = invocation.parameters["description"]?.stringValue ?? ""
        let template = invocation.parameters["template"]?.stringValue ?? "landing"
        let filename = invocation.parameters["filename"]?.stringValue ?? "index.html"
        let includeCSS = invocation.parameters["include_css"]?.boolValue ?? true
        
        let html = generateHTML(title: title, description: description, template: template, includeCSS: includeCSS)
        
        // Save the file if project root is available
        if let projectRoot = invocation.context.projectRoot {
            let fileURL = projectRoot.appendingPathComponent(filename)
            try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? html.write(to: fileURL, atomically: true, encoding: .utf8)
            return .success(.compound([
                .text("Created HTML page: \(filename)"),
                .code(html, language: "html")
            ]))
        }
        
        return .success(.code(html, language: "html"))
    }
    
    private func generateHTML(title: String, description: String, template: String, includeCSS: Bool) -> String {
        let css = includeCSS ? generateCSS(for: template) : ""
        let body = generateBody(for: template, title: title, description: description)
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(title)</title>
            <meta name="description" content="\(description)">
            \(includeCSS ? "<style>\n\(css)\n    </style>" : "")
            <link rel="preconnect" href="https://fonts.googleapis.com">
            <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }
    
    private func generateCSS(for template: String) -> String {
        return """
                :root {
                    --primary: #6366f1;
                    --primary-dark: #4f46e5;
                    --secondary: #ec4899;
                    --background: #0f172a;
                    --surface: #1e293b;
                    --text: #f8fafc;
                    --text-muted: #94a3b8;
                    --border: #334155;
                    --gradient: linear-gradient(135deg, var(--primary), var(--secondary));
                }
                
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
                    background: var(--background);
                    color: var(--text);
                    line-height: 1.6;
                    min-height: 100vh;
                }
                
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    padding: 0 24px;
                }
                
                /* Header Styles */
                header {
                    position: fixed;
                    top: 0;
                    left: 0;
                    right: 0;
                    padding: 20px 0;
                    background: rgba(15, 23, 42, 0.8);
                    backdrop-filter: blur(10px);
                    border-bottom: 1px solid var(--border);
                    z-index: 100;
                }
                
                nav {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                }
                
                .logo {
                    font-size: 1.5rem;
                    font-weight: 700;
                    background: var(--gradient);
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                }
                
                .nav-links {
                    display: flex;
                    gap: 32px;
                    list-style: none;
                }
                
                .nav-links a {
                    color: var(--text-muted);
                    text-decoration: none;
                    font-weight: 500;
                    transition: color 0.3s;
                }
                
                .nav-links a:hover {
                    color: var(--text);
                }
                
                /* Hero Section */
                .hero {
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    text-align: center;
                    padding: 120px 24px;
                    position: relative;
                    overflow: hidden;
                }
                
                .hero::before {
                    content: '';
                    position: absolute;
                    top: 0;
                    left: 50%;
                    transform: translateX(-50%);
                    width: 800px;
                    height: 800px;
                    background: radial-gradient(circle, rgba(99, 102, 241, 0.15), transparent 70%);
                    pointer-events: none;
                }
                
                .hero-content {
                    position: relative;
                    z-index: 1;
                }
                
                .hero h1 {
                    font-size: clamp(2.5rem, 8vw, 5rem);
                    font-weight: 700;
                    margin-bottom: 24px;
                    line-height: 1.1;
                }
                
                .hero h1 span {
                    background: var(--gradient);
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                }
                
                .hero p {
                    font-size: 1.25rem;
                    color: var(--text-muted);
                    max-width: 600px;
                    margin: 0 auto 40px;
                }
                
                /* Buttons */
                .btn {
                    display: inline-flex;
                    align-items: center;
                    gap: 8px;
                    padding: 16px 32px;
                    border-radius: 12px;
                    font-weight: 600;
                    text-decoration: none;
                    transition: all 0.3s;
                    cursor: pointer;
                    border: none;
                    font-size: 1rem;
                }
                
                .btn-primary {
                    background: var(--gradient);
                    color: white;
                    box-shadow: 0 4px 20px rgba(99, 102, 241, 0.4);
                }
                
                .btn-primary:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 6px 30px rgba(99, 102, 241, 0.5);
                }
                
                .btn-secondary {
                    background: var(--surface);
                    color: var(--text);
                    border: 1px solid var(--border);
                }
                
                .btn-secondary:hover {
                    background: var(--border);
                }
                
                /* Features Section */
                .features {
                    padding: 120px 24px;
                    background: var(--surface);
                }
                
                .section-title {
                    text-align: center;
                    margin-bottom: 64px;
                }
                
                .section-title h2 {
                    font-size: 2.5rem;
                    margin-bottom: 16px;
                }
                
                .section-title p {
                    color: var(--text-muted);
                    max-width: 500px;
                    margin: 0 auto;
                }
                
                .features-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                    gap: 32px;
                }
                
                .feature-card {
                    background: var(--background);
                    border: 1px solid var(--border);
                    border-radius: 16px;
                    padding: 32px;
                    transition: transform 0.3s, box-shadow 0.3s;
                }
                
                .feature-card:hover {
                    transform: translateY(-4px);
                    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
                }
                
                .feature-icon {
                    width: 56px;
                    height: 56px;
                    background: var(--gradient);
                    border-radius: 12px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    margin-bottom: 20px;
                    font-size: 1.5rem;
                }
                
                .feature-card h3 {
                    font-size: 1.25rem;
                    margin-bottom: 12px;
                }
                
                .feature-card p {
                    color: var(--text-muted);
                }
                
                /* Footer */
                footer {
                    padding: 60px 24px;
                    border-top: 1px solid var(--border);
                    text-align: center;
                    color: var(--text-muted);
                }
                
                /* Animations */
                @keyframes fadeInUp {
                    from {
                        opacity: 0;
                        transform: translateY(30px);
                    }
                    to {
                        opacity: 1;
                        transform: translateY(0);
                    }
                }
                
                .animate-in {
                    animation: fadeInUp 0.8s ease-out forwards;
                }
        """
    }
    
    private func generateBody(for template: String, title: String, description: String) -> String {
        return """
            <header>
                <nav class="container">
                    <div class="logo">\(title)</div>
                    <ul class="nav-links">
                        <li><a href="#features">Features</a></li>
                        <li><a href="#about">About</a></li>
                        <li><a href="#contact">Contact</a></li>
                    </ul>
                </nav>
            </header>
        
            <main>
                <section class="hero">
                    <div class="hero-content animate-in">
                        <h1>Build Something <span>Amazing</span></h1>
                        <p>\(description.isEmpty ? "Create beautiful, modern web experiences with cutting-edge design and seamless interactions." : description)</p>
                        <div style="display: flex; gap: 16px; justify-content: center;">
                            <a href="#" class="btn btn-primary">Get Started</a>
                            <a href="#" class="btn btn-secondary">Learn More</a>
                        </div>
                    </div>
                </section>
        
                <section class="features" id="features">
                    <div class="container">
                        <div class="section-title">
                            <h2>Features</h2>
                            <p>Everything you need to build modern web applications</p>
                        </div>
                        <div class="features-grid">
                            <div class="feature-card">
                                <div class="feature-icon">⚡</div>
                                <h3>Lightning Fast</h3>
                                <p>Optimized for performance with modern best practices and efficient code.</p>
                            </div>
                            <div class="feature-card">
                                <div class="feature-icon">🎨</div>
                                <h3>Beautiful Design</h3>
                                <p>Stunning visuals with carefully crafted UI components and animations.</p>
                            </div>
                            <div class="feature-card">
                                <div class="feature-icon">📱</div>
                                <h3>Fully Responsive</h3>
                                <p>Perfect experience on every device, from mobile to desktop.</p>
                            </div>
                        </div>
                    </div>
                </section>
            </main>
        
            <footer>
                <div class="container">
                    <p>&copy; 2024 \(title). All rights reserved.</p>
                </div>
            </footer>
        """
    }
}

/// Tool for generating CSS stylesheets
public struct CreateCSSTool: MCPTool {
    public let definition = ToolDefinition(
        id: "create_css",
        name: "Create CSS",
        description: "Generate a CSS stylesheet with modern styles",
        category: .web,
        parameters: [
            ToolParameter(name: "description", description: "Description of styles needed", type: .string),
            ToolParameter(name: "style", description: "Style preset", type: .string, required: false, defaultValue: "modern", options: ["modern", "minimal", "colorful", "dark", "light"]),
            ToolParameter(name: "filename", description: "Output filename", type: .string, required: false, defaultValue: "styles.css")
        ],
        icon: "paintbrush"
    )
    
    public init() {}
    
    public func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        let description = invocation.parameters["description"]?.stringValue ?? ""
        let style = invocation.parameters["style"]?.stringValue ?? "modern"
        let filename = invocation.parameters["filename"]?.stringValue ?? "styles.css"
        
        let css = generateCSS(description: description, style: style)
        
        if let projectRoot = invocation.context.projectRoot {
            let fileURL = projectRoot.appendingPathComponent(filename)
            try? css.write(to: fileURL, atomically: true, encoding: .utf8)
            return .success(.compound([
                .text("Created CSS file: \(filename)"),
                .code(css, language: "css")
            ]))
        }
        
        return .success(.code(css, language: "css"))
    }
    
    private func generateCSS(description: String, style: String) -> String {
        let colors: (primary: String, secondary: String, bg: String, text: String)
        
        switch style {
        case "minimal":
            colors = ("#000000", "#666666", "#ffffff", "#000000")
        case "colorful":
            colors = ("#ff6b6b", "#4ecdc4", "#f7f7f7", "#2d3436")
        case "dark":
            colors = ("#6366f1", "#ec4899", "#0f172a", "#f8fafc")
        case "light":
            colors = ("#3b82f6", "#8b5cf6", "#ffffff", "#1f2937")
        default: // modern
            colors = ("#6366f1", "#ec4899", "#0f172a", "#f8fafc")
        }
        
        return """
        /* Generated CSS - \(style) style */
        /* \(description) */
        
        :root {
            --primary: \(colors.primary);
            --secondary: \(colors.secondary);
            --background: \(colors.bg);
            --text: \(colors.text);
            --spacing-sm: 8px;
            --spacing-md: 16px;
            --spacing-lg: 32px;
            --spacing-xl: 64px;
            --radius-sm: 4px;
            --radius-md: 8px;
            --radius-lg: 16px;
            --shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
            --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
            --transition: all 0.3s ease;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: var(--background);
            color: var(--text);
            line-height: 1.6;
        }
        
        /* Container */
        .container {
            width: 100%;
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 var(--spacing-md);
        }
        
        /* Typography */
        h1, h2, h3, h4, h5, h6 {
            font-weight: 700;
            line-height: 1.2;
            margin-bottom: var(--spacing-md);
        }
        
        h1 { font-size: 3rem; }
        h2 { font-size: 2.25rem; }
        h3 { font-size: 1.5rem; }
        
        p {
            margin-bottom: var(--spacing-md);
        }
        
        a {
            color: var(--primary);
            text-decoration: none;
            transition: var(--transition);
        }
        
        a:hover {
            opacity: 0.8;
        }
        
        /* Buttons */
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: var(--spacing-sm) var(--spacing-md);
            border-radius: var(--radius-md);
            font-weight: 600;
            cursor: pointer;
            transition: var(--transition);
            border: none;
        }
        
        .btn-primary {
            background: var(--primary);
            color: white;
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-lg);
        }
        
        /* Cards */
        .card {
            background: white;
            border-radius: var(--radius-lg);
            padding: var(--spacing-lg);
            box-shadow: var(--shadow);
            transition: var(--transition);
        }
        
        .card:hover {
            transform: translateY(-4px);
            box-shadow: var(--shadow-lg);
        }
        
        /* Grid */
        .grid {
            display: grid;
            gap: var(--spacing-lg);
        }
        
        .grid-2 { grid-template-columns: repeat(2, 1fr); }
        .grid-3 { grid-template-columns: repeat(3, 1fr); }
        .grid-4 { grid-template-columns: repeat(4, 1fr); }
        
        @media (max-width: 768px) {
            .grid-2, .grid-3, .grid-4 {
                grid-template-columns: 1fr;
            }
        }
        
        /* Flexbox utilities */
        .flex { display: flex; }
        .flex-center { align-items: center; justify-content: center; }
        .flex-between { justify-content: space-between; }
        .flex-col { flex-direction: column; }
        .gap-sm { gap: var(--spacing-sm); }
        .gap-md { gap: var(--spacing-md); }
        .gap-lg { gap: var(--spacing-lg); }
        
        /* Spacing utilities */
        .p-sm { padding: var(--spacing-sm); }
        .p-md { padding: var(--spacing-md); }
        .p-lg { padding: var(--spacing-lg); }
        .m-sm { margin: var(--spacing-sm); }
        .m-md { margin: var(--spacing-md); }
        .m-lg { margin: var(--spacing-lg); }
        
        /* Animations */
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        @keyframes slideUp {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .animate-fade { animation: fadeIn 0.5s ease-out; }
        .animate-slide { animation: slideUp 0.5s ease-out; }
        """
    }
}

/// Tool for generating JavaScript code
public struct CreateJavaScriptTool: MCPTool {
    public let definition = ToolDefinition(
        id: "create_javascript",
        name: "Create JavaScript",
        description: "Generate JavaScript code for web functionality",
        category: .web,
        parameters: [
            ToolParameter(name: "description", description: "Description of functionality needed", type: .string),
            ToolParameter(name: "type", description: "Type of JS", type: .string, required: false, defaultValue: "vanilla", options: ["vanilla", "module", "class"]),
            ToolParameter(name: "filename", description: "Output filename", type: .string, required: false, defaultValue: "script.js")
        ],
        icon: "curlybraces"
    )
    
    public init() {}
    
    public func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        let description = invocation.parameters["description"]?.stringValue ?? "Interactive web functionality"
        let type = invocation.parameters["type"]?.stringValue ?? "vanilla"
        let filename = invocation.parameters["filename"]?.stringValue ?? "script.js"
        
        let js = generateJavaScript(description: description, type: type)
        
        if let projectRoot = invocation.context.projectRoot {
            let fileURL = projectRoot.appendingPathComponent(filename)
            try? js.write(to: fileURL, atomically: true, encoding: .utf8)
            return .success(.compound([
                .text("Created JavaScript file: \(filename)"),
                .code(js, language: "javascript")
            ]))
        }
        
        return .success(.code(js, language: "javascript"))
    }
    
    private func generateJavaScript(description: String, type: String) -> String {
        switch type {
        case "module":
            return """
            // \(description)
            // ES6 Module
            
            /**
             * Initialize the application
             */
            export function init() {
                console.log('Application initialized');
                setupEventListeners();
                loadInitialData();
            }
            
            /**
             * Setup event listeners
             */
            function setupEventListeners() {
                // Document ready
                document.addEventListener('DOMContentLoaded', () => {
                    console.log('DOM loaded');
                });
                
                // Click handlers
                document.querySelectorAll('[data-action]').forEach(el => {
                    el.addEventListener('click', handleAction);
                });
                
                // Form submissions
                document.querySelectorAll('form').forEach(form => {
                    form.addEventListener('submit', handleFormSubmit);
                });
            }
            
            /**
             * Handle action clicks
             */
            function handleAction(e) {
                const action = e.target.dataset.action;
                console.log('Action triggered:', action);
            }
            
            /**
             * Handle form submissions
             */
            async function handleFormSubmit(e) {
                e.preventDefault();
                const formData = new FormData(e.target);
                console.log('Form submitted:', Object.fromEntries(formData));
            }
            
            /**
             * Load initial data
             */
            async function loadInitialData() {
                try {
                    // const response = await fetch('/api/data');
                    // const data = await response.json();
                    console.log('Data loaded');
                } catch (error) {
                    console.error('Failed to load data:', error);
                }
            }
            
            /**
             * Utility: Debounce function
             */
            export function debounce(func, wait) {
                let timeout;
                return function executedFunction(...args) {
                    clearTimeout(timeout);
                    timeout = setTimeout(() => func.apply(this, args), wait);
                };
            }
            
            /**
             * Utility: Format date
             */
            export function formatDate(date) {
                return new Intl.DateTimeFormat('en-US', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                }).format(new Date(date));
            }
            
            // Auto-initialize
            init();
            """
            
        case "class":
            return """
            // \(description)
            // Class-based JavaScript
            
            class App {
                constructor() {
                    this.state = {
                        initialized: false,
                        data: []
                    };
                    this.init();
                }
                
                init() {
                    console.log('App initializing...');
                    this.setupEventListeners();
                    this.state.initialized = true;
                    console.log('App initialized');
                }
                
                setupEventListeners() {
                    document.addEventListener('DOMContentLoaded', () => this.onReady());
                    
                    // Delegate click events
                    document.addEventListener('click', (e) => {
                        if (e.target.matches('[data-action]')) {
                            this.handleAction(e.target.dataset.action, e);
                        }
                    });
                }
                
                onReady() {
                    console.log('DOM ready');
                    this.render();
                }
                
                handleAction(action, event) {
                    console.log('Action:', action);
                    
                    switch(action) {
                        case 'toggle':
                            this.toggle(event.target);
                            break;
                        case 'submit':
                            this.submit();
                            break;
                        default:
                            console.log('Unknown action:', action);
                    }
                }
                
                toggle(element) {
                    element.classList.toggle('active');
                }
                
                async submit() {
                    console.log('Submitting...');
                }
                
                render() {
                    console.log('Rendering with state:', this.state);
                }
                
                setState(newState) {
                    this.state = { ...this.state, ...newState };
                    this.render();
                }
            }
            
            // Initialize app
            const app = new App();
            """
            
        default: // vanilla
            return """
            // \(description)
            // Vanilla JavaScript
            
            (function() {
                'use strict';
                
                // Wait for DOM
                document.addEventListener('DOMContentLoaded', init);
                
                function init() {
                    console.log('Page loaded');
                    setupNavigation();
                    setupAnimations();
                    setupForms();
                }
                
                // Smooth scroll navigation
                function setupNavigation() {
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
                
                // Scroll animations
                function setupAnimations() {
                    const observer = new IntersectionObserver((entries) => {
                        entries.forEach(entry => {
                            if (entry.isIntersecting) {
                                entry.target.classList.add('animate-in');
                            }
                        });
                    }, { threshold: 0.1 });
                    
                    document.querySelectorAll('.animate-on-scroll').forEach(el => {
                        observer.observe(el);
                    });
                }
                
                // Form handling
                function setupForms() {
                    document.querySelectorAll('form').forEach(form => {
                        form.addEventListener('submit', async function(e) {
                            e.preventDefault();
                            
                            const button = this.querySelector('button[type="submit"]');
                            const originalText = button.textContent;
                            button.textContent = 'Sending...';
                            button.disabled = true;
                            
                            try {
                                const formData = new FormData(this);
                                console.log('Form data:', Object.fromEntries(formData));
                                
                                // Simulate API call
                                await new Promise(resolve => setTimeout(resolve, 1000));
                                
                                showNotification('Success!', 'success');
                                this.reset();
                            } catch (error) {
                                showNotification('Error: ' + error.message, 'error');
                            } finally {
                                button.textContent = originalText;
                                button.disabled = false;
                            }
                        });
                    });
                }
                
                // Notification helper
                function showNotification(message, type = 'info') {
                    const notification = document.createElement('div');
                    notification.className = `notification notification-${type}`;
                    notification.textContent = message;
                    document.body.appendChild(notification);
                    
                    setTimeout(() => {
                        notification.classList.add('fade-out');
                        setTimeout(() => notification.remove(), 300);
                    }, 3000);
                }
                
                // Expose to global if needed
                window.App = {
                    showNotification
                };
            })();
            """
        }
    }
}

/// Tool for running shell commands
public struct ExecuteCommandTool: MCPTool {
    public let definition = ToolDefinition(
        id: "execute_command",
        name: "Execute Command",
        description: "Execute a shell command in the project directory",
        category: .system,
        parameters: [
            ToolParameter(name: "command", description: "Command to execute", type: .string),
            ToolParameter(name: "cwd", description: "Working directory", type: .string, required: false)
        ],
        icon: "terminal"
    )
    
    public init() {}
    
    public func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        guard let command = invocation.parameters["command"]?.stringValue else {
            return .error(.missingParameter("command"))
        }
        
        // On iOS, shell commands are not supported
        // Return a simulated response or guidance
        #if os(iOS)
        return .success(.text("""
            [iOS Environment] Shell command execution is not available on iOS.
            
            Command requested: \(command)
            
            Alternative: Use the file tools to create/modify files directly, or use the code generation tools.
            """))
        #else
        let cwd = invocation.parameters["cwd"]?.stringValue ?? invocation.context.projectRoot?.path ?? FileManager.default.currentDirectoryPath
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.currentDirectoryURL = URL(fileURLWithPath: cwd)
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""
            
            if process.terminationStatus == 0 {
                return .success(.text(output.isEmpty ? "Command completed successfully" : output))
            } else {
                return .error(ToolError(
                    code: "COMMAND_FAILED",
                    message: "Command exited with code \(process.terminationStatus)",
                    details: error.isEmpty ? output : error
                ))
            }
        } catch {
            return .error(.executionFailed("Failed to execute command: \(error.localizedDescription)"))
        }
        #endif
    }
}
