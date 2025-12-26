import SwiftUI

// MARK: - Theme Protocol

/// Protocol defining a complete dock theme
public protocol DockThemeProtocol {
    var colors: DockColorScheme { get }
    var typography: DockTypography { get }
    var spacing: DockSpacing { get }
    var borders: DockBorders { get }
    var shadows: DockShadows { get }
    var animations: DockAnimations { get }
    var cornerRadii: DockCornerRadii { get }
}

// MARK: - Color Scheme

public struct DockColorScheme {
    public var background: Color
    public var secondaryBackground: Color
    public var tertiaryBackground: Color
    public var panelBackground: Color
    public var headerBackground: Color
    public var activeHeaderBackground: Color
    public var separator: Color
    public var border: Color
    public var activeBorder: Color
    public var text: Color
    public var secondaryText: Color
    public var tertiaryText: Color
    public var accent: Color
    public var accentSecondary: Color
    public var dropZoneHighlight: Color
    public var dropZoneBackground: Color
    public var resizeHandle: Color
    public var tabBackground: Color
    public var activeTabBackground: Color
    public var hoverBackground: Color
    public var shadowColor: Color
    
    public init(
        background: Color = Color(uiColor: .systemBackground),
        secondaryBackground: Color = Color(uiColor: .secondarySystemBackground),
        tertiaryBackground: Color = Color(uiColor: .tertiarySystemBackground),
        panelBackground: Color = Color(uiColor: .systemBackground),
        headerBackground: Color = Color(uiColor: .secondarySystemBackground),
        activeHeaderBackground: Color = Color.accentColor.opacity(0.15),
        separator: Color = Color(uiColor: .separator),
        border: Color = Color(uiColor: .separator),
        activeBorder: Color = Color.accentColor,
        text: Color = Color(uiColor: .label),
        secondaryText: Color = Color(uiColor: .secondaryLabel),
        tertiaryText: Color = Color(uiColor: .tertiaryLabel),
        accent: Color = Color.accentColor,
        accentSecondary: Color = Color.accentColor.opacity(0.7),
        dropZoneHighlight: Color = Color.accentColor.opacity(0.3),
        dropZoneBackground: Color = Color.accentColor.opacity(0.1),
        resizeHandle: Color = Color(uiColor: .separator),
        tabBackground: Color = Color(uiColor: .tertiarySystemBackground),
        activeTabBackground: Color = Color(uiColor: .systemBackground),
        hoverBackground: Color = Color(uiColor: .systemGray5),
        shadowColor: Color = Color.black.opacity(0.15)
    ) {
        self.background = background
        self.secondaryBackground = secondaryBackground
        self.tertiaryBackground = tertiaryBackground
        self.panelBackground = panelBackground
        self.headerBackground = headerBackground
        self.activeHeaderBackground = activeHeaderBackground
        self.separator = separator
        self.border = border
        self.activeBorder = activeBorder
        self.text = text
        self.secondaryText = secondaryText
        self.tertiaryText = tertiaryText
        self.accent = accent
        self.accentSecondary = accentSecondary
        self.dropZoneHighlight = dropZoneHighlight
        self.dropZoneBackground = dropZoneBackground
        self.resizeHandle = resizeHandle
        self.tabBackground = tabBackground
        self.activeTabBackground = activeTabBackground
        self.hoverBackground = hoverBackground
        self.shadowColor = shadowColor
    }
}

// MARK: - Typography

public struct DockTypography {
    public var headerFont: Font
    public var headerFontWeight: Font.Weight
    public var tabFont: Font
    public var tabFontWeight: Font.Weight
    public var bodyFont: Font
    public var captionFont: Font
    public var iconSize: CGFloat
    public var smallIconSize: CGFloat
    
    public init(
        headerFont: Font = .system(size: 13),
        headerFontWeight: Font.Weight = .semibold,
        tabFont: Font = .system(size: 12),
        tabFontWeight: Font.Weight = .medium,
        bodyFont: Font = .system(size: 14),
        captionFont: Font = .system(size: 11),
        iconSize: CGFloat = 16,
        smallIconSize: CGFloat = 12
    ) {
        self.headerFont = headerFont
        self.headerFontWeight = headerFontWeight
        self.tabFont = tabFont
        self.tabFontWeight = tabFontWeight
        self.bodyFont = bodyFont
        self.captionFont = captionFont
        self.iconSize = iconSize
        self.smallIconSize = smallIconSize
    }
}

// MARK: - Spacing

