import SwiftUI

// MARK: - Blue Grape Palette

public struct BlueGrape: DockPalette {
    public let colors: DockColorScheme
    public let typography: DockTypography
    public let spacing: DockSpacing
    public let borders: DockBorders
    public let shadows: DockShadows
    public let animations: DockAnimations
    public let cornerRadii: DockCornerRadii
    
    public init() {
        self.colors = DockColorScheme(
            background: Color(hex: 0x2C2E82),           // Deep blue grape
            secondaryBackground: Color(hex: 0x3C3E97),  // Lighter blue
            tertiaryBackground: Color(hex: 0x4D4FB2),   // Even lighter blue
            panelBackground: Color(hex: 0x34368B),    // Panel blue
            headerBackground: Color(hex: 0x3A3D97),      // Header blue
            activeHeaderBackground: Color(hex: 0x4A4FB0), // Active header
            separator: Color(hex: 0x5B4A9E),            // Grape separator
            border: Color(hex: 0x4E4A99),               // Grape border
            activeBorder: Color(hex: 0xF4C44D),         // Yellow accent
            text: Color(hex: 0xFFFFFF),               // White text
            secondaryText: Color(hex: 0xD6D7F4),          // Light blue text
            tertiaryText: Color(hex: 0xAEB0E6),           // Medium blue text
            accent: Color(hex: 0xF4C44D),                // Yellow accent
            accentSecondary: Color(hex: 0xF8D87A),       // Lighter yellow
            dropZoneHighlight: Color(hex: 0xF4C44D),     // Yellow highlight
            dropZoneBackground: Color(hex: 0xF4C44D, opacity: 0.18), // Light yellow
            resizeHandle: Color(hex: 0x7A72D2),          // Light grape
            tabBackground: Color(hex: 0x3B3E9C),      // Tab blue
            activeTabBackground: Color(hex: 0x34368B), // Active tab
            hoverBackground: Color(hex: 0x5053B8),       // Hover state
            shadowColor: Color.black.opacity(0.35)                           // Darker shadows
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
            panelShadowOpacity: 0.22,
            floatingShadowRadius: 6,  // Slightly larger for floating
            floatingShadowOffset: CGSize(width: 0, height: 3),
            floatingShadowOpacity: 0.3
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
