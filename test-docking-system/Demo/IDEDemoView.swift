import SwiftUI

// MARK: - IDE Demo View

/// Comprehensive demo showcasing the docking system capabilities
struct IDEDemoView: View {
    @StateObject private var dockState: DockState
    @State private var showingThemePicker = false
    @State private var showingLayoutPicker = false
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    init() {
        let layout = Self.createIDELayout()
        _dockState = StateObject(wrappedValue: DockState(layout: layout))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar at top (not overlapping)
            toolbar
            
            // Main docking system fills remaining space
            DockingSystem(state: dockState, theme: themeManager.currentTheme)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .onAppear {
            dockState.loadFromUserDefaults()
        }
        .onChange(of: dockState.layout.leftWidth) { _, _ in dockState.saveToUserDefaults() }
        .onChange(of: dockState.layout.rightWidth) { _, _ in dockState.saveToUserDefaults() }
        .onChange(of: dockState.layout.topHeight) { _, _ in dockState.saveToUserDefaults() }
        .onChange(of: dockState.layout.bottomHeight) { _, _ in dockState.saveToUserDefaults() }
        .onChange(of: dockState.layout.isLeftCollapsed) { _, _ in dockState.saveToUserDefaults() }
        .onChange(of: dockState.layout.isRightCollapsed) { _, _ in dockState.saveToUserDefaults() }
        .onChange(of: dockState.layout.isTopCollapsed) { _, _ in dockState.saveToUserDefaults() }
        .onChange(of: dockState.layout.isBottomCollapsed) { _, _ in dockState.saveToUserDefaults() }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        let theme = themeManager.currentTheme
        
        return HStack(spacing: 16) {
            // App title
            HStack(spacing: 8) {
                Image(systemName: "hammer.fill")
                    .foregroundColor(theme.colors.accent)
                Text("Dock IDE")
                    .font(theme.typography.headerFont.weight(.bold))
                    .foregroundColor(theme.colors.text)
            }
            
            Divider()
                .frame(height: 20)
                .overlay(theme.colors.separator)
            
            // Theme picker
            themePicker
            
            // Layout presets
            Menu {
                Button("IDE Layout") { applyLayout(.ide) }
                Button("Minimal Layout") { applyLayout(.minimal) }
                Button("Writing Layout") { applyLayout(.writing) }
                Button("Debug Layout") { applyLayout(.debug) }
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
            
            Spacer()
            
            // Panel toggles
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
            
            Divider()
                .frame(height: 20)
                .overlay(theme.colors.separator)
            
            // Add panel button
            Menu {
                Button(action: { addPanel(type: .fileExplorer) }) {
                    Label("File Explorer", systemImage: "folder")
                }
                Button(action: { addPanel(type: .console) }) {
                    Label("Console", systemImage: "terminal")
                }
                Button(action: { addPanel(type: .inspector) }) {
                    Label("Inspector", systemImage: "info.circle")
                }
                Button(action: { addPanel(type: .search) }) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                Button(action: { addPanel(type: .debug) }) {
                    Label("Debug", systemImage: "ant")
                }
                Button(action: { addPanel(type: .git) }) {
                    Label("Source Control", systemImage: "arrow.triangle.branch")
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
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(theme.colors.headerBackground)
    }
    
    // MARK: - Layout Creation
    
    static func createIDELayout() -> DockLayout {
        let layout = DockLayout()
        
        // Left panel - File Explorer & Search
        let fileExplorer = DockPanel(
            id: "file-explorer",
            title: "Explorer",
            icon: "folder.fill",
            position: .left,
            visibility: .standard
        ) {
            FileExplorerView()
        }
        
        let search = DockPanel(
            id: "search",
            title: "Search",
            icon: "magnifyingglass",
            position: .left,
            visibility: .standard
        ) {
            SearchView()
        }
        
        let sourceControl = DockPanel(
            id: "source-control",
            title: "Source Control",
            icon: "arrow.triangle.branch",
            position: .left,
            visibility: .standard
        ) {
            SourceControlView()
        }
        
        let leftGroup = DockPanelGroup(
            panels: [fileExplorer, search, sourceControl],
            position: .left,
            activeTabIndex: 0
        )
        layout.leftNode = .panel(leftGroup)
        layout.leftWidth = 260
        
        // Center - Code Editor
        let editor1 = DockPanel(
            id: "editor-1",
            title: "ContentView.swift",
            icon: "swift",
            position: .center,
            visibility: [.showHeader, .showCloseButton, .allowDrag, .allowTabbing]
        ) {
            CodeEditorView(fileName: "ContentView.swift")
        }
        
        let editor2 = DockPanel(
            id: "editor-2",
            title: "App.swift",
            icon: "swift",
            position: .center,
            visibility: [.showHeader, .showCloseButton, .allowDrag, .allowTabbing]
        ) {
            CodeEditorView(fileName: "App.swift")
        }
        
        let centerGroup = DockPanelGroup(
            panels: [editor1, editor2],
            position: .center,
            activeTabIndex: 0
        )
        layout.centerNode = .panel(centerGroup)
        
        // Right panel - Inspector & Debug
        let inspector = DockPanel(
            id: "inspector",
            title: "Inspector",
            icon: "info.circle",
            position: .right,
            visibility: .standard
        ) {
            InspectorView()
        }
        
        let debug = DockPanel(
            id: "debug",
            title: "Debug",
            icon: "ant.fill",
            position: .right,
            visibility: .standard
        ) {
            DebugView()
        }
        
        let rightGroup = DockPanelGroup(
            panels: [inspector, debug],
            position: .right,
            activeTabIndex: 0
        )
        layout.rightNode = .panel(rightGroup)
        layout.rightWidth = 280
        
        // Bottom panel - Console & Problems
        let console = DockPanel(
            id: "console",
            title: "Console",
            icon: "terminal.fill",
            position: .bottom,
            visibility: .standard
        ) {
            ConsoleView()
        }
        
        let problems = DockPanel(
            id: "problems",
            title: "Problems",
            icon: "exclamationmark.triangle.fill",
            position: .bottom,
            visibility: .standard
        ) {
            ProblemsView()
        }
        
        let bottomGroup = DockPanelGroup(
            panels: [console, problems],
            position: .bottom,
            activeTabIndex: 0
        )
        layout.bottomNode = .panel(bottomGroup)
        layout.bottomHeight = 200
        
        return layout
    }
    
    // MARK: - Actions
    
    private func applyLayout(_ preset: LayoutPreset) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            switch preset {
            case .ide:
                dockState.layout.isLeftCollapsed = false
                dockState.layout.isRightCollapsed = false
                dockState.layout.isBottomCollapsed = false
                dockState.layout.leftWidth = 260
                dockState.layout.rightWidth = 280
                dockState.layout.bottomHeight = 200
                
            case .minimal:
                dockState.layout.isLeftCollapsed = true
                dockState.layout.isRightCollapsed = true
                dockState.layout.isBottomCollapsed = true
                
            case .writing:
                dockState.layout.isLeftCollapsed = true
                dockState.layout.isRightCollapsed = false
                dockState.layout.isBottomCollapsed = true
                dockState.layout.rightWidth = 300
                
            case .debug:
                dockState.layout.isLeftCollapsed = false
                dockState.layout.isRightCollapsed = false
                dockState.layout.isBottomCollapsed = false
                dockState.layout.leftWidth = 200
                dockState.layout.rightWidth = 320
                dockState.layout.bottomHeight = 250
            }
        }
    }
    
    private func resetLayout() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            let newLayout = Self.createIDELayout()
            dockState.layout.leftNode = newLayout.leftNode
            dockState.layout.rightNode = newLayout.rightNode
            dockState.layout.topNode = newLayout.topNode
            dockState.layout.bottomNode = newLayout.bottomNode
            dockState.layout.centerNode = newLayout.centerNode
            dockState.layout.leftWidth = newLayout.leftWidth
            dockState.layout.rightWidth = newLayout.rightWidth
            dockState.layout.bottomHeight = newLayout.bottomHeight
            dockState.layout.isLeftCollapsed = false
            dockState.layout.isRightCollapsed = false
            dockState.layout.isBottomCollapsed = false
        }
    }
    
