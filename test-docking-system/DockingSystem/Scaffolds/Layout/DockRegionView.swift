import SwiftUI

// MARK: - Dock Region View

/// Renders a dock layout node (panel group or split)
struct DockRegionView: View {
    let node: DockLayoutNode
    let position: DockPosition
    let isCollapsed: Bool
    let size: CGSize
    
    @EnvironmentObject var state: DockState
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        Group {
            switch node {
            case .panel(let group):
                if isCollapsed {
                    CollapsedPanelView(group: group, position: position)
                } else {
                    DockPanelGroupView(group: group, position: position)
                }
                
            case .split(let splitNode):
                if isCollapsed {
                    CollapsedPanelView(group: nil, position: position)
                } else {
                    DockSplitView(node: splitNode, position: position, size: size)
                }
                
            case .empty:
                EmptyView()
            }
        }
        .background(theme.colors.panelBackground)
    }
}

// MARK: - Collapsed Panel View

struct CollapsedPanelView: View {
    let group: DockPanelGroup?
    let position: DockPosition
    
    @EnvironmentObject var state: DockState
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        Button(action: {
            state.layout.toggleCollapse(for: position)
        }) {
            VStack(spacing: 4) {
                Image(systemName: expandIcon)
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.secondaryText)
                
                if let group = group, let panel = group.activePanel {
                    if position.isHorizontalEdge {
                        Text(panel.title)
                            .font(.system(size: 10))
                            .foregroundColor(theme.colors.tertiaryText)
                            .rotationEffect(.degrees(position == .left ? -90 : 90))
                            .fixedSize()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.colors.secondaryBackground)
        }
        .buttonStyle(.plain)
    }
    
    private var expandIcon: String {
        switch position {
        case .left: return "chevron.right"
        case .right: return "chevron.left"
        case .top: return "chevron.down"
        case .bottom: return "chevron.up"
        default: return "chevron.right"
        }
    }
}

// MARK: - Dock Panel Group View

struct DockPanelGroupView: View {
    @ObservedObject var group: DockPanelGroup
    let position: DockPosition
    
    @EnvironmentObject var state: DockState
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar if multiple panels
            if group.panels.count > 1 {
                tabBar
            }
            
            // Active panel content
            if let activePanel = group.activePanel {
                panelContent(for: activePanel)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .strokeBorder(
                    group.activePanel?.isActive == true ? theme.colors.activeBorder : theme.colors.border,
                    lineWidth: group.activePanel?.isActive == true ? theme.borders.activeBorderWidth : theme.borders.borderWidth
                )
        )
    }
    
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(group.panels.enumerated()), id: \.element.id) { index, panel in
                    TabView(
                        panel: panel,
                        isActive: index == group.activeTabIndex,
                        onSelect: {
                            withAnimation(theme.animations.quickAnimation) {
                                group.activeTabIndex = index
                                state.activatePanel(panel)
                            }
                        },
                        onClose: {
                            state.closePanel(panel)
                        }
                    )
                }
                
                Spacer()
            }
        }
        .frame(height: 32)
        .background(theme.colors.tabBackground)
        .overlay(
            Rectangle()
                .frame(height: theme.borders.separatorWidth)
                .foregroundColor(theme.colors.separator),
            alignment: .bottom
        )
    }
    
    @ViewBuilder
    private func panelContent(for panel: DockPanel) -> some View {
        VStack(spacing: 0) {
            // Header (if single panel or always show header)
            if group.panels.count == 1 || panel.visibility.contains(.showHeader) {
                DockPanelHeader(panel: panel, position: position)
            }
            
            // Content
            panel.content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            state.activatePanel(panel)
        }
    }
}

// MARK: - Tab View

struct TabView: View {
    let panel: DockPanel
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @EnvironmentObject var state: DockState
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    @State private var isDragging = false
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = panel.icon {
                Image(systemName: icon)
                    .font(.system(size: max(theme.typography.iconSize - 2, 10)))
                    .foregroundColor(isActive ? theme.colors.accent : theme.colors.secondaryText)
            }
            
