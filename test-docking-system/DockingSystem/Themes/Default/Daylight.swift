import SwiftUI

// MARK: - Daylight Light Palette

public struct Daylight: DockPalette {
    public let colors: DockColorScheme
    public let typography: DockTypography
    public let spacing: DockSpacing
    public let borders: DockBorders
    public let shadows: DockShadows
    public let animations: DockAnimations
    public let cornerRadii: DockCornerRadii
    
    public init() {
        // VS Code-inspired Light Theme
        self.colors = DockColorScheme(
            background: Color(hex: 0xFFFFFF),           // Editor background
            secondaryBackground: Color(hex: 0xF3F3F3),  // Side bar background
            tertiaryBackground: Color(hex: 0x2C2C2C),   // Activity bar (Dark in light theme usually)
            panelBackground: Color(hex: 0xFFFFFF),      // Panel background
            headerBackground: Color(hex: 0xF3F3F3),     // Header background
            activeHeaderBackground: Color(hex: 0xE4E6F1), // Active header
            separator: Color(hex: 0xE5E5E5),            // Split view separator
            border: Color(hex: 0xE5E5E5),               // Borders
            activeBorder: Color(hex: 0x0090F1),         // Focus border
            text: Color(hex: 0x333333),                 // Main text
            secondaryText: Color(hex: 0x616161),        // Secondary text
            tertiaryText: Color(hex: 0xAAAAAA),         // Disabled/Dimmed
            accent: Color(hex: 0x0090F1),               // Blue accent
            accentSecondary: Color(hex: 0x007ACC),      // Darker accent
            dropZoneHighlight: Color(hex: 0x0090F1),    // Drop zone
            dropZoneBackground: Color(hex: 0x0090F1).opacity(0.2),
            resizeHandle: Color.clear,                  // Invisible handle area
            tabBackground: Color(hex: 0xECECEC),        // Inactive tab
            activeTabBackground: Color(hex: 0xFFFFFF),  // Active tab
            hoverBackground: Color(hex: 0xE8E8E8),      // List hover
            shadowColor: Color.black.opacity(0.1)
        )
        
        // Activity bar text needs to be light since background is dark
        // This is a limitation of the current palette structure, assuming one text color fits all backgrounds.
        // We will stick to standard mapping for now.
        
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
            floatingShadowRadius: 8,
            floatingShadowOffset: CGSize(width: 0, height: 4),
            floatingShadowOpacity: 0.15
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