public struct DockSpacing {
    public var panelPadding: CGFloat
    public var headerPadding: CGFloat
    public var tabPadding: CGFloat
    public var contentPadding: CGFloat
    public var itemSpacing: CGFloat
    public var sectionSpacing: CGFloat
    public var resizeHandleSize: CGFloat
    public var minimizedBarHeight: CGFloat
    public var collapsedWidth: CGFloat
    
    public init(
        panelPadding: CGFloat = 0,
        headerPadding: CGFloat = 8,
        tabPadding: CGFloat = 8,
        contentPadding: CGFloat = 12,
        itemSpacing: CGFloat = 4,
        sectionSpacing: CGFloat = 8,
        resizeHandleSize: CGFloat = 6,
        minimizedBarHeight: CGFloat = 44,
        collapsedWidth: CGFloat = 44
    ) {
        self.panelPadding = panelPadding
        self.headerPadding = headerPadding
        self.tabPadding = tabPadding
        self.contentPadding = contentPadding
        self.itemSpacing = itemSpacing
        self.sectionSpacing = sectionSpacing
        self.resizeHandleSize = resizeHandleSize
        self.minimizedBarHeight = minimizedBarHeight
        self.collapsedWidth = collapsedWidth
    }
}

// MARK: - Borders

public struct DockBorders {
    public var panelBorderWidth: CGFloat
    public var activeBorderWidth: CGFloat
    public var separatorWidth: CGFloat
    public var dropZoneBorderWidth: CGFloat
    
    public init(
        panelBorderWidth: CGFloat = 1,
        activeBorderWidth: CGFloat = 2,
        separatorWidth: CGFloat = 1,
        dropZoneBorderWidth: CGFloat = 2
    ) {
        self.panelBorderWidth = panelBorderWidth
        self.activeBorderWidth = activeBorderWidth
        self.separatorWidth = separatorWidth
        self.dropZoneBorderWidth = dropZoneBorderWidth
    }
}

// MARK: - Shadows

public struct DockShadows {
    public var panelShadowRadius: CGFloat
    public var floatingShadowRadius: CGFloat
    public var dropShadowRadius: CGFloat
    public var panelShadowOffset: CGSize
    public var floatingShadowOffset: CGSize
    
    public init(
        panelShadowRadius: CGFloat = 2,
        floatingShadowRadius: CGFloat = 12,
        dropShadowRadius: CGFloat = 8,
        panelShadowOffset: CGSize = CGSize(width: 0, height: 1),
        floatingShadowOffset: CGSize = CGSize(width: 0, height: 4)
    ) {
        self.panelShadowRadius = panelShadowRadius
        self.floatingShadowRadius = floatingShadowRadius
        self.dropShadowRadius = dropShadowRadius
        self.panelShadowOffset = panelShadowOffset
        self.floatingShadowOffset = floatingShadowOffset
    }
}

// MARK: - Animations

public struct DockAnimations {
    public var defaultDuration: Double
    public var quickDuration: Double
    public var springResponse: Double
    public var springDamping: Double
    
    public var defaultAnimation: Animation {
        .easeInOut(duration: defaultDuration)
    }
    
    public var quickAnimation: Animation {
        .easeInOut(duration: quickDuration)
    }
    
    public var springAnimation: Animation {
        .spring(response: springResponse, dampingFraction: springDamping)
    }
    
    public init(
        defaultDuration: Double = 0.25,
        quickDuration: Double = 0.15,
        springResponse: Double = 0.3,
        springDamping: Double = 0.8
    ) {
        self.defaultDuration = defaultDuration
        self.quickDuration = quickDuration
        self.springResponse = springResponse
        self.springDamping = springDamping
    }
}

// MARK: - Corner Radii

public struct DockCornerRadii {
    public var panel: CGFloat
    public var header: CGFloat
    public var tab: CGFloat
    public var button: CGFloat
    public var dropZone: CGFloat
    public var floating: CGFloat
    
    public init(
        panel: CGFloat = 8,
        header: CGFloat = 0,
        tab: CGFloat = 6,
        button: CGFloat = 4,
        dropZone: CGFloat = 8,
        floating: CGFloat = 12
    ) {
        self.panel = panel
        self.header = header
        self.tab = tab
        self.button = button
        self.dropZone = dropZone
        self.floating = floating
    }
}

// MARK: - Default Theme

