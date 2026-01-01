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
        VStack(spacing: 0) {
            // Top beveled edge
            HStack(spacing: 0) {
                Rectangle()
                    .fill(theme.colors.accent)
                    .frame(height: 1)
                Rectangle()
                    .fill(theme.colors.background)
                    .frame(height: 1)
            }
            
            // Main header content
            HStack(spacing: 0) {
                // Left beveled edge
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(theme.colors.accent)
                        .frame(width: 1)
                    Rectangle()
                        .fill(theme.colors.background)
                        .frame(width: 1)
                }
                
                // Content area
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        if let icon = configuration.icon {
                            RetroIcon(systemName: icon, isActive: configuration.isActive)
                        }
                        
                        Text(configuration.title)
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundColor(configuration.isActive ? theme.colors.text : theme.colors.secondaryText)
                    }
                    
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
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    configuration.isActive ? theme.colors.activeHeaderBackground : theme.colors.headerBackground
                )
                
                // Right beveled edge
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(theme.colors.background)
                        .frame(width: 1)
                    Rectangle()
                        .fill(theme.colors.accent)
                        .frame(width: 1)
                }
            }
            
            // Bottom beveled edge
            HStack(spacing: 0) {
                Rectangle()
                    .fill(theme.colors.background)
                    .frame(height: 1)
                Rectangle()
                    .fill(theme.colors.accent)
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Retro Mac OS 9 Tab Bar Style

public struct RetroMaxOS9TabBarStyle: DockTabBarStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockTabBarConfiguration) -> some View {
        VStack(spacing: 0) {
            // Top beveled edge
            HStack(spacing: 0) {
                Rectangle()
                    .fill(theme.colors.accent)
                    .frame(height: 1)
                Rectangle()
                    .fill(theme.colors.background)
                    .frame(height: 1)
            }
            
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
            }
            .background(theme.colors.tabBackground)
            
            // Bottom beveled edge
            HStack(spacing: 0) {
                Rectangle()
                    .fill(theme.colors.background)
                    .frame(height: 1)
                Rectangle()
                    .fill(theme.colors.accent)
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Retro Resize Handle Style

public struct RetroMaxOS9ResizeHandleStyle: DockResizeHandleStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockResizeHandleConfiguration) -> some View {
        Group {
            if configuration.orientation == .horizontal {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(theme.colors.accent)
                        .frame(height: 1)
                    Rectangle()
                        .fill(theme.colors.resizeHandle)
                        .frame(height: 3)
                    Rectangle()
                        .fill(theme.colors.background)
                        .frame(height: 1)
                }
                .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(theme.colors.accent)
                        .frame(width: 1)
                    Rectangle()
                        .fill(theme.colors.resizeHandle)
                        .frame(width: 3)
                    Rectangle()
                        .fill(theme.colors.background)
                        .frame(width: 1)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .opacity(configuration.isHovered ? 1.0 : 0.7)
        .animation(.easeInOut(duration: theme.animations.quickDuration), value: configuration.isHovered)
    }
}

// MARK: - Retro Drop Zone Style

public struct RetroMaxOS9DropZoneStyle: DockDropZoneStyle {
    @Environment(\.dockTheme) var theme
    
    public func makeBody(configuration: DockDropZoneConfiguration) -> some View {
        Group {
            if configuration.isActive {
                VStack(spacing: 0) {
                    // Top beveled edge
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(theme.colors.accent)
                            .frame(height: 2)
                        Rectangle()
                            .fill(theme.colors.background)
                            .frame(height: 2)
                    }
                    
                    // Main drop zone
                    RoundedRectangle(cornerRadius: 0)
                        .fill(theme.colors.dropZoneBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .strokeBorder(
                                    theme.colors.dropZoneHighlight,
                                    style: StrokeStyle(lineWidth: 2, dash: [6, 3])
                                )
                        )
                    
                    // Bottom beveled edge
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(theme.colors.background)
                            .frame(height: 2)
                        Rectangle()
                            .fill(theme.colors.accent)
                            .frame(height: 2)
                    }
                }
                .animation(.easeInOut(duration: theme.animations.defaultDuration), value: configuration.isActive)
            }
        }
    }
}

// MARK: - Retro Components

private struct RetroIcon: View {
    let systemName: String
    let isActive: Bool
    
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(isActive ? theme.colors.accent : theme.colors.secondaryText)
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
            VStack(spacing: 0) {
                // Top beveled edge
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(isPressed ? theme.colors.background : theme.colors.accent)
                        .frame(width: 1, height: 1)
                    Rectangle()
                        .fill(isPressed ? theme.colors.accent : theme.colors.background)
                        .frame(width: 14, height: 1)
                    Rectangle()
                        .fill(isPressed ? theme.colors.accent : theme.colors.background)
                        .frame(width: 1, height: 1)
                }
                
                // Button content
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(isPressed ? theme.colors.accent : theme.colors.background)
                        .frame(width: 1, height: 14)
                    
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isCloseButton ? .white : theme.colors.text)
                        .frame(width: 14, height: 14)
                        .background(
                            isCloseButton ? theme.colors.accent : 
                            (isPressed ? theme.colors.hoverBackground : theme.colors.tabBackground)
                        )
                    
                    Rectangle()
                        .fill(isPressed ? theme.colors.background : theme.colors.accent)
                        .frame(width: 1, height: 14)
                }
                
                // Bottom beveled edge
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(isPressed ? theme.colors.accent : theme.colors.background)
                        .frame(width: 1, height: 1)
                    Rectangle()
                        .fill(isPressed ? theme.colors.background : theme.colors.accent)
                        .frame(width: 14, height: 1)
                    Rectangle()
                        .fill(isPressed ? theme.colors.background : theme.colors.accent)
                        .frame(width: 1, height: 1)
                }
            }
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
            VStack(spacing: 0) {
                // Top beveled edge
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(isActive ? theme.colors.accent : theme.colors.background)
                        .frame(height: 1)
                    Rectangle()
                        .fill(isActive ? theme.colors.background : theme.colors.tabBackground)
                        .frame(height: 1)
                    Rectangle()
                        .fill(isActive ? theme.colors.background : theme.colors.accent)
                        .frame(height: 1)
                }
                
                // Tab content
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(isActive ? theme.colors.background : theme.colors.accent)
                        .frame(width: 1)
                    
                    HStack(spacing: 4) {
                        if let icon = icon {
                            Image(systemName: icon)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(isActive ? theme.colors.text : theme.colors.secondaryText)
                        }
                        
                        Text(title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isActive ? theme.colors.text : theme.colors.secondaryText)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        isActive ? theme.colors.activeTabBackground : theme.colors.tabBackground
                    )
                    
                    Rectangle()
                        .fill(isActive ? theme.colors.accent : theme.colors.background)
                        .frame(width: 1)
                }
                
                // Bottom beveled edge
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(isActive ? theme.colors.background : theme.colors.accent)
                        .frame(height: 1)
                    Rectangle()
                        .fill(isActive ? theme.colors.accent : theme.colors.background)
                        .frame(height: 1)
                    Rectangle()
                        .fill(isActive ? theme.colors.accent : theme.colors.background)
                        .frame(height: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
