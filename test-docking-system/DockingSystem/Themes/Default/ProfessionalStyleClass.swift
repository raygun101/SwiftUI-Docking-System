import SwiftUI

// MARK: - Professional Style Class

/// A modern, clean style class for professional IDE-like applications
public struct ProfessionalStyleClass: DockStyleClass {
    public init() {}
    
    public func makeHeader() -> ProfessionalHeaderStyle {
        ProfessionalHeaderStyle()
    }
    
    public func makeTabBar() -> ProfessionalTabBarStyle {
        ProfessionalTabBarStyle()
    }
    
    public func makeResizeHandle() -> ProfessionalResizeHandleStyle {
        ProfessionalResizeHandleStyle()
    }
    
    public func makeDropZone() -> ProfessionalDropZoneStyle {
        ProfessionalDropZoneStyle()
    }
    
    public func makeFloatingPanel() -> ProfessionalFloatingPanelStyle {
        ProfessionalFloatingPanelStyle()
    }
    
    public func makeDragPreview() -> ProfessionalDragPreviewStyle {
        ProfessionalDragPreviewStyle()
    }
}

// MARK: - Professional Header Style

public struct ProfessionalHeaderStyle: DockHeaderStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockHeaderConfiguration) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: theme.spacing.headerPadding) {
                if let icon = configuration.icon {
                    Image(systemName: icon)
                        .font(.system(size: theme.typography.iconSize))
                        .foregroundColor(configuration.isActive ? theme.colors.accent : theme.colors.secondaryText)
                }
                
                Text(configuration.title)
                    .font(theme.typography.headerFont)
                    .fontWeight(theme.typography.headerFontWeight)
                    .foregroundColor(configuration.isActive ? theme.colors.text : theme.colors.secondaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                if configuration.visibility.contains(.showCollapseButton) {
                    ProfessionalHeaderButton(
                        icon: configuration.isCollapsed ? "chevron.down" : "chevron.up",
                        action: configuration.onCollapse
                    )
                }
                
                if configuration.visibility.contains(.showMaximizeButton) {
                    ProfessionalHeaderButton(
                        icon: "arrow.up.left.and.arrow.down.right",
                        action: configuration.onMaximize
                    )
                }
                
                if configuration.visibility.contains(.allowFloat) {
                    ProfessionalHeaderButton(
                        icon: "uiwindow.split.2x1",
                        action: configuration.onFloat
                    )
                }
                
                if configuration.visibility.contains(.showCloseButton) {
                    ProfessionalHeaderButton(
                        icon: "xmark",
                        action: configuration.onClose
                    )
                }
            }
        }
        .padding(.horizontal, theme.spacing.headerPadding)
        .padding(.vertical, theme.spacing.headerPadding - 2)
        .background(configuration.isActive ? theme.colors.activeHeaderBackground : theme.colors.headerBackground)
        .overlay(
            Rectangle()
                .frame(height: theme.borders.separatorWidth)
                .foregroundColor(theme.colors.separator),
            alignment: .bottom
        )
    }
}

// MARK: - Professional Tab Bar Style

public struct ProfessionalTabBarStyle: DockTabBarStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockTabBarConfiguration) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(configuration.tabs.enumerated()), id: \.element.id) { index, tab in
                    ProfessionalTabButton(
                        title: tab.title,
                        icon: tab.icon,
                        isActive: tab.isActive,
                        action: { configuration.onSelect(index) }
                    )
                }
            }
        }
        .background(theme.colors.tabBackground)
        .overlay(
            Rectangle()
                .frame(height: theme.borders.separatorWidth)
                .foregroundColor(theme.colors.separator),
            alignment: .bottom
        )
    }
}

// MARK: - Professional Resize Handle Style

public struct ProfessionalResizeHandleStyle: DockResizeHandleStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockResizeHandleConfiguration) -> some View {
        Group {
            if configuration.orientation == .horizontal {
                Rectangle()
                    .fill(configuration.isHovered ? theme.colors.accent : theme.colors.separator)
                    .frame(height: theme.spacing.resizeHandleSize)
                    .frame(maxWidth: .infinity)
            } else {
                Rectangle()
                    .fill(configuration.isHovered ? theme.colors.accent : theme.colors.separator)
                    .frame(width: theme.spacing.resizeHandleSize)
                    .frame(maxHeight: .infinity)
            }
        }
        .animation(.easeInOut(duration: theme.animations.quickDuration), value: configuration.isHovered)
    }
}

// MARK: - Professional Drop Zone Style

public struct ProfessionalDropZoneStyle: DockDropZoneStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockDropZoneConfiguration) -> some View {
        Group {
            if configuration.isActive {
                RoundedRectangle(cornerRadius: theme.cornerRadii.dropZone)
                    .fill(theme.colors.dropZoneBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadii.dropZone)
                            .strokeBorder(theme.colors.dropZoneHighlight, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    )
                    .animation(.easeInOut(duration: theme.animations.defaultDuration), value: configuration.isActive)
            }
        }
    }
}

// MARK: - Professional Components