public struct DefaultDockTheme: DockThemeProtocol {
    public var colors: DockColorScheme
    public var typography: DockTypography
    public var spacing: DockSpacing
    public var borders: DockBorders
    public var shadows: DockShadows
    public var animations: DockAnimations
    public var cornerRadii: DockCornerRadii
    
    public init(
        colors: DockColorScheme = DockColorScheme(),
        typography: DockTypography = DockTypography(),
        spacing: DockSpacing = DockSpacing(),
        borders: DockBorders = DockBorders(),
        shadows: DockShadows = DockShadows(),
        animations: DockAnimations = DockAnimations(),
        cornerRadii: DockCornerRadii = DockCornerRadii()
    ) {
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.borders = borders
        self.shadows = shadows
        self.animations = animations
        self.cornerRadii = cornerRadii
    }
}

// MARK: - Dark Theme

public struct DarkDockTheme: DockThemeProtocol {
    public var colors: DockColorScheme
    public var typography: DockTypography
    public var spacing: DockSpacing
    public var borders: DockBorders
    public var shadows: DockShadows
    public var animations: DockAnimations
    public var cornerRadii: DockCornerRadii
    
    public init() {
        self.colors = DockColorScheme(
            background: Color(white: 0.1),
            secondaryBackground: Color(white: 0.15),
            tertiaryBackground: Color(white: 0.2),
            panelBackground: Color(white: 0.12),
            headerBackground: Color(white: 0.18),
            activeHeaderBackground: Color.blue.opacity(0.2),
            separator: Color(white: 0.25),
            border: Color(white: 0.25),
            activeBorder: Color.blue,
            text: Color.white,
            secondaryText: Color(white: 0.7),
            tertiaryText: Color(white: 0.5),
            accent: Color.blue,
            accentSecondary: Color.blue.opacity(0.7),
            dropZoneHighlight: Color.blue.opacity(0.4),
            dropZoneBackground: Color.blue.opacity(0.15),
            resizeHandle: Color(white: 0.3),
            tabBackground: Color(white: 0.15),
            activeTabBackground: Color(white: 0.22),
            hoverBackground: Color(white: 0.25),
            shadowColor: Color.black.opacity(0.4)
        )
        self.typography = DockTypography()
        self.spacing = DockSpacing()
        self.borders = DockBorders()
        self.shadows = DockShadows(
            panelShadowRadius: 3,
            floatingShadowRadius: 16,
            dropShadowRadius: 10
        )
        self.animations = DockAnimations()
        self.cornerRadii = DockCornerRadii()
    }
}

// MARK: - Xcode-Style Theme

public struct XcodeDockTheme: DockThemeProtocol {
    public var colors: DockColorScheme
    public var typography: DockTypography
    public var spacing: DockSpacing
    public var borders: DockBorders
    public var shadows: DockShadows
    public var animations: DockAnimations
    public var cornerRadii: DockCornerRadii
    
    public init() {
        self.colors = DockColorScheme(
            background: Color(red: 0.14, green: 0.14, blue: 0.16),
            secondaryBackground: Color(red: 0.18, green: 0.18, blue: 0.20),
            tertiaryBackground: Color(red: 0.22, green: 0.22, blue: 0.24),
            panelBackground: Color(red: 0.14, green: 0.14, blue: 0.16),
            headerBackground: Color(red: 0.20, green: 0.20, blue: 0.22),
            activeHeaderBackground: Color(red: 0.25, green: 0.25, blue: 0.28),
            separator: Color(red: 0.28, green: 0.28, blue: 0.30),
            border: Color(red: 0.28, green: 0.28, blue: 0.30),
            activeBorder: Color(red: 0.35, green: 0.55, blue: 0.95),
            text: Color.white,
            secondaryText: Color(white: 0.65),
            tertiaryText: Color(white: 0.45),
            accent: Color(red: 0.35, green: 0.55, blue: 0.95),
            accentSecondary: Color(red: 0.35, green: 0.55, blue: 0.95).opacity(0.7),
            dropZoneHighlight: Color(red: 0.35, green: 0.55, blue: 0.95).opacity(0.35),
            dropZoneBackground: Color(red: 0.35, green: 0.55, blue: 0.95).opacity(0.12),
            resizeHandle: Color(red: 0.35, green: 0.35, blue: 0.38),
            tabBackground: Color(red: 0.18, green: 0.18, blue: 0.20),
            activeTabBackground: Color(red: 0.26, green: 0.26, blue: 0.28),
            hoverBackground: Color(red: 0.28, green: 0.28, blue: 0.30),
            shadowColor: Color.black.opacity(0.5)
        )
        self.typography = DockTypography(
            headerFont: .system(size: 12),
            headerFontWeight: .medium,
            tabFont: .system(size: 11),
            tabFontWeight: .regular
        )
        self.spacing = DockSpacing(
            headerPadding: 6,
            tabPadding: 6,
            resizeHandleSize: 5
        )
        self.borders = DockBorders(
            panelBorderWidth: 0.5
        )
        self.shadows = DockShadows(
            panelShadowRadius: 0,
            floatingShadowRadius: 20
        )
        self.animations = DockAnimations(
            springResponse: 0.25,
            springDamping: 0.85
        )
        self.cornerRadii = DockCornerRadii(
            panel: 0,
            header: 0,
            tab: 4,
            button: 3,
            dropZone: 4,
            floating: 8
        )
    }
}

