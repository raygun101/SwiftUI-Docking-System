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
    
    public func makeFloatingPanel() -> DefaultFloatingPanelStyle {
        DefaultFloatingPanelStyle()
    }
    
    public func makeDragPreview() -> DefaultDragPreviewStyle {
        DefaultDragPreviewStyle()
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

// MARK: - Default Floating Panel Style

public struct DefaultFloatingPanelStyle: DockFloatingPanelStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockFloatingPanelConfiguration) -> some View {
        VStack(spacing: 0) {
            // Floating window header
            floatingHeader(configuration: configuration)
            
            // Tab bar if multiple panels
            if configuration.hasMultipleTabs {
                floatingTabBar(configuration: configuration)
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
    private func floatingHeader(configuration: DockFloatingPanelConfiguration) -> some View {
        HStack(spacing: theme.spacing.tabPadding) {
            // macOS-style window controls
            HStack(spacing: 6) {
                WindowControlButton(color: Color(red: 1.0, green: 0.38, blue: 0.35)) {
                    configuration.onClose()
                }
                
                WindowControlButton(color: Color(red: 1.0, green: 0.78, blue: 0.25)) {
                    configuration.onMinimize()
                }
                
                WindowControlButton(color: Color(red: 0.35, green: 0.78, blue: 0.35)) {
                    configuration.onMaximize()
                }
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Title
            HStack(spacing: 4) {
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
            .padding(.trailing, 8)
        }
        .frame(height: 32)
        .background(theme.colors.headerBackground)
    }
    
    @ViewBuilder
    private func floatingTabBar(configuration: DockFloatingPanelConfiguration) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(configuration.tabs.enumerated()), id: \.element.id) { index, tab in
                    FloatingTabButton(
                        tab: tab,
                        isActive: index == configuration.activeTabIndex,
                        onSelect: { configuration.onTabSelect(index) },
                        onClose: { configuration.onTabClose(index) }
                    )
                }
            }
        }
        .frame(height: 28)
        .background(theme.colors.tabBackground)
        .overlay(
            Rectangle()
                .frame(height: theme.borders.separatorWidth)
                .foregroundColor(theme.colors.separator),
            alignment: .bottom
        )
    }
}

// MARK: - Window Control Button

private struct WindowControlButton: View {
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .opacity(isHovered ? 1.0 : 0.85)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Floating Tab Button

private struct FloatingTabButton: View {
    let tab: DockTabItem
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = tab.icon {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(isActive ? theme.colors.accent : theme.colors.secondaryText)
            }
            
            Text(tab.title)
                .font(.system(size: 11))
                .foregroundColor(isActive ? theme.colors.text : theme.colors.secondaryText)
                .lineLimit(1)
            
            if isHovered || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(theme.colors.tertiaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isActive ? theme.colors.activeTabBackground : (isHovered ? theme.colors.hoverBackground : Color.clear))
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Default Drag Preview Style

public struct DefaultDragPreviewStyle: DockDragPreviewStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockDragPreviewConfiguration) -> some View {
        HStack(spacing: 8) {
            if let icon = configuration.icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(theme.colors.accent)
            }
            
            Text(configuration.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.colors.panelBackground)
                .shadow(color: theme.colors.shadowColor, radius: 16, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(theme.colors.accent, lineWidth: 2)
        )
    }
}