            Text(panel.title)
                .font(theme.typography.tabFont)
                .fontWeight(theme.typography.tabFontWeight)
                .foregroundColor(isActive ? theme.colors.text : theme.colors.secondaryText)
                .lineLimit(1)
            
            if isHovered || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(theme.colors.tertiaryText)
                        .frame(width: 14, height: 14)
                        .background(isHovered ? theme.colors.hoverBackground : Color.clear)
                        .cornerRadius(2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, theme.spacing.tabPadding)
        .padding(.vertical, 6)
        .background(
            Group {
                if isActive {
                    theme.colors.activeTabBackground
                } else if isHovered {
                    theme.colors.hoverBackground
                } else {
                    Color.clear
                }
            }
        )
        .overlay(
            Group {
                if isActive {
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(theme.colors.accent)
                            .frame(height: 2)
                    }
                }
            }
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            isHovered = hovering
        }
        .onLongPressGesture(minimumDuration: 0.25, maximumDistance: 24, perform: {
            guard panel.visibility.contains(.allowDrag) else { return }
            guard state.draggedPanel?.id != panel.id else { return }
            isDragging = true
            state.startDrag(panel)
            
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }, onPressingChanged: { pressing in
            if !pressing, state.draggedPanel?.id == panel.id, !state.dragHasMoved {
                isDragging = false
                state.cancelDrag()
            }
        })
        .opacity(state.draggedPanel?.id == panel.id ? 0.4 : 1.0)
        .scaleEffect(state.draggedPanel?.id == panel.id ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: state.draggedPanel?.id)
    }
}

// MARK: - Panel Header

struct DockPanelHeader: View {
    @ObservedObject var panel: DockPanel
    let position: DockPosition
    
    @EnvironmentObject var state: DockState
    @Environment(\.dockTheme) var theme
    @State private var isDragging = false
    
    var body: some View {
        HStack(spacing: theme.spacing.headerPadding / 2) {
            // Icon
            if let icon = panel.icon {
                Image(systemName: icon)
                    .font(.system(size: theme.typography.iconSize))
                    .foregroundColor(panel.isActive ? theme.colors.accent : theme.colors.secondaryText)
            }
            
            // Title
            Text(panel.title)
                .font(theme.typography.headerFont)
                .fontWeight(theme.typography.headerFontWeight)
                .foregroundColor(panel.isActive ? theme.colors.text : theme.colors.secondaryText)
                .lineLimit(1)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 2) {
                if panel.visibility.contains(.showCollapseButton) {
                    HeaderActionButton(icon: "chevron.up") {
                        state.layout.toggleCollapse(for: position)
                    }
                }
                
                if panel.visibility.contains(.allowFloat) {
                    HeaderActionButton(icon: "uiwindow.split.2x1") {
                        state.floatPanel(panel)
                    }
                }
                
                if panel.visibility.contains(.showCloseButton) {
                    HeaderActionButton(icon: "xmark") {
                        state.closePanel(panel)
                    }
                }
            }
        }
        .padding(.horizontal, theme.spacing.headerPadding)
        .padding(.vertical, theme.spacing.headerPadding - 2)
        .background(panel.isActive ? theme.colors.activeHeaderBackground : theme.colors.headerBackground)
        .overlay(
            Rectangle()
                .frame(height: theme.borders.separatorWidth)
                .foregroundColor(theme.colors.separator),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.25, maximumDistance: 24, perform: {
            guard panel.visibility.contains(.allowDrag) else { return }
            guard state.draggedPanel?.id != panel.id else { return }
            isDragging = true
            state.startDrag(panel)
            
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }, onPressingChanged: { pressing in
            if !pressing, state.draggedPanel?.id == panel.id, !state.dragHasMoved {
                isDragging = false
                state.cancelDrag()
            }
        })
        .opacity(state.draggedPanel?.id == panel.id ? 0.4 : 1.0)
    }
}

// MARK: - Header Action Button

struct HeaderActionButton: View {
    let icon: String
    let action: () -> Void
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: max(theme.typography.iconSize - 2, 10)))
                .foregroundColor(theme.colors.secondaryText)
                .frame(width: 22, height: 22)
                .background(isHovered ? theme.colors.hoverBackground : Color.clear)
                .cornerRadius(theme.cornerRadii.button)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