// MARK: - VS Code-Style Theme

public struct VSCodeDockTheme: DockThemeProtocol {
    public var colors: DockColorScheme
    public var typography: DockTypography
    public var spacing: DockSpacing
    public var borders: DockBorders
    public var shadows: DockShadows
    public var animations: DockAnimations
    public var cornerRadii: DockCornerRadii
    
    public init() {
        self.colors = DockColorScheme(
            background: Color(red: 0.12, green: 0.12, blue: 0.12),
            secondaryBackground: Color(red: 0.15, green: 0.15, blue: 0.15),
            tertiaryBackground: Color(red: 0.18, green: 0.18, blue: 0.18),
            panelBackground: Color(red: 0.12, green: 0.12, blue: 0.12),
            headerBackground: Color(red: 0.15, green: 0.15, blue: 0.15),
            activeHeaderBackground: Color(red: 0.18, green: 0.18, blue: 0.18),
            separator: Color(red: 0.22, green: 0.22, blue: 0.22),
            border: Color(red: 0.22, green: 0.22, blue: 0.22),
            activeBorder: Color(red: 0.0, green: 0.48, blue: 0.80),
            text: Color(red: 0.85, green: 0.85, blue: 0.85),
            secondaryText: Color(red: 0.60, green: 0.60, blue: 0.60),
            tertiaryText: Color(red: 0.45, green: 0.45, blue: 0.45),
            accent: Color(red: 0.0, green: 0.48, blue: 0.80),
            accentSecondary: Color(red: 0.0, green: 0.48, blue: 0.80).opacity(0.7),
            dropZoneHighlight: Color(red: 0.0, green: 0.48, blue: 0.80).opacity(0.4),
            dropZoneBackground: Color(red: 0.0, green: 0.48, blue: 0.80).opacity(0.15),
            resizeHandle: Color(red: 0.0, green: 0.48, blue: 0.80),
            tabBackground: Color(red: 0.15, green: 0.15, blue: 0.15),
            activeTabBackground: Color(red: 0.12, green: 0.12, blue: 0.12),
            hoverBackground: Color(red: 0.20, green: 0.20, blue: 0.20),
            shadowColor: Color.black.opacity(0.6)
        )
        self.typography = DockTypography(
            headerFont: .system(size: 11),
            headerFontWeight: .regular,
            tabFont: .system(size: 13),
            tabFontWeight: .regular
        )
        self.spacing = DockSpacing(
            headerPadding: 10,
            tabPadding: 10,
            resizeHandleSize: 4
        )
        self.borders = DockBorders()
        self.shadows = DockShadows(
            panelShadowRadius: 0
        )
        self.animations = DockAnimations(
            defaultDuration: 0.15,
            quickDuration: 0.1
        )
        self.cornerRadii = DockCornerRadii(
            panel: 0,
            header: 0,
            tab: 0,
            button: 2,
            dropZone: 0,
            floating: 6
        )
    }
}

// MARK: - Theme Environment Key

public struct DockThemeKey: EnvironmentKey {
    public static let defaultValue: any DockThemeProtocol = DefaultDockTheme()
}

extension EnvironmentValues {
    public var dockTheme: any DockThemeProtocol {
        get { self[DockThemeKey.self] }
        set { self[DockThemeKey.self] = newValue }
    }
}

// MARK: - View Modifier

public struct DockThemeModifier: ViewModifier {
    let theme: any DockThemeProtocol
    
    public func body(content: Content) -> some View {
        content.environment(\.dockTheme, theme)
    }
}

extension View {
    public func dockTheme(_ theme: any DockThemeProtocol) -> some View {
        modifier(DockThemeModifier(theme: theme))
    }
}