private struct ProfessionalHeaderButton: View {
    let icon: String
    let action: () -> Void
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isHovered ? theme.colors.text : theme.colors.secondaryText)
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadii.button)
                        .fill(isHovered ? theme.colors.hoverBackground : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private struct ProfessionalTabButton: View {
    let title: String
    let icon: String?
    let isActive: Bool
    let action: () -> Void
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(isActive ? theme.colors.accent : theme.colors.secondaryText)
                }
                
                Text(title)
                    .font(theme.typography.tabFont)
                    .fontWeight(theme.typography.tabFontWeight)
                    .foregroundColor(isActive ? theme.colors.text : theme.colors.secondaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, theme.spacing.tabPadding + 4)
            .padding(.vertical, theme.spacing.tabPadding)
            .background(isActive ? theme.colors.activeTabBackground : (isHovered ? theme.colors.hoverBackground : Color.clear))
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(isActive ? theme.colors.accent : Color.clear),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Professional Floating Panel Style

public struct ProfessionalFloatingPanelStyle: DockFloatingPanelStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockFloatingPanelConfiguration) -> some View {
        VStack(spacing: 0) {
            // Modern floating header
            professionalFloatingHeader(configuration: configuration)
            
            // Tab bar if multiple panels
            if configuration.hasMultipleTabs {
                professionalFloatingTabBar(configuration: configuration)
            }
            
            // Content
            configuration.content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
        .frame(width: configuration.size.width, height: configuration.size.height)
        .background(theme.colors.panelBackground)
        .cornerRadius(theme.cornerRadii.floating)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadii.floating)
                .strokeBorder(
                    configuration.isActive ? theme.colors.activeBorder : theme.colors.border,
                    lineWidth: configuration.isActive
                        ? theme.borders.activeBorderWidth
                        : theme.borders.borderWidth
                )
        )
        .shadow(
            color: theme.colors.shadowColor,
            radius: theme.shadows.floatingShadowRadius,
            x: theme.shadows.floatingShadowOffset.width,
            y: theme.shadows.floatingShadowOffset.height
        )
    }
    
    @ViewBuilder
    private func professionalFloatingHeader(configuration: DockFloatingPanelConfiguration) -> some View {
        HStack(spacing: theme.spacing.tabPadding) {
            // Modern window controls
            HStack(spacing: 8) {
                ProfessionalWindowButton(icon: "xmark", color: Color(red: 1.0, green: 0.38, blue: 0.35)) {
                    configuration.onClose()
                }
                
                ProfessionalWindowButton(icon: "minus", color: Color(red: 1.0, green: 0.78, blue: 0.25)) {
                    configuration.onMinimize()
                }
                
                ProfessionalWindowButton(icon: "arrow.up.left.and.arrow.down.right", color: Color(red: 0.35, green: 0.78, blue: 0.35)) {
                    configuration.onMaximize()
                }
            }
            .padding(.leading, 12)
            
            Spacer()
            
            // Title
            HStack(spacing: 6) {
                if let icon = configuration.icon {
                    Image(systemName: icon)
                        .font(.system(size: theme.typography.iconSize))
                        .foregroundColor(theme.colors.secondaryText)
                }
                Text(configuration.title)
                    .font(theme.typography.headerFont)
                    .fontWeight(theme.typography.headerFontWeight)
                    .foregroundColor(theme.colors.text)
            }
            
            Spacer()
            
            // Dock button
            Button(action: configuration.onDock) {
                Image(systemName: "rectangle.inset.filled.and.person.filled")
                    .font(.system(size: theme.typography.iconSize))
                    .foregroundColor(theme.colors.secondaryText)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 12)
        }
        .frame(height: 36)
        .background(theme.colors.headerBackground)
    }
    
    @ViewBuilder
    private func professionalFloatingTabBar(configuration: DockFloatingPanelConfiguration) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(configuration.tabs.enumerated()), id: \.element.id) { index, tab in
                    ProfessionalFloatingTabButton(
                        tab: tab,
                        isActive: index == configuration.activeTabIndex,
                        onSelect: { configuration.onTabSelect(index) },
                        onClose: { configuration.onTabClose(index) }
                    )
                }
            }
        }
        .frame(height: 30)
        .background(theme.colors.tabBackground)
        .overlay(
            Rectangle()
                .frame(height: theme.borders.separatorWidth)
                .foregroundColor(theme.colors.separator),
            alignment: .bottom
        )
    }
}

// MARK: - Professional Window Button

private struct ProfessionalWindowButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                
                if isHovered {
                    Image(systemName: icon)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.black.opacity(0.6))
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Professional Floating Tab Button

private struct ProfessionalFloatingTabButton: View {
    let tab: DockTabItem
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = tab.icon {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(isActive ? theme.colors.accent : theme.colors.secondaryText)
            }
            
            Text(tab.title)
                .font(.system(size: 12))
                .foregroundColor(isActive ? theme.colors.text : theme.colors.secondaryText)
                .lineLimit(1)
            
            if isHovered || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(theme.colors.tertiaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(isActive ? theme.colors.activeTabBackground : (isHovered ? theme.colors.hoverBackground : Color.clear))
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(isActive ? theme.colors.accent : Color.clear),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Professional Drag Preview Style

public struct ProfessionalDragPreviewStyle: DockDragPreviewStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockDragPreviewConfiguration) -> some View {
        HStack(spacing: 8) {
            if let icon = configuration.icon {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.accent)
            }
            
            Text(configuration.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.colors.text)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.colors.panelBackground)
                .shadow(color: theme.colors.shadowColor, radius: 12, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(theme.colors.accent, lineWidth: 1.5)
        )
    }
}
