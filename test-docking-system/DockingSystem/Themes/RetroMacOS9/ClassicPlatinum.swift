import SwiftUI

// MARK: - Classic Platinum Palette

public struct ClassicPlatinum: DockPalette {
    public let colors: DockColorScheme
    public let typography: DockTypography
    public let spacing: DockSpacing
    public let borders: DockBorders
    public let shadows: DockShadows
    public let animations: DockAnimations
    public let cornerRadii: DockCornerRadii
    
    public init() {
        self.colors = DockColorScheme(
            background: Color(hex: 0xD8D8D8),      // Platinum background
            secondaryBackground: Color(hex: 0xC7C7C7), // Darker platinum
            tertiaryBackground: Color(hex: 0xA5A5A5),  // Even darker
            panelBackground: Color(hex: 0xE3E3E3),     // Light platinum
            headerBackground: Color(hex: 0xCFCFCF),     // Header platinum
            activeHeaderBackground: Color(hex: 0xD6D6D6), // Active header fallback
            separator: Color(hex: 0x7D7D7D),            // Dark separator
            border: Color(hex: 0x8A8A8A),               // Border color
            activeBorder: Color(hex: 0x1B53D7),           // Classic Mac blue
            text: Color(hex: 0x000000),                   // Black text
            secondaryText: Color(hex: 0x1E1E1E),          // Dark gray
            tertiaryText: Color(hex: 0x4A4A4A),           // Medium gray
            accent: Color(hex: 0x1B53D7),                // Classic Mac blue
            accentSecondary: Color(hex: 0x4B7BEA),       // Lighter blue
            dropZoneHighlight: Color(hex: 0x1B53D7),     // Blue highlight
            dropZoneBackground: Color(hex: 0x1B53D7, opacity: 0.14), // Very light blue
            resizeHandle: Color(hex: 0x8D8D8D),          // Gray resize handle
            tabBackground: Color(hex: 0xCFCFCF),       // Tab background
            activeTabBackground: Color(hex: 0xE6E6E6),  // Active tab
            hoverBackground: Color(hex: 0xBEBEBE),     // Hover state
            shadowColor: Color.black.opacity(0.25)                           // Classic shadows
        )
        
        self.typography = DockTypography(
            headerFont: .system(size: 12, weight: .semibold, design: .default), // Chicago-style
            headerFontWeight: .semibold,
            tabFont: .system(size: 11, weight: .medium, design: .default),      // Geneva-style
            tabFontWeight: .medium,
            iconSize: 12
        )
        
        self.spacing = DockSpacing(
            headerPadding: 6,        // Compact padding
            tabPadding: 6,           // Tight tab padding
            resizeHandleSize: 4,     // Slightly thicker handles
            panelPadding: 10,        // Standard panel padding
            collapsedWidth: 42,      // Classic collapsed width
            minPanelSize: 140,       // Smaller minimum size
            dropZoneMargin: 56       // Smaller drop zone margin
        )
        
        self.borders = DockBorders(
            separatorWidth: 1,       // Thin separators
            borderWidth: 1,          // Thin borders
            activeBorderWidth: 2      // Slightly thicker active border
        )
        
        self.shadows = DockShadows(
            panelShadowRadius: 1.5,    // Subtle shadows
            panelShadowOffset: CGSize(width: 0, height: 1),
            panelShadowOpacity: 0.2,
            floatingShadowRadius: 6,  // Slightly larger for floating
            floatingShadowOffset: CGSize(width: 0, height: 3),
            floatingShadowOpacity: 0.28
        )
        
        self.animations = DockAnimations(
            defaultDuration: 0.15,   // Quick animations
            quickDuration: 0.1,
            slowDuration: 0.25,
            springResponse: 0.2,
            springDampingFraction: 0.9
        )
        
        self.cornerRadii = DockCornerRadii(
            panel: 0,                // No rounded corners (classic Mac)
            header: 0,               // Sharp corners
            tab: 0,                  // Square tabs
            button: 0,               // Square buttons
            dropZone: 0,             // Square drop zones
            floating: 2               // Minimal rounding for floating
        )
    }
}
