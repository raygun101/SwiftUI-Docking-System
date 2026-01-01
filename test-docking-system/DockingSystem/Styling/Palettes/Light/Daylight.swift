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
        self.colors = DockColorScheme(
            background: Color(red: 0.97, green: 0.97, blue: 0.97),        // Light background
            secondaryBackground: Color(red: 0.92, green: 0.92, blue: 0.92), // Slightly darker
            tertiaryBackground: Color(red: 0.87, green: 0.87, blue: 0.87),  // Even darker
            panelBackground: Color(red: 1.0, green: 1.0, blue: 1.0),       // Pure white
            headerBackground: Color(red: 0.95, green: 0.95, blue: 0.95),     // Header background
            activeHeaderBackground: Color(red: 0.90, green: 0.90, blue: 0.90), // Active header
            separator: Color(red: 0.80, green: 0.80, blue: 0.80),            // Subtle separator
            border: Color(red: 0.75, green: 0.75, blue: 0.75),             // Border color
            activeBorder: Color(red: 0.0, green: 0.48, blue: 0.95),         // Blue accent
            text: Color(red: 0.1, green: 0.1, blue: 0.1),                 // Dark text
            secondaryText: Color(red: 0.4, green: 0.4, blue: 0.4),          // Medium gray text
            tertiaryText: Color(red: 0.6, green: 0.6, blue: 0.6),           // Light gray text
            accent: Color(red: 0.0, green: 0.48, blue: 0.95),                // Blue accent
            accentSecondary: Color(red: 0.2, green: 0.6, blue: 1.0),        // Lighter blue
            dropZoneHighlight: Color(red: 0.0, green: 0.48, blue: 0.95),     // Blue highlight
            dropZoneBackground: Color(red: 0.0, green: 0.48, blue: 0.95).opacity(0.1), // Light blue
            resizeHandle: Color(red: 0.5, green: 0.5, blue: 0.5),          // Gray resize handle
            tabBackground: Color(red: 0.92, green: 0.92, blue: 0.92),       // Tab background
            activeTabBackground: Color(red: 1.0, green: 1.0, blue: 1.0),    // Active tab
            hoverBackground: Color(red: 0.87, green: 0.87, blue: 0.87),     // Hover state
            shadowColor: Color.black.opacity(0.2)                           // Light shadows
        )
        
        self.typography = DockTypography(
            headerFont: .system(size: 13, weight: .medium, design: .default), // Modern system font
            headerFontWeight: .medium,
            tabFont: .system(size: 12, weight: .regular, design: .default),     // Clean tab font
            tabFontWeight: .regular,
            iconSize: 14
        )
        
        self.spacing = DockSpacing(
            headerPadding: 12,       // Modern padding
            tabPadding: 8,           // Comfortable tab padding
            resizeHandleSize: 4,     // Standard resize handle
            panelPadding: 16,        // Modern panel padding
            collapsedWidth: 44,      // Standard collapsed width
            minPanelSize: 200,       // Modern minimum size
            dropZoneMargin: 80       // Standard drop zone margin
        )
        
        self.borders = DockBorders(
            separatorWidth: 1,       // Thin separators
            borderWidth: 1,          // Thin borders
            activeBorderWidth: 2      // Thicker active border
        )
        
        self.shadows = DockShadows(
            panelShadowRadius: 8,    // Modern shadows
            panelShadowOffset: CGSize(width: 0, height: 2),
            panelShadowOpacity: 0.15,
            floatingShadowRadius: 16, // Larger floating shadows
            floatingShadowOffset: CGSize(width: 0, height: 8),
            floatingShadowOpacity: 0.25
        )
        
        self.animations = DockAnimations(
            defaultDuration: 0.25,   // Smooth animations
            quickDuration: 0.15,
            slowDuration: 0.4,
            springResponse: 0.3,
            springDampingFraction: 0.8
        )
        
        self.cornerRadii = DockCornerRadii(
            panel: 8,                // Modern rounded corners
            header: 8,               // Rounded header
            tab: 6,                  // Rounded tabs
            button: 4,               // Rounded buttons
            dropZone: 8,             // Rounded drop zones
            floating: 12             // More rounded for floating
        )
    }
}
