import SwiftUI

// MARK: - Retro Mac OS 9 Style Class

public struct RetroMaxOS9StyleClass: DockStyleClass {
    public init() {}
    
    public func makeHeader() -> RetroMaxOS9HeaderStyle {
        RetroMaxOS9HeaderStyle()
    }
    
    public func makeTabBar() -> RetroMaxOS9TabBarStyle {
        RetroMaxOS9TabBarStyle()
    }
    
    public func makeResizeHandle() -> RetroMaxOS9ResizeHandleStyle {
        RetroMaxOS9ResizeHandleStyle()
    }
    
    public func makeDropZone() -> RetroMaxOS9DropZoneStyle {
        RetroMaxOS9DropZoneStyle()
    }
}

// MARK: - Retro Mac OS 9 Header Style

public struct RetroMaxOS9HeaderStyle: DockHeaderStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockHeaderConfiguration) -> some View {
        let isActive = configuration.isActive
        let titleColor = isActive ? Color.white : theme.colors.text
        let iconColor = isActive ? Color.white : theme.colors.secondaryText
        let headerGradient = LinearGradient(
            colors: isActive
                ? [theme.colors.accentSecondary, theme.colors.accent]
                : [theme.colors.headerBackground, theme.colors.secondaryBackground],
            startPoint: .top,
            endPoint: .bottom
        )
        let bevelHighlight = isActive
            ? theme.colors.accentSecondary.opacity(0.7)
            : theme.colors.panelBackground
        let bevelShadow = isActive
            ? theme.colors.tertiaryBackground.opacity(0.85)
            : theme.colors.tertiaryBackground

        return HStack(spacing: 6) {
            if let icon = configuration.icon {
                RetroIcon(systemName: icon, color: iconColor)
            }

            Text(configuration.title)
                .font(theme.typography.headerFont)
                .fontWeight(theme.typography.headerFontWeight)
                .foregroundColor(titleColor)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 4) {
                if configuration.visibility.contains(.showCollapseButton) {
                    RetroButton(
                        icon: configuration.isCollapsed ? "chevron.down" : "chevron.up",
                        action: configuration.onCollapse
                    )
                }

                if configuration.visibility.contains(.showMaximizeButton) {
                    RetroButton(
                        icon: "arrow.up.left.and.arrow.down.right",
                        action: configuration.onMaximize
                    )
                }

                if configuration.visibility.contains(.allowFloat) {
                    RetroButton(
                        icon: "uiwindow.split.2x1",
                        action: configuration.onFloat
                    )
                }

                if configuration.visibility.contains(.showCloseButton) {
                    RetroButton(
                        icon: "xmark",
                        action: configuration.onClose,
                        isCloseButton: true
                    )
                }
            }
        }
        .padding(.horizontal, theme.spacing.headerPadding)
        .padding(.vertical, max(theme.spacing.headerPadding - 3, 4))
        .background(headerGradient)
        .retroBevel(highlight: bevelHighlight, shadow: bevelShadow)
        .overlay(
            Rectangle()
                .fill(theme.colors.border)
                .frame(height: theme.borders.separatorWidth),
            alignment: .bottom
        )
    }
}

// MARK: - Retro Mac OS 9 Tab Bar Style

public struct RetroMaxOS9TabBarStyle: DockTabBarStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockTabBarConfiguration) -> some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(configuration.tabs.enumerated()), id: \.element.id) { index, tab in
                        RetroTabButton(
                            title: tab.title,
                            icon: tab.icon,
                            isActive: tab.isActive,
                            isFirst: index == 0,
                            isLast: index == configuration.tabs.count - 1,
                            action: { configuration.onSelect(index) }
                        )
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 2)
            }
        }
        .background(
            LinearGradient(
                colors: [theme.colors.tabBackground, theme.colors.secondaryBackground],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .retroBevel(highlight: theme.colors.panelBackground, shadow: theme.colors.tertiaryBackground)
        .overlay(
            Rectangle()
                .fill(theme.colors.border)
                .frame(height: theme.borders.separatorWidth),
            alignment: .bottom
        )
    }
}

// MARK: - Retro Resize Handle Style

