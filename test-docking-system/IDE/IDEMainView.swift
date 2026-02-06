import SwiftUI

// MARK: - Main IDE View

/// The main IDE view integrating all components with the docking system
public struct IDEMainView: View {
    @StateObject private var ideState = IDEState.shared
    @StateObject private var dockState: DockState
    @StateObject private var layoutManager: IDELayoutManager
    @Environment(\.dockTheme) var theme
    
    @State private var isInitialized = false
    
    public init() {
        _dockState = StateObject(wrappedValue: DockState(layout: IDEMainView.createDefaultLayout()))
        // Initialize layout manager with project URL (will be updated when project loads)
        let defaultURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        _layoutManager = StateObject(wrappedValue: IDELayoutManager(projectURL: defaultURL))
    }
    
    public var body: some View {
        ZStack {
            // Main dock container
            DockContainer(state: dockState)
                .environmentObject(ideState)
            
            // Workspace switcher (bottom right)
            workspaceSwitcher
            
            // Loading overlay
            if ideState.isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            ideState.attachDockState(dockState)
            if !isInitialized {
                initializeIDE()
            }
        }
    }
    
    // MARK: - Workspace Switcher
    
    private var workspaceSwitcher: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                LayoutProfileSwitcher(
                    profiles: layoutManager.profiles,
                    activeProfileID: layoutManager.activeProfileID,
                    onProfileSelect: { profileID in
                        layoutManager.switchToProfile(profileID)
                        if let profile = layoutManager.profiles.first(where: { $0.id == profileID }) {
                            applyLayoutProfile(profile)
                        }
                    }
                )
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                
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
    
    // MARK: - Initialization
    
    private func initializeIDE() {
        isInitialized = true
        Task {
            await ideState.initialize()
            await MainActor.run {
                updatePanelsWithProject()
            }
        }
    }
    
    private func updatePanelsWithProject() {
        guard let project = ideState.workspaceManager.project else { return }
        
        // Update left panel with project explorer
        let explorerGroup = DockPanelGroup(panels: [
            DockPanel(
                id: "project-explorer",
                title: project.name,
                icon: "folder.fill",
                position: .left
            ) {
                IDEProjectExplorerPanel(project: project)
                    .environmentObject(ideState)
            }
        ], position: .left)
        dockState.layout.leftNode = .panel(explorerGroup)
        
        dockState.layout.rightNode = .panel(DockPanelGroup(panels: [
            DockPanel(
                id: "agent-main",
                title: "AI Assistant",
                icon: "sparkles",
                position: .right
            ) {
                AgentChatView()
                    .environmentObject(ideState)
            }
        ], position: .right))
        
        // Update bottom panel with console
        dockState.layout.bottomNode = .panel(DockPanelGroup(panels: [
            DockPanel(
                id: "console",
                title: "Console",
                icon: "terminal",
                position: .bottom
            ) {
                IDEConsolePanel()
                    .environmentObject(ideState)
            }
        ], position: .bottom))
    }
    
    // MARK: - Layout Management
    
    private func applyLayoutProfile(_ profile: IDELayoutProfile) {
        withAnimation(theme.animations.springAnimation) {
            // Apply region sizes and visibility
            let regions = profile.dockRegions
            dockState.layout.leftWidth = regions.leftWidth
            dockState.layout.rightWidth = regions.rightWidth
            dockState.layout.bottomHeight = regions.bottomHeight
            dockState.layout.isLeftCollapsed = !regions.leftVisible
            dockState.layout.isRightCollapsed = !regions.rightVisible
            dockState.layout.isBottomCollapsed = !regions.bottomVisible
        }
    }
    
    // Legacy support for IDELayoutType
    private func applyLayout(_ layoutType: IDELayoutType) {
        switch layoutType {
        case .coding:
            if let profile = layoutManager.profiles.first(where: { $0.name == "Coding" }) {
                applyLayoutProfile(profile)
            }
        case .preview:
            if let profile = layoutManager.profiles.first(where: { $0.name == "Preview" }) {
                applyLayoutProfile(profile)
            }
        case .debug, .design, .custom:
            break
        }
    }
    
    // MARK: - Default Layout
    
    static func createDefaultLayout() -> DockLayout {
        var layout = DockLayout()
        layout.leftWidth = 250
        layout.rightWidth = 300
        layout.bottomHeight = 150
        return layout
    }
}

// MARK: - Workspace Switcher Bar

struct WorkspaceSwitcherBar: View {
    let workspaces: [IDEWorkspace]
    @Binding var activeIndex: Int
    let onLayoutChange: (IDELayoutType) -> Void
    
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(workspaces.enumerated()), id: \.element.id) { index, workspace in
                WorkspaceButton(
                    workspace: workspace,
                    isActive: index == activeIndex,
                    onTap: {
                        activeIndex = index
                        onLayoutChange(workspace.layoutType)
                    }
                )
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.panelBackground.opacity(0.95))
                .shadow(color: theme.colors.shadowColor.opacity(0.3), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.colors.border.opacity(0.5), lineWidth: 1)
        )
    }
}

struct WorkspaceButton: View {
    let workspace: IDEWorkspace
    let isActive: Bool
    let onTap: () -> Void
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: workspace.icon)
                    .font(.system(size: 16, weight: isActive ? .semibold : .regular))
                
                Text(workspace.name)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundColor(isActive ? theme.colors.accent : theme.colors.secondaryText)
            .frame(width: 56, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? theme.colors.accent.opacity(0.15) : (isHovered ? theme.colors.hoverBackground : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Layout Profile Switcher

struct LayoutProfileSwitcher: View {
    let profiles: [IDELayoutProfile]
    let activeProfileID: UUID?
    let onProfileSelect: (UUID) -> Void
    
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(profiles) { profile in
                LayoutProfileButton(
                    profile: profile,
                    isActive: profile.id == activeProfileID,
                    onTap: {
                        onProfileSelect(profile.id)
                    }
                )
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.panelBackground.opacity(0.95))
                .shadow(color: theme.colors.shadowColor.opacity(0.3), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.colors.border.opacity(0.5), lineWidth: 1)
        )
    }
}

struct LayoutProfileButton: View {
    let profile: IDELayoutProfile
    let isActive: Bool
    let onTap: () -> Void
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: profile.icon)
                    .font(.system(size: 16, weight: isActive ? .semibold : .regular))
                
                Text(profile.name)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(isActive ? theme.colors.accent : theme.colors.secondaryText)
            .frame(width: 56, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? theme.colors.accent.opacity(0.15) : (isHovered ? theme.colors.hoverBackground : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
