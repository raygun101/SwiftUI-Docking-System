import SwiftUI

// MARK: - Core Protocols

/// Protocol defining a complete dock theme (composed of style class + palette)
public protocol DockThemeProtocol {
    var colors: DockColorScheme { get }
    var typography: DockTypography { get }
    var spacing: DockSpacing { get }
    var borders: DockBorders { get }
    var shadows: DockShadows { get }
    var animations: DockAnimations { get }
    var cornerRadii: DockCornerRadii { get }
}

/// Protocol defining visual tree structure and interactions
public protocol DockStyleClass {
    init()
    associatedtype Header: DockHeaderStyle
    associatedtype TabBar: DockTabBarStyle
    associatedtype ResizeHandle: DockResizeHandleStyle
    associatedtype DropZone: DockDropZoneStyle
    associatedtype FloatingPanel: DockFloatingPanelStyle
    associatedtype DragPreview: DockDragPreviewStyle
    
    func makeHeader() -> Header
    func makeTabBar() -> TabBar
    func makeResizeHandle() -> ResizeHandle
    func makeDropZone() -> DropZone
    func makeFloatingPanel() -> FloatingPanel
    func makeDragPreview() -> DragPreview
}

/// Protocol defining colors, typography, spacing, and visual properties
public protocol DockPalette {
    init()
    var colors: DockColorScheme { get }
    var typography: DockTypography { get }
    var spacing: DockSpacing { get }
    var borders: DockBorders { get }
    var shadows: DockShadows { get }
    var animations: DockAnimations { get }
    var cornerRadii: DockCornerRadii { get }
}

// MARK: - Style Protocols

/// Protocol for panel header styling
public protocol DockHeaderStyle {
    associatedtype Body: View
    func makeBody(configuration: DockHeaderConfiguration) -> Body
}

/// Protocol for tab bar styling
public protocol DockTabBarStyle {
    associatedtype Body: View
    func makeBody(configuration: DockTabBarConfiguration) -> Body
}

/// Protocol for resize handle styling
public protocol DockResizeHandleStyle {
    associatedtype Body: View
    func makeBody(configuration: DockResizeHandleConfiguration) -> Body
}

/// Protocol for drop zone styling
public protocol DockDropZoneStyle {
    associatedtype Body: View
    func makeBody(configuration: DockDropZoneConfiguration) -> Body
}

/// Protocol for floating panel styling
public protocol DockFloatingPanelStyle {
    associatedtype Body: View
    func makeBody(configuration: DockFloatingPanelConfiguration) -> Body
}

/// Protocol for drag preview styling
public protocol DockDragPreviewStyle {
    associatedtype Body: View
    func makeBody(configuration: DockDragPreviewConfiguration) -> Body
}

// MARK: - Configuration Objects

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

public struct DockResizeHandleConfiguration {
    public let orientation: DockSplitOrientation
    public let isHovered: Bool
    public let isDragging: Bool
    public let position: DockPosition
}

public struct DockDropZoneConfiguration {
    public let dropZone: DockDropZone
    public let isActive: Bool
    public let containerSize: CGSize
}

public struct DockFloatingPanelConfiguration {
    public let title: String
    public let icon: String?
    public let isActive: Bool
    public let hasMultipleTabs: Bool
    public let tabs: [DockTabItem]
    public let activeTabIndex: Int
    public let size: CGSize
    public let content: AnyView
    
    // Actions
    public let onClose: () -> Void
    public let onMinimize: () -> Void
    public let onMaximize: () -> Void
    public let onDock: () -> Void
    public let onTabSelect: (Int) -> Void
    public let onTabClose: (Int) -> Void
}

public struct DockDragPreviewConfiguration {
    public let title: String
    public let icon: String?
    public let location: CGPoint
}

// MARK: - Composable Theme

/// A theme composed of a style class and palette
public struct ComposableDockTheme<Style: DockStyleClass, Palette: DockPalette>: DockThemeProtocol {
    public let styleClass: Style
    public let palette: Palette
    