    private func addPanel(type: PanelType) {
        let panel: DockPanel
        
        switch type {
        case .fileExplorer:
            panel = DockPanel(
                id: "file-explorer-\(UUID().uuidString.prefix(4))",
                title: "Explorer",
                icon: "folder.fill",
                position: .left
            ) { FileExplorerView() }
            
        case .console:
            panel = DockPanel(
                id: "console-\(UUID().uuidString.prefix(4))",
                title: "Console",
                icon: "terminal.fill",
                position: .bottom
            ) { ConsoleView() }
            
        case .inspector:
            panel = DockPanel(
                id: "inspector-\(UUID().uuidString.prefix(4))",
                title: "Inspector",
                icon: "info.circle",
                position: .right
            ) { InspectorView() }
            
        case .search:
            panel = DockPanel(
                id: "search-\(UUID().uuidString.prefix(4))",
                title: "Search",
                icon: "magnifyingglass",
                position: .left
            ) { SearchView() }
            
        case .debug:
            panel = DockPanel(
                id: "debug-\(UUID().uuidString.prefix(4))",
                title: "Debug",
                icon: "ant.fill",
                position: .right
            ) { DebugView() }
            
        case .git:
            panel = DockPanel(
                id: "git-\(UUID().uuidString.prefix(4))",
                title: "Source Control",
                icon: "arrow.triangle.branch",
                position: .left
            ) { SourceControlView() }
        }
        
        // Float the new panel
        withAnimation(.spring(response: 0.3)) {
            let floatingGroup = DockPanelGroup(
                panels: [panel],
                position: .floating,
                size: CGSize(width: 300, height: 400)
            )
            panel.floatingFrame = CGRect(x: 150, y: 150, width: 300, height: 400)
            dockState.layout.floatingPanels.append(floatingGroup)
        }
    }
    
    enum LayoutPreset {
        case ide, minimal, writing, debug
    }
    
    enum PanelType {
        case fileExplorer, console, inspector, search, debug, git
    }
    
    private var themePicker: some View {
        let theme = themeManager.currentTheme
        
        return Menu {
            Button("Default Theme") {
                themeManager.applyDefaultTheme()
            }
            if !themeManager.availableThemes.isEmpty {
                Divider()
            }
            ForEach(ThemePresets.ThemeCategory.allCases, id: \.self) { category in
                let themes = themeManager.availableThemes.filter { $0.category == category }
                if !themes.isEmpty {
                    Text(category.displayName)
                        .font(.subheadline)
                    ForEach(themes, id: \.name) { theme in
                        Button(action: {
                            themeManager.applyTheme(named: theme.name)
                        }) {
                            HStack {
                                Text(theme.displayName)
                                Spacer()
                                if themeManager.selectedThemeMetadata?.name == theme.name {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    if category != ThemePresets.ThemeCategory.allCases.last {
                        Divider()
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "paintbrush")
                Text(themeManager.selectedThemeMetadata?.displayName ?? "Default Theme")
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
}

// MARK: - Panel Toggle Button

struct PanelToggleButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isActive ? theme.colors.accent : theme.colors.secondaryText)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive ? theme.colors.accent.opacity(0.15) : (isHovered ? theme.colors.hoverBackground : Color.clear))
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#Preview {
    IDEDemoView()
}
