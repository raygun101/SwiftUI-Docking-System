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
