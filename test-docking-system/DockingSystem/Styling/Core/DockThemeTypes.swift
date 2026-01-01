import SwiftUI

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
        dropZoneHighlight: Color = Color.accentColor.opacity(0.4),
        dropZoneBackground: Color = Color.accentColor.opacity(0.15),
        resizeHandle: Color = Color.accentColor,
        tabBackground: Color = Color(uiColor: .secondarySystemBackground),
        activeTabBackground: Color = Color(uiColor: .systemBackground),
        hoverBackground: Color = Color(uiColor: .tertiarySystemBackground),
        shadowColor: Color = Color(red: 0, green: 0, blue: 0).opacity(0.1)
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
    public var iconSize: CGFloat
    
    public init(
        headerFont: Font = .system(size: 13),
        headerFontWeight: Font.Weight = .medium,
        tabFont: Font = .system(size: 12),
        tabFontWeight: Font.Weight = .regular,
        iconSize: CGFloat = 14
    ) {
        self.headerFont = headerFont
        self.headerFontWeight = headerFontWeight
        self.tabFont = tabFont
        self.tabFontWeight = tabFontWeight
        self.iconSize = iconSize
    }
}

// MARK: - Spacing

public struct DockSpacing {
    public var headerPadding: CGFloat
    public var tabPadding: CGFloat
    public var resizeHandleSize: CGFloat
    public var panelPadding: CGFloat
    public var collapsedWidth: CGFloat
    public var minPanelSize: CGFloat
    public var dropZoneMargin: CGFloat
    
    public init(
        headerPadding: CGFloat = 12,
        tabPadding: CGFloat = 8,
        resizeHandleSize: CGFloat = 4,
        panelPadding: CGFloat = 16,
        collapsedWidth: CGFloat = 44,
        minPanelSize: CGFloat = 200,
        dropZoneMargin: CGFloat = 80
    ) {
        self.headerPadding = headerPadding
        self.tabPadding = tabPadding
        self.resizeHandleSize = resizeHandleSize
        self.panelPadding = panelPadding
        self.collapsedWidth = collapsedWidth
        self.minPanelSize = minPanelSize
        self.dropZoneMargin = dropZoneMargin
    }
}

// MARK: - Borders

public struct DockBorders {
    public var separatorWidth: CGFloat
    public var borderWidth: CGFloat
    public var activeBorderWidth: CGFloat
    
    public init(
        separatorWidth: CGFloat = 1,
        borderWidth: CGFloat = 1,
        activeBorderWidth: CGFloat = 2
    ) {
        self.separatorWidth = separatorWidth
        self.borderWidth = borderWidth
        self.activeBorderWidth = activeBorderWidth
    }
}

// MARK: - Shadows

public struct DockShadows {
    public var panelShadowRadius: CGFloat
    public var panelShadowOffset: CGSize
    public var panelShadowOpacity: Double
    public var floatingShadowRadius: CGFloat
    public var floatingShadowOffset: CGSize
    public var floatingShadowOpacity: Double
    
    public init(
        panelShadowRadius: CGFloat = 8,
        panelShadowOffset: CGSize = CGSize(width: 0, height: 2),
        panelShadowOpacity: Double = 0.15,
        floatingShadowRadius: CGFloat = 16,
        floatingShadowOffset: CGSize = CGSize(width: 0, height: 8),
        floatingShadowOpacity: Double = 0.25
    ) {
        self.panelShadowRadius = panelShadowRadius
        self.panelShadowOffset = panelShadowOffset
        self.panelShadowOpacity = panelShadowOpacity
        self.floatingShadowRadius = floatingShadowRadius
        self.floatingShadowOffset = floatingShadowOffset
        self.floatingShadowOpacity = floatingShadowOpacity
    }
}

// MARK: - Animations

public struct DockAnimations {
    public var defaultDuration: Double
    public var quickDuration: Double
    public var slowDuration: Double
    public var springResponse: Double
    public var springDampingFraction: Double
    
    public init(
        defaultDuration: Double = 0.25,
        quickDuration: Double = 0.15,
        slowDuration: Double = 0.4,
        springResponse: Double = 0.3,
        springDampingFraction: Double = 0.8
    ) {
        self.defaultDuration = defaultDuration
        self.quickDuration = quickDuration
        self.slowDuration = slowDuration
        self.springResponse = springResponse
        self.springDampingFraction = springDampingFraction
    }
    
    public var quickAnimation: Animation {
        .easeInOut(duration: quickDuration)
    }
    
    public var defaultAnimation: Animation {
        .easeInOut(duration: defaultDuration)
    }
    
    public var slowAnimation: Animation {
        .easeInOut(duration: slowDuration)
    }
    
    public var springAnimation: Animation {
        .spring(response: springResponse, dampingFraction: springDampingFraction)
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
        header: CGFloat = 8,
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