public struct RetroMaxOS9ResizeHandleStyle: DockResizeHandleStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockResizeHandleConfiguration) -> some View {
        Group {
            if configuration.orientation == .horizontal {
                let thickness = max(theme.spacing.resizeHandleSize, 4)
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(theme.colors.panelBackground)
                        .frame(height: 1)
                    Rectangle()
                        .fill(theme.colors.resizeHandle)
                        .frame(height: thickness - 2)
                    Rectangle()
                        .fill(theme.colors.tertiaryBackground)
                        .frame(height: 1)
                }
                .frame(maxWidth: .infinity)
            } else {
                let thickness = max(theme.spacing.resizeHandleSize, 4)
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(theme.colors.panelBackground)
                        .frame(width: 1)
                    Rectangle()
                        .fill(theme.colors.resizeHandle)
                        .frame(width: thickness - 2)
                    Rectangle()
                        .fill(theme.colors.tertiaryBackground)
                        .frame(width: 1)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .opacity(configuration.isHovered ? 1.0 : 0.75)
        .animation(.easeInOut(duration: theme.animations.quickDuration), value: configuration.isHovered)
    }
}

// MARK: - Retro Drop Zone Style

public struct RetroMaxOS9DropZoneStyle: DockDropZoneStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockDropZoneConfiguration) -> some View {
        Group {
            if configuration.isActive {
                Rectangle()
                    .fill(theme.colors.dropZoneBackground)
                    .retroBevel(
                        highlight: theme.colors.panelBackground.opacity(0.8),
                        shadow: theme.colors.tertiaryBackground
                    )
                    .overlay(
                        Rectangle()
                            .strokeBorder(
                                theme.colors.dropZoneHighlight,
                                style: StrokeStyle(lineWidth: 2, dash: [5, 3])
                            )
                    )
                    .overlay(
                        Rectangle()
                            .strokeBorder(theme.colors.border, lineWidth: theme.borders.borderWidth)
                    )
                .animation(.easeInOut(duration: theme.animations.defaultDuration), value: configuration.isActive)
            }
        }
    }
}

// MARK: - Retro Components

private struct RetroIcon: View {
    let systemName: String
    let color: Color

    @Environment(\.dockTheme) var theme

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: theme.typography.iconSize, weight: .medium))
            .foregroundColor(color)
    }
}

private struct RetroButton: View {
    let icon: String
    let action: () -> Void
    let isCloseButton: Bool
    
    @Environment(\.dockTheme) var theme
    @State private var isPressed = false
    
    init(icon: String, action: @escaping () -> Void, isCloseButton: Bool = false) {
        self.icon = icon
        self.action = action
        self.isCloseButton = isCloseButton
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(isCloseButton ? theme.colors.accent : theme.colors.panelBackground)

                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(isCloseButton ? .white : theme.colors.text)
            }
            .frame(width: 14, height: 14)
            .retroBevel(
                highlight: isPressed ? theme.colors.tertiaryBackground : theme.colors.background,
                shadow: isPressed ? theme.colors.background : theme.colors.tertiaryBackground
            )
            .overlay(
                Rectangle()
                    .strokeBorder(theme.colors.border, lineWidth: theme.borders.borderWidth)
            )
        }
        .buttonStyle(.plain)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
}

private struct RetroTabButton: View {
    let title: String
    let icon: String?
    let isActive: Bool
    let isFirst: Bool
    let isLast: Bool
    let action: () -> Void
    
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: max(theme.typography.iconSize - 3, 9), weight: .medium))
                        .foregroundColor(isActive ? theme.colors.text : theme.colors.secondaryText)
                }

                Text(title)
                    .font(theme.typography.tabFont)
                    .fontWeight(theme.typography.tabFontWeight)
                    .foregroundColor(isActive ? theme.colors.text : theme.colors.secondaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, theme.spacing.tabPadding)
            .padding(.vertical, 3)
            .padding(.leading, isFirst ? 2 : 0)
            .frame(minHeight: 18)
            .background(isActive ? theme.colors.activeTabBackground : theme.colors.tabBackground)
            .retroBevel(
                highlight: isActive ? theme.colors.panelBackground : theme.colors.background,
                shadow: theme.colors.tertiaryBackground
            )
            .overlay(
                Group {
                    if !isActive {
                        Rectangle()
                            .fill(theme.colors.border)
                            .frame(height: theme.borders.separatorWidth)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
            )
            .overlay(
                Group {
                    if !isLast {
                        Rectangle()
                            .fill(theme.colors.border)
                            .frame(width: theme.borders.separatorWidth)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    func retroBevel(highlight: Color, shadow: Color, lineWidth: CGFloat = 1) -> some View {
        self
            .overlay(
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(highlight)
                        .frame(height: lineWidth)
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(shadow)
                        .frame(height: lineWidth)
                }
            )
            .overlay(
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(highlight)
                        .frame(width: lineWidth)
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(shadow)
                        .frame(width: lineWidth)
                }
            )
    }
}
