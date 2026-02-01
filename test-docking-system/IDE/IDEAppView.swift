import SwiftUI

// MARK: - IDE App View

/// The complete IDE application view with project management and multi-layout workspaces
public struct IDEAppView: View {
    @StateObject private var ideState = IDEState.shared
    @StateObject private var dockState: DockState
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var isInitialized = false
    @State private var showingNewFileSheet = false
    @State private var showingNewFolderSheet = false
    @State private var showingMCPSettings = false
    @State private var showingAgentPanel = false
    
    public init() {
        _dockState = StateObject(wrappedValue: DockState(layout: IDEAppView.createInitialLayout()))
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // IDE toolbar
                ideToolbar
                
                // Main dock container
                DockingSystem(state: dockState, theme: themeManager.currentTheme)
                    .environmentObject(ideState)
            }
            .ignoresSafeArea(.all, edges: .bottom)
            
            // Workspace switcher overlay (bottom right - preserved from original)
            workspaceSwitcherOverlay
            
            // Loading overlay
            if ideState.isLoading {
                loadingOverlay
            }
        }
        .sheet(isPresented: $showingMCPSettings) {
            MCPSettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .presentMCPSettings)) { _ in
            showingMCPSettings = true
        }
        .onAppear {
            ideState.attachDockState(dockState)
            if !isInitialized {
                initializeIDE()
            }
        }
    }
    
    // MARK: - IDE Toolbar
    
    private var ideToolbar: some View {
        let theme = themeManager.currentTheme
        
        return HStack(spacing: 16) {
            // App title with project name
            HStack(spacing: 8) {
                Image(systemName: "hammer.fill")
                    .foregroundColor(theme.colors.accent)
                
                if let project = ideState.workspaceManager.project {
                    Text(project.name)
                        .font(theme.typography.headerFont.weight(.bold))
                        .foregroundColor(theme.colors.text)
                } else {
                    Text("Mobile IDE")
                        .font(theme.typography.headerFont.weight(.bold))
                        .foregroundColor(theme.colors.text)
                }
            }
            
            Divider()
                .frame(height: 20)
                .overlay(theme.colors.separator)
            
            // Theme picker
            themePicker
            
            // Layout presets menu
            layoutPresetsMenu
            
            Spacer()
            
            // File operations
            if ideState.isProjectLoaded {
                fileOperationsMenu
                
                Divider()
                    .frame(height: 20)
                    .overlay(theme.colors.separator)
            }
            
            // Panel toggles
            panelToggles
            
            Divider()
                .frame(height: 20)
                .overlay(theme.colors.separator)
            
            // AI Agent button
            agentButton
            
            // Settings button
            settingsButton
            
            Divider()
                .frame(height: 20)
                .overlay(theme.colors.separator)
            
            // Add panel menu
            addPanelMenu
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(theme.colors.headerBackground)
    }
    
    // MARK: - Workspace Switcher Overlay
    
    private var workspaceSwitcherOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                WorkspaceSwitcherBar(
                    workspaces: ideState.workspaceManager.workspaces,
                    activeIndex: $ideState.workspaceManager.activeWorkspaceIndex,
                    onLayoutChange: { layoutType in
                        applyWorkspaceLayout(layoutType)
                    }
                )
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        let theme = themeManager.currentTheme
        
        return ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(ideState.statusMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.colors.panelBackground)
            )
        }
    }
    
    // MARK: - Toolbar Components
    
    private var themePicker: some View {
        let theme = themeManager.currentTheme
        
        return Menu {
            Button("Default Theme") { themeManager.applyDefaultTheme() }
            Divider()
            ForEach(ThemePresets.ThemeCategory.allCases, id: \.self) { category in
                let themes = themeManager.availableThemes.filter { $0.category == category }
                if !themes.isEmpty {
                    Section(category.displayName) {
                        ForEach(themes, id: \.name) { themeInfo in
                            Button(action: { themeManager.applyTheme(named: themeInfo.name) }) {
                                HStack {
                                    Text(themeInfo.displayName)
                                    if themeManager.selectedThemeMetadata?.name == themeInfo.name {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "paintbrush")
                Text(themeManager.selectedThemeMetadata?.displayName ?? "Theme")
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(theme.colors.tertiaryBackground)
            .cornerRadius(6)
            .foregroundColor(theme.colors.text)
        }
        .buttonStyle(.plain)
    }
    
    private var layoutPresetsMenu: some View {
        let theme = themeManager.currentTheme
        
        return Menu {
            Button("Code Layout") { applyWorkspaceLayout(.coding) }
            Button("Preview Layout") { applyWorkspaceLayout(.preview) }
            Button("Debug Layout") { applyWorkspaceLayout(.debug) }
            Button("Design Layout") { applyWorkspaceLayout(.design) }
            Divider()
            Button("Reset Layout") { resetLayout() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "rectangle.3.group")
                Text("Layouts")
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(theme.colors.tertiaryBackground)
            .cornerRadius(6)
            .foregroundColor(theme.colors.text)
        }
        .buttonStyle(.plain)
    }
    
    private var fileOperationsMenu: some View {
        let theme = themeManager.currentTheme
        
        return Menu {
            Button(action: { Task { await ideState.saveCurrentDocument() } }) {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            Button(action: { Task { await ideState.saveAllDocuments() } }) {
                Label("Save All", systemImage: "square.and.arrow.down.on.square")
            }
            Divider()
            Button(action: { Task { await ideState.refreshProject() } }) {
                Label("Refresh Project", systemImage: "arrow.clockwise")
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "doc")
                Text("File")
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(theme.colors.tertiaryBackground)
            .cornerRadius(6)
            .foregroundColor(theme.colors.text)
        }
        .buttonStyle(.plain)
    }
    
    private var panelToggles: some View {
        HStack(spacing: 8) {
            PanelToggleButton(
                icon: "sidebar.left",
                isActive: !dockState.layout.isLeftCollapsed,
                action: { dockState.layout.toggleCollapse(for: .left) }
            )
            
            PanelToggleButton(
                icon: "sidebar.right",
                isActive: !dockState.layout.isRightCollapsed,
                action: { dockState.layout.toggleCollapse(for: .right) }
            )
            
            PanelToggleButton(
                icon: "rectangle.bottomthird.inset.filled",
                isActive: !dockState.layout.isBottomCollapsed,
                action: { dockState.layout.toggleCollapse(for: .bottom) }
            )
        }
    }
    
    private var agentButton: some View {
        let theme = themeManager.currentTheme
        
        return Button(action: { toggleAgentPanel() }) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                Text("Agent")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(theme.colors.tertiaryBackground)
            .cornerRadius(6)
            .foregroundColor(theme.colors.text)
        }
        .buttonStyle(.plain)
    }
    
    private var settingsButton: some View {
        let theme = themeManager.currentTheme
        
        return Button(action: { showingMCPSettings = true }) {
            Image(systemName: "gearshape")
                .padding(6)
                .background(theme.colors.tertiaryBackground)
                .cornerRadius(6)
                .foregroundColor(theme.colors.text)
        }
        .buttonStyle(.plain)
    }
    
    private var addPanelMenu: some View {
        let theme = themeManager.currentTheme
        
        return Menu {
            Section("Editors") {
                Button(action: { addFloatingPanel(type: .htmlPreview) }) {
                    Label("HTML Preview", systemImage: "globe")
                }
            }
            Divider()
            Section("Panels") {
                Button(action: { addFloatingPanel(type: .fileExplorer) }) {
                    Label("File Explorer", systemImage: "folder")
                }
                Button(action: { addFloatingPanel(type: .console) }) {
                    Label("Console", systemImage: "terminal")
                }
                Button(action: { addFloatingPanel(type: .search) }) {
                    Label("Search", systemImage: "magnifyingglass")
                }
            }
            Divider()
            Section("AI Agent") {
                Button(action: { addFloatingPanel(type: .agentChat) }) {
                    Label("AI Assistant", systemImage: "sparkles")
                }
                Button(action: { addFloatingPanel(type: .tools) }) {
                    Label("Tools", systemImage: "wrench.and.screwdriver")
                }
            }
        } label: {
            Image(systemName: "plus.rectangle")
                .padding(6)
                .background(theme.colors.tertiaryBackground)
                .cornerRadius(6)
                .foregroundColor(theme.colors.text)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Initialization
    
    private func initializeIDE() {
        isInitialized = true
        
        // Initialize MCP system
        MCP.initialize()
        
        // Connect Agent-IDE bridge
        AgentIDEBridge.shared.connect(to: ideState)
        
        Task {
            await ideState.initialize()
            await MainActor.run {
                setupProjectPanels()
                updateMCPContext()
            }
        }
    }
    
    private func updateMCPContext() {
        guard let project = ideState.workspaceManager.project else { return }
        MCP.setProjectContext(
            rootURL: project.rootURL,
            openFiles: project.openDocuments.map { $0.fileURL },
            activeFile: project.activeDocument?.fileURL
        )
    }
    
    private func setupProjectPanels() {
        guard let project = ideState.workspaceManager.project else { return }
        
        // Left: Project Explorer
        let explorerGroup = DockPanelGroup(panels: [
            DockPanel(
                id: "project-explorer",
                title: project.name,
                icon: "folder.fill",
                position: .left,
                visibility: .standard
            ) {
                IDEProjectExplorerPanel(project: project)
                    .environmentObject(ideState)
            }
        ], position: .left)
        dockState.layout.leftNode = .panel(explorerGroup)
        
        // Right: Preview + Agent
        dockState.layout.rightNode = .panel(DockPanelGroup(panels: [
            DockPanel(
                id: "preview-main",
                title: "Preview",
                icon: "eye",
                position: .right,
                visibility: .standard
            ) { IDEPreviewPanel(project: project).environmentObject(ideState) },
            DockPanel(
                id: "agent-main",
                title: "AI Assistant",
                icon: "sparkles",
                position: .right,
                visibility: .standard
            ) { AgentChatView().environmentObject(ideState) }
        ], position: .right))
        
        // Bottom: Console
        dockState.layout.bottomNode = .panel(DockPanelGroup(panels: [
            DockPanel(
                id: "console-main",
                title: "Console",
                icon: "terminal.fill",
                position: .bottom,
                visibility: .standard
            ) { IDEConsolePanel().environmentObject(ideState) }
        ], position: .bottom))
        
        // Auto-open index.html if exists
        Task {
            let indexURL = project.rootURL.appendingPathComponent("index.html")
            if IDEFileSystemManager.shared.fileExists(at: indexURL) {
                await ideState.openFile(indexURL)
            }
        }
    }
    
    // MARK: - Layout Management
    
    private func applyWorkspaceLayout(_ layoutType: IDELayoutType) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            switch layoutType {
            case .coding:
                dockState.layout.leftWidth = 250
                dockState.layout.rightWidth = 0
                dockState.layout.bottomHeight = 150
                dockState.layout.isLeftCollapsed = false
                dockState.layout.isRightCollapsed = true
                dockState.layout.isBottomCollapsed = false
                
            case .preview:
                dockState.layout.leftWidth = 200
                dockState.layout.rightWidth = 350
                dockState.layout.bottomHeight = 0
                dockState.layout.isLeftCollapsed = false
                dockState.layout.isRightCollapsed = false
                dockState.layout.isBottomCollapsed = true
                
            case .debug:
                dockState.layout.leftWidth = 250
                dockState.layout.rightWidth = 280
                dockState.layout.bottomHeight = 200
                dockState.layout.isLeftCollapsed = false
                dockState.layout.isRightCollapsed = false
                dockState.layout.isBottomCollapsed = false
                
            case .design:
                dockState.layout.leftWidth = 0
                dockState.layout.rightWidth = 400
                dockState.layout.bottomHeight = 0
                dockState.layout.isLeftCollapsed = true
                dockState.layout.isRightCollapsed = false
                dockState.layout.isBottomCollapsed = true
                
            case .custom:
                break
            }
        }
    }
    
    private func resetLayout() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dockState.layout.leftWidth = 250
            dockState.layout.rightWidth = 300
            dockState.layout.bottomHeight = 150
            dockState.layout.isLeftCollapsed = false
            dockState.layout.isRightCollapsed = false
            dockState.layout.isBottomCollapsed = false
        }
    }
    
    private func toggleAgentPanel() {
        // Find and activate the agent panel in the right panel group
        if case .panel(let rightGroup) = dockState.layout.rightNode {
            if let agentIndex = rightGroup.panels.firstIndex(where: { $0.id == "agent-main" }) {
                rightGroup.activeTabIndex = agentIndex
            }
        }
        
        // Make sure right panel is visible
        if dockState.layout.isRightCollapsed {
            withAnimation(.spring(response: 0.3)) {
                dockState.layout.isRightCollapsed = false
                dockState.layout.rightWidth = 350
            }
        }
    }
    
    private func addFloatingPanel(type: IDEPanelType) {
        guard let project = ideState.workspaceManager.project else { return }
        
        let panel: DockPanel
        
        switch type {
        case .htmlPreview:
            panel = DockPanel(
                id: "preview-\(UUID().uuidString.prefix(4))",
                title: "HTML Preview",
                icon: "globe",
                position: .center,
                visibility: [.showHeader, .showCloseButton, .allowDrag, .allowTabbing, .allowFloat]
            ) {
                IDEPreviewPanel(project: project)
                    .environmentObject(ideState)
            }
            
        case .fileExplorer:
            panel = DockPanel(
                id: "explorer-\(UUID().uuidString.prefix(4))",
                title: "Explorer",
                icon: "folder.fill",
                position: .left,
                visibility: [.showHeader, .showCloseButton, .allowDrag, .allowTabbing, .allowFloat]
            ) {
                IDEProjectExplorerPanel(project: project)
                    .environmentObject(ideState)
            }
            
        case .console:
            panel = DockPanel(
                id: "console-\(UUID().uuidString.prefix(4))",
                title: "Console",
                icon: "terminal.fill",
                position: .bottom,
                visibility: [.showHeader, .showCloseButton, .allowDrag, .allowTabbing, .allowFloat]
            ) {
                IDEConsolePanel()
                    .environmentObject(ideState)
            }
            
        case .search:
            panel = DockPanel(
                id: "search-\(UUID().uuidString.prefix(4))",
                title: "Search",
                icon: "magnifyingglass",
                position: .left,
                visibility: [.showHeader, .showCloseButton, .allowDrag, .allowTabbing, .allowFloat]
            ) {
                SearchView()
            }
            
        case .agentChat:
            panel = DockPanel(
                id: "agent-\(UUID().uuidString.prefix(4))",
                title: "AI Assistant",
                icon: "sparkles",
                position: .right,
                size: CGSize(width: 400, height: 500),
                visibility: [.showHeader, .showCloseButton, .allowDrag, .allowTabbing, .allowFloat]
            ) {
                AgentChatView()
                    .environmentObject(ideState)
            }
            
        case .tools:
            panel = DockPanel(
                id: "tools-\(UUID().uuidString.prefix(4))",
                title: "Tools",
                icon: "wrench.and.screwdriver",
                position: .right,
                size: CGSize(width: 350, height: 400),
                visibility: [.showHeader, .showCloseButton, .allowDrag, .allowTabbing, .allowFloat]
            ) {
                ToolsPanelView()
            }
        }
        
        withAnimation(.spring(response: 0.3)) {
            let floatingGroup = DockPanelGroup(
                panels: [panel],
                position: .floating,
                size: CGSize(width: 350, height: 400)
            )
            panel.floatingFrame = CGRect(x: 100, y: 100, width: 350, height: 400)
            dockState.layout.floatingPanels.append(floatingGroup)
        }
    }
    
    // MARK: - Initial Layout
    
    static func createInitialLayout() -> DockLayout {
        var layout = DockLayout()
        layout.leftWidth = 250
        layout.rightWidth = 300
        layout.bottomHeight = 150
        return layout
    }
}

// MARK: - IDE Panel Type

enum IDEPanelType {
    case htmlPreview
    case fileExplorer
    case console
    case search
    case agentChat
    case tools
}
