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
            background: Color(red: 0.2, green: 0.2, blue: 0.8),           // Deep blue
            secondaryBackground: Color(red: 0.3, green: 0.3, blue: 0.9),  // Lighter blue
            tertiaryBackground: Color(red: 0.4, green: 0.4, blue: 1.0),   // Even lighter blue
            panelBackground: Color(red: 0.25, green: 0.25, blue: 0.85),    // Panel blue
            headerBackground: Color(red: 0.3, green: 0.3, blue: 0.9),      // Header blue
            activeHeaderBackground: Color(red: 0.35, green: 0.35, blue: 0.95), // Active header
            separator: Color(red: 0.5, green: 0.2, blue: 0.8),            // Grape separator
            border: Color(red: 0.4, green: 0.3, blue: 0.9),               // Grape border
            activeBorder: Color(red: 1.0, green: 0.8, blue: 0.2),         // Yellow accent
            text: Color(red: 1.0, green: 1.0, blue: 1.0),               // White text
            secondaryText: Color(red: 0.8, green: 0.8, blue: 1.0),          // Light blue text
            tertiaryText: Color(red: 0.6, green: 0.6, blue: 0.9),           // Medium blue text
            accent: Color(red: 1.0, green: 0.8, blue: 0.2),                // Yellow accent
            accentSecondary: Color(red: 1.0, green: 0.9, blue: 0.4),       // Lighter yellow
            dropZoneHighlight: Color(red: 1.0, green: 0.8, blue: 0.2),     // Yellow highlight
            dropZoneBackground: Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.15), // Light yellow
            resizeHandle: Color(red: 0.6, green: 0.4, blue: 1.0),          // Light grape
            tabBackground: Color(red: 0.35, green: 0.35, blue: 0.95),      // Tab blue
            activeTabBackground: Color(red: 0.25, green: 0.25, blue: 0.85), // Active tab
            hoverBackground: Color(red: 0.4, green: 0.4, blue: 1.0),       // Hover state
            shadowColor: Color.black.opacity(0.4)                           // Darker shadows
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
