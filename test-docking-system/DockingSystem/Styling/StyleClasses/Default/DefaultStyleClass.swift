import SwiftUI

// MARK: - Default Style Class

public struct DefaultStyleClass: DockStyleClass {
    public init() {}
    
    public func makeHeader() -> DefaultHeaderStyle {
        DefaultHeaderStyle()
    }
    
    public func makeTabBar() -> DefaultTabBarStyle {
        DefaultTabBarStyle()
    }
    
    public func makeResizeHandle() -> DefaultResizeHandleStyle {
        DefaultResizeHandleStyle()
    }
    
    public func makeDropZone() -> DefaultDropZoneStyle {
        DefaultDropZoneStyle()
    }
}

// MARK: - Default Header Style

public struct DefaultHeaderStyle: DockHeaderStyle {
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
            
            HStack(spacing: 2) {
                if configuration.visibility.contains(.showCollapseButton) {
                    HeaderButton(
                        icon: configuration.isCollapsed ? "chevron.down" : "chevron.up",
                        action: configuration.onCollapse
                    )
                }
                
                if configuration.visibility.contains(.showMaximizeButton) {
                    HeaderButton(
                        icon: "arrow.up.left.and.arrow.down.right",
                        action: configuration.onMaximize
                    )
                }
                
                if configuration.visibility.contains(.allowFloat) {
                    HeaderButton(
                        icon: "uiwindow.split.2x1",
                        action: configuration.onFloat
                    )
                }
                
                if configuration.visibility.contains(.showCloseButton) {
                    HeaderButton(
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

// MARK: - Default Tab Bar Style

public struct DefaultTabBarStyle: DockTabBarStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockTabBarConfiguration) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(configuration.tabs.enumerated()), id: \.element.id) { index, tab in
                    DefaultTabButton(
                        title: tab.title,
                        icon: tab.icon,
                        isActive: tab.isActive,
                        isLast: index == configuration.tabs.count - 1,
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

// MARK: - Default Tab Button

private struct DefaultTabButton: View {
    let title: String
    let icon: String?
    let isActive: Bool
    let isLast: Bool
    let action: () -> Void
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: theme.typography.iconSize - 2))
                        .foregroundColor(isActive ? theme.colors.accent : theme.colors.secondaryText)
                }
                
                Text(title)
                    .font(theme.typography.tabFont)
                    .fontWeight(theme.typography.tabFontWeight)
                    .foregroundColor(isActive ? theme.colors.text : theme.colors.secondaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, theme.spacing.tabPadding)
            .padding(.vertical, theme.spacing.tabPadding - 2)
            .background(
                isActive ? theme.colors.activeTabBackground : 
                (isHovered ? theme.colors.hoverBackground : Color.clear)
            )
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
        .padding(.trailing, isLast ? 0 : 1)
    }
}

// MARK: - Default Resize Handle Style

public struct DefaultResizeHandleStyle: DockResizeHandleStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockResizeHandleConfiguration) -> some View {
        Group {
            if configuration.orientation == .horizontal {
                Rectangle()
                    .fill(theme.colors.resizeHandle)
                    .frame(height: theme.spacing.resizeHandleSize)
                    .frame(maxWidth: .infinity)
            } else {
                Rectangle()
                    .fill(theme.colors.resizeHandle)
                    .frame(width: theme.spacing.resizeHandleSize)
                    .frame(maxHeight: .infinity)
            }
        }
        .opacity(configuration.isHovered ? 1.0 : 0.6)
        .scaleEffect(configuration.isDragging ? 1.5 : 1.0)
        .animation(.easeInOut(duration: theme.animations.quickDuration), value: configuration.isHovered)
        .animation(.easeInOut(duration: theme.animations.quickDuration), value: configuration.isDragging)
    }
}

// MARK: - Default Drop Zone Style

public struct DefaultDropZoneStyle: DockDropZoneStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockDropZoneConfiguration) -> some View {
        Group {
            if configuration.isActive {
                RoundedRectangle(cornerRadius: theme.cornerRadii.dropZone)
                    .fill(theme.colors.dropZoneBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadii.dropZone)
                            .strokeBorder(
                                theme.colors.dropZoneHighlight,
                                style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                            )
                    )
                    .animation(.easeInOut(duration: theme.animations.defaultDuration), value: configuration.isActive)
            }
        }
    }
}

// MARK: - Header Button

private struct HeaderButton: View {
    let icon: String
    let action: () -> Void
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: theme.typography.iconSize - 2))
                .foregroundColor(isHovered ? theme.colors.accent : theme.colors.secondaryText)
                .frame(width: 20, height: 20)
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