    public init(styleClass: Style, palette: Palette) {
        self.styleClass = styleClass
        self.palette = palette
    }
    
    // MARK: - Theme Protocol Implementation
    
    public var colors: DockColorScheme { palette.colors }
    public var typography: DockTypography { palette.typography }
    public var spacing: DockSpacing { palette.spacing }
    public var borders: DockBorders { palette.borders }
    public var shadows: DockShadows { palette.shadows }
    public var animations: DockAnimations { palette.animations }
    public var cornerRadii: DockCornerRadii { palette.cornerRadii }
    
    // MARK: - Style Accessors
    
    public var headerStyle: any DockHeaderStyle { styleClass.makeHeader() }
    public var tabBarStyle: any DockTabBarStyle { styleClass.makeTabBar() }
    public var resizeHandleStyle: any DockResizeHandleStyle { styleClass.makeResizeHandle() }
    public var dropZoneStyle: any DockDropZoneStyle { styleClass.makeDropZone() }
    public var floatingPanelStyle: any DockFloatingPanelStyle { styleClass.makeFloatingPanel() }
    public var dragPreviewStyle: any DockDragPreviewStyle { styleClass.makeDragPreview() }
}

// MARK: - Environment Keys

public struct DockThemeKey: EnvironmentKey {
    public static let defaultValue: DockThemeProtocol = DefaultDockTheme()
}

public extension EnvironmentValues {
    var dockTheme: DockThemeProtocol {
        get { self[DockThemeKey.self] }
        set { self[DockThemeKey.self] = newValue }
    }
}

public struct DockHeaderStyleKey: EnvironmentKey {
    public static let defaultValue: any DockHeaderStyle = DefaultDockHeaderStyle()
}

public extension EnvironmentValues {
    var dockHeaderStyle: any DockHeaderStyle {
        get { self[DockHeaderStyleKey.self] }
        set { self[DockHeaderStyleKey.self] = newValue }
    }
}

public struct DockTabBarStyleKey: EnvironmentKey {
    public static let defaultValue: any DockTabBarStyle = DefaultDockTabBarStyle()
}

public extension EnvironmentValues {
    var dockTabBarStyle: any DockTabBarStyle {
        get { self[DockTabBarStyleKey.self] }
        set { self[DockTabBarStyleKey.self] = newValue }
    }
}

public struct DockResizeHandleStyleKey: EnvironmentKey {
    public static let defaultValue: any DockResizeHandleStyle = DefaultDockResizeHandleStyle()
}

public extension EnvironmentValues {
    var dockResizeHandleStyle: any DockResizeHandleStyle {
        get { self[DockResizeHandleStyleKey.self] }
        set { self[DockResizeHandleStyleKey.self] = newValue }
    }
}

public struct DockDropZoneStyleKey: EnvironmentKey {
    public static let defaultValue: any DockDropZoneStyle = DefaultDockDropZoneStyle()
}

public extension EnvironmentValues {
    var dockDropZoneStyle: any DockDropZoneStyle {
        get { self[DockDropZoneStyleKey.self] }
        set { self[DockDropZoneStyleKey.self] = newValue }
    }
}

public struct DockFloatingPanelStyleKey: EnvironmentKey {
    public static let defaultValue: any DockFloatingPanelStyle = DefaultFloatingPanelStyle()
}

public extension EnvironmentValues {
    var dockFloatingPanelStyle: any DockFloatingPanelStyle {
        get { self[DockFloatingPanelStyleKey.self] }
        set { self[DockFloatingPanelStyleKey.self] = newValue }
    }
}

public struct DockDragPreviewStyleKey: EnvironmentKey {
    public static let defaultValue: any DockDragPreviewStyle = DefaultDragPreviewStyle()
}

public extension EnvironmentValues {
    var dockDragPreviewStyle: any DockDragPreviewStyle {
        get { self[DockDragPreviewStyleKey.self] }
        set { self[DockDragPreviewStyleKey.self] = newValue }
    }
}
