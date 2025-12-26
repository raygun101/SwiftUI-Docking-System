import SwiftUI

// MARK: - Style Protocols

/// Protocol for panel header styling
public protocol DockHeaderStyle {
    associatedtype Body: View
    func makeBody(configuration: DockHeaderConfiguration) -> Body
}

public struct DockHeaderConfiguration {
    public let title: String
    public let icon: String?
    public let isActive: Bool
    public let isCollapsed: Bool
    public let position: DockPosition
    public let visibility: DockPanelVisibility
    public let onClose: () -> Void
    public let onCollapse: () -> Void
    public let onMaximize: () -> Void
    public let onFloat: () -> Void
}

/// Protocol for tab bar styling
public protocol DockTabBarStyle {
    associatedtype Body: View
    func makeBody(configuration: DockTabBarConfiguration) -> Body
}

public struct DockTabBarConfiguration {
    public let tabs: [DockTabItem]
    public let activeIndex: Int
    public let position: DockPosition
    public let onSelect: (Int) -> Void
    public let onClose: (Int) -> Void
    public let onReorder: (Int, Int) -> Void
}

public struct DockTabItem: Identifiable {
    public let id: String
    public let title: String
    public let icon: String?
    public let isActive: Bool
}

/// Protocol for resize handle styling
public protocol DockResizeHandleStyle {
    associatedtype Body: View
    func makeBody(configuration: DockResizeHandleConfiguration) -> Body
}

public struct DockResizeHandleConfiguration {
    public let direction: ResizeDirection
    public let isActive: Bool
    public let position: DockPosition
}

/// Protocol for drop zone styling
public protocol DockDropZoneStyle {
    associatedtype Body: View
    func makeBody(configuration: DockDropZoneConfiguration) -> Body
}

public struct DockDropZoneConfiguration {
    public let zone: DockDropZone
    public let isHighlighted: Bool
    public let frame: CGRect
}

// MARK: - Default Header Style

public struct DefaultDockHeaderStyle: DockHeaderStyle {
    @Environment(\.dockTheme) var theme
    
    public init() {}
    
    public func makeBody(configuration: DockHeaderConfiguration) -> some View {
        DefaultDockHeaderView(configuration: configuration)
    }
}

struct DefaultDockHeaderView: View {
    let configuration: DockHeaderConfiguration
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        HStack(spacing: theme.spacing.itemSpacing) {
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

struct HeaderButton: View {
    let icon: String
    let action: () -> Void
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: theme.typography.smallIconSize))
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

// MARK: - Default Tab Bar Style

public struct DefaultDockTabBarStyle: DockTabBarStyle {
    public init() {}
    
    public func makeBody(configuration: DockTabBarConfiguration) -> some View {
        DefaultDockTabBarView(configuration: configuration)
    }
}

struct DefaultDockTabBarView: View {
    let configuration: DockTabBarConfiguration
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(configuration.tabs.enumerated()), id: \.element.id) { index, tab in
                    TabItemView(
                        tab: tab,
                        index: index,
                        isActive: index == configuration.activeIndex,
                        onSelect: { configuration.onSelect(index) },
                        onClose: { configuration.onClose(index) }
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

struct TabItemView: View {
    let tab: DockTabItem
    let index: Int
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = tab.icon {
                Image(systemName: icon)
                    .font(.system(size: theme.typography.smallIconSize))
                    .foregroundColor(isActive ? theme.colors.accent : theme.colors.secondaryText)
            }
            
            Text(tab.title)
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
                        .background(theme.colors.hoverBackground)
                        .cornerRadius(2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, theme.spacing.tabPadding)
        .padding(.vertical, theme.spacing.tabPadding - 2)
        .background(isActive ? theme.colors.activeTabBackground : (isHovered ? theme.colors.hoverBackground : Color.clear))
        .cornerRadius(theme.cornerRadii.tab)
        .overlay(
            Group {
                if isActive {
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(theme.colors.accent)
                }
            },
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Default Resize Handle Style

public struct DefaultDockResizeHandleStyle: DockResizeHandleStyle {
    public init() {}
    
    public func makeBody(configuration: DockResizeHandleConfiguration) -> some View {
        DefaultDockResizeHandleView(configuration: configuration)
    }
}

struct DefaultDockResizeHandleView: View {
    let configuration: DockResizeHandleConfiguration
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        Rectangle()
            .fill(configuration.isActive ? theme.colors.accent : theme.colors.resizeHandle)
            .frame(
                width: configuration.direction == .vertical ? nil : theme.spacing.resizeHandleSize,
                height: configuration.direction == .horizontal ? nil : theme.spacing.resizeHandleSize
            )
            .contentShape(Rectangle())
    }
}

// MARK: - Default Drop Zone Style

public struct DefaultDockDropZoneStyle: DockDropZoneStyle {
    public init() {}
    
    public func makeBody(configuration: DockDropZoneConfiguration) -> some View {
        DefaultDockDropZoneView(configuration: configuration)
    }
}

struct DefaultDockDropZoneView: View {
    let configuration: DockDropZoneConfiguration
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadii.dropZone)
            .fill(configuration.isHighlighted ? theme.colors.dropZoneBackground : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadii.dropZone)
                    .strokeBorder(
                        configuration.isHighlighted ? theme.colors.dropZoneHighlight : Color.clear,
                        style: StrokeStyle(lineWidth: theme.borders.dropZoneBorderWidth, dash: [6, 3])
                    )
            )
            .animation(theme.animations.quickAnimation, value: configuration.isHighlighted)
    }
}

// MARK: - Style Environment Keys

struct DockHeaderStyleKey: EnvironmentKey {
    static let defaultValue: any DockHeaderStyle = DefaultDockHeaderStyle()
}

struct DockTabBarStyleKey: EnvironmentKey {
    static let defaultValue: any DockTabBarStyle = DefaultDockTabBarStyle()
}

struct DockResizeHandleStyleKey: EnvironmentKey {
    static let defaultValue: any DockResizeHandleStyle = DefaultDockResizeHandleStyle()
}

struct DockDropZoneStyleKey: EnvironmentKey {
    static let defaultValue: any DockDropZoneStyle = DefaultDockDropZoneStyle()
}

extension EnvironmentValues {
    var dockHeaderStyle: any DockHeaderStyle {
        get { self[DockHeaderStyleKey.self] }
        set { self[DockHeaderStyleKey.self] = newValue }
    }
    
    var dockTabBarStyle: any DockTabBarStyle {
        get { self[DockTabBarStyleKey.self] }
        set { self[DockTabBarStyleKey.self] = newValue }
    }
    
    var dockResizeHandleStyle: any DockResizeHandleStyle {
        get { self[DockResizeHandleStyleKey.self] }
        set { self[DockResizeHandleStyleKey.self] = newValue }
    }
    
    var dockDropZoneStyle: any DockDropZoneStyle {
        get { self[DockDropZoneStyleKey.self] }
        set { self[DockDropZoneStyleKey.self] = newValue }
    }
}
