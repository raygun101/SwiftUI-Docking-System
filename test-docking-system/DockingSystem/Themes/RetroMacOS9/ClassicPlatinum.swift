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
            background: Color(red: 0.85, green: 0.85, blue: 0.85),      // Platinum background
            secondaryBackground: Color(red: 0.75, green: 0.75, blue: 0.75), // Darker platinum
            tertiaryBackground: Color(red: 0.65, green: 0.65, blue: 0.65),  // Even darker
            panelBackground: Color(red: 0.90, green: 0.90, blue: 0.90),     // Light platinum
            headerBackground: Color(red: 0.75, green: 0.75, blue: 0.75),     // Header platinum
            activeHeaderBackground: Color(red: 0.80, green: 0.80, blue: 0.80), // Active header
            separator: Color(red: 0.55, green: 0.55, blue: 0.55),            // Dark separator
            border: Color(red: 0.60, green: 0.60, blue: 0.60),               // Border color
            activeBorder: Color(red: 0.0, green: 0.0, blue: 1.0),           // Classic Mac blue
            text: Color(red: 0.0, green: 0.0, blue: 0.0),                   // Black text
            secondaryText: Color(red: 0.2, green: 0.2, blue: 0.2),          // Dark gray
            tertiaryText: Color(red: 0.4, green: 0.4, blue: 0.4),           // Medium gray
            accent: Color(red: 0.0, green: 0.0, blue: 1.0),                // Classic Mac blue
            accentSecondary: Color(red: 0.0, green: 0.5, blue: 1.0),       // Lighter blue
            dropZoneHighlight: Color(red: 0.0, green: 0.0, blue: 1.0),     // Blue highlight
            dropZoneBackground: Color(red: 0.0, green: 0.0, blue: 1.0).opacity(0.1), // Very light blue
            resizeHandle: Color(red: 0.4, green: 0.4, blue: 0.4),          // Gray resize handle
            tabBackground: Color(red: 0.80, green: 0.80, blue: 0.80),       // Tab background
            activeTabBackground: Color(red: 0.90, green: 0.90, blue: 0.90),  // Active tab
            hoverBackground: Color(red: 0.70, green: 0.70, blue: 0.70),     // Hover state
            shadowColor: Color.black.opacity(0.3)                           // Classic shadows
        )
        
        self.typography = DockTypography(
            headerFont: .system(size: 12, weight: .medium, design: .default), // Chicago-style
            headerFontWeight: .medium,
            tabFont: .system(size: 11, weight: .medium, design: .default),      // Geneva-style
            tabFontWeight: .medium,
            iconSize: 12
        )
        
        self.spacing = DockSpacing(
            headerPadding: 8,        // Compact padding
            tabPadding: 6,           // Tight tab padding
            resizeHandleSize: 3,     // Thin resize handles
            panelPadding: 12,        // Standard panel padding
            collapsedWidth: 44,      // Classic collapsed width
            minPanelSize: 150,       // Smaller minimum size
            dropZoneMargin: 60       // Smaller drop zone margin
        )
        
        self.borders = DockBorders(
            separatorWidth: 1,       // Thin separators
            borderWidth: 1,          // Thin borders
            activeBorderWidth: 2      // Slightly thicker active border
        )
        
        self.shadows = DockShadows(
            panelShadowRadius: 2,    // Subtle shadows
            panelShadowOffset: CGSize(width: 0, height: 1),
            panelShadowOpacity: 0.2,
            floatingShadowRadius: 4,  // Slightly larger for floating
            floatingShadowOffset: CGSize(width: 0, height: 2),
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
