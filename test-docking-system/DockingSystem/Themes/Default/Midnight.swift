import SwiftUI

// MARK: - Midnight Dark Palette

public struct Midnight: DockPalette {
    public let colors: DockColorScheme
    public let typography: DockTypography
    public let spacing: DockSpacing
    public let borders: DockBorders
    public let shadows: DockShadows
    public let animations: DockAnimations
    public let cornerRadii: DockCornerRadii
    
    public init() {
        self.colors = DockColorScheme(
            background: Color(hex: 0x1E1E1E),           // VS Code dark background
            secondaryBackground: Color(hex: 0x252526),  // Side bar
            tertiaryBackground: Color(hex: 0x333333),   // Activity bar
            panelBackground: Color(hex: 0x1E1E1E),      // Panel background
            headerBackground: Color(hex: 0x252526),     // Header
            activeHeaderBackground: Color(hex: 0x37373D), // Active header
            separator: Color(hex: 0x3C3C3C),            // Separator
            border: Color(hex: 0x3C3C3C),               // Borders
            activeBorder: Color(hex: 0x007ACC),         // Focus border (blue)
            text: Color(hex: 0xCCCCCC),                 // Main text
            secondaryText: Color(hex: 0x8C8C8C),        // Secondary text
            tertiaryText: Color(hex: 0x5A5A5A),         // Disabled text
            accent: Color(hex: 0x007ACC),               // Blue accent
            accentSecondary: Color(hex: 0x0098FF),      // Lighter accent
            dropZoneHighlight: Color(hex: 0x007ACC),    // Drop zone
            dropZoneBackground: Color(hex: 0x007ACC).opacity(0.2),
            resizeHandle: Color.clear,                  // Invisible handle area
            tabBackground: Color(hex: 0x2D2D2D),        // Inactive tab
            activeTabBackground: Color(hex: 0x1E1E1E),  // Active tab
            hoverBackground: Color(hex: 0x2A2D2E),      // List hover
            shadowColor: Color.black.opacity(0.3)
        )
        
        self.typography = DockTypography(
            headerFont: .system(size: 11, weight: .semibold),
            headerFontWeight: .semibold,
            tabFont: .system(size: 12, weight: .regular),
            tabFontWeight: .regular,
            iconSize: 14
        )
        
        self.spacing = DockSpacing(
            headerPadding: 8,
            tabPadding: 10,
            resizeHandleSize: 4,
            panelPadding: 0,
            collapsedWidth: 48,
            minPanelSize: 150,
            dropZoneMargin: 40
        )
        
        self.borders = DockBorders(
            separatorWidth: 1,
            borderWidth: 1,
            activeBorderWidth: 1
        )
        
        self.shadows = DockShadows(
            panelShadowRadius: 0,
            panelShadowOffset: .zero,
            panelShadowOpacity: 0,
            floatingShadowRadius: 12,
            floatingShadowOffset: CGSize(width: 0, height: 6),
            floatingShadowOpacity: 0.4
        )
        
        self.animations = DockAnimations(
            defaultDuration: 0.2,
            quickDuration: 0.1,
            slowDuration: 0.3,
            springResponse: 0.35,
            springDampingFraction: 0.85
        )
        
        self.cornerRadii = DockCornerRadii(
            panel: 0,
            header: 0,
            tab: 0,
            button: 4,
            dropZone: 0,
            floating: 6
        )
    }
}
