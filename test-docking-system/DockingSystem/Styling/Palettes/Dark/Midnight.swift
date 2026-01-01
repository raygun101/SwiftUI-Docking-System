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
            background: Color(red: 0.11, green: 0.11, blue: 0.15),        // Deep midnight blue
            secondaryBackground: Color(red: 0.15, green: 0.15, blue: 0.20), // Slightly lighter
            tertiaryBackground: Color(red: 0.18, green: 0.18, blue: 0.23),  // Even lighter
            panelBackground: Color(red: 0.13, green: 0.13, blue: 0.17),     // Panel background
            headerBackground: Color(red: 0.16, green: 0.16, blue: 0.21),     // Header background
            activeHeaderBackground: Color(red: 0.20, green: 0.20, blue: 0.25), // Active header
            separator: Color(red: 0.25, green: 0.25, blue: 0.30),          // Subtle separator
            border: Color(red: 0.30, green: 0.30, blue: 0.35),             // Border color
            activeBorder: Color(red: 0.0, green: 0.48, blue: 1.0),          // Bright blue accent
            text: Color(red: 0.95, green: 0.95, blue: 0.97),               // Near white text
            secondaryText: Color(red: 0.70, green: 0.70, blue: 0.75),          // Light gray text
            tertiaryText: Color(red: 0.50, green: 0.50, blue: 0.55),           // Medium gray text
            accent: Color(red: 0.0, green: 0.48, blue: 1.0),                // Bright blue accent
            accentSecondary: Color(red: 0.2, green: 0.6, blue: 1.0),        // Lighter blue
            dropZoneHighlight: Color(red: 0.0, green: 0.48, blue: 1.0),      // Blue highlight
            dropZoneBackground: Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.15), // Light blue
            resizeHandle: Color(red: 0.4, green: 0.4, blue: 0.5),          // Gray resize handle
            tabBackground: Color(red: 0.18, green: 0.18, blue: 0.23),       // Tab background
            activeTabBackground: Color(red: 0.13, green: 0.13, blue: 0.17),  // Active tab
            hoverBackground: Color(red: 0.22, green: 0.22, blue: 0.27),     // Hover state
            shadowColor: Color.black.opacity(0.6)                           // Dark shadows
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
