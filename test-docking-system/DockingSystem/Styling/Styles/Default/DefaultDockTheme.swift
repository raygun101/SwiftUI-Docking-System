import SwiftUI

// MARK: - Default Dock Theme

/// Default theme using DefaultStyleClass with a light palette
public struct DefaultDockTheme: DockThemeProtocol {
    public let colors: DockColorScheme
    public let typography: DockTypography
    public let spacing: DockSpacing
    public let borders: DockBorders
    public let shadows: DockShadows
    public let animations: DockAnimations
    public let cornerRadii: DockCornerRadii
    
    public init() {
        self.colors = DockColorScheme()
        self.typography = DockTypography()
        self.spacing = DockSpacing()
        self.borders = DockBorders()
        self.shadows = DockShadows()
        self.animations = DockAnimations()
        self.cornerRadii = DockCornerRadii()
    }
}

// MARK: - Default Style Implementations

/// Default header style for fallback
public struct DefaultDockHeaderStyle: DockHeaderStyle {
    public func makeBody(configuration: DockHeaderConfiguration) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                if let icon = configuration.icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(configuration.isActive ? Color.accentColor : Color.secondary)
                }
                
                Text(configuration.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(configuration.isActive ? Color.primary : Color.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 2) {
                if configuration.visibility.contains(.showCollapseButton) {
                    Button(action: configuration.onCollapse) {
                        Image(systemName: configuration.isCollapsed ? "chevron.down" : "chevron.up")
                            .font(.system(size: 12))
                    }
                }
                
                if configuration.visibility.contains(.showCloseButton) {
                    Button(action: configuration.onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(configuration.isActive ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor.separator)),
            alignment: .bottom
        )
    }
}

/// Default tab bar style for fallback
public struct DefaultDockTabBarStyle: DockTabBarStyle {
    public func makeBody(configuration: DockTabBarConfiguration) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(configuration.tabs.enumerated()), id: \.element.id) { index, tab in
                    Button(action: { configuration.onSelect(index) }) {
                        HStack(spacing: 6) {
                            if let icon = tab.icon {
                                Image(systemName: icon)
                                    .font(.system(size: 12))
                            }
                            Text(tab.title)
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(tab.isActive ? Color.accentColor.opacity(0.1) : Color.clear)
                        .overlay(
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(tab.isActive ? Color.accentColor : Color.clear),
                            alignment: .bottom
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, index < configuration.tabs.count - 1 ? 1 : 0)
                }
            }
        }
        .background(Color.secondary.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor.separator)),
            alignment: .bottom
        )
    }
}

/// Default resize handle style for fallback
public struct DefaultDockResizeHandleStyle: DockResizeHandleStyle {
    public func makeBody(configuration: DockResizeHandleConfiguration) -> some View {
        Group {
            if configuration.orientation == .horizontal {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            } else {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 4)
                    .frame(maxHeight: .infinity)
            }
        }
        .opacity(configuration.isHovered ? 1.0 : 0.6)
    }
}

/// Default drop zone style for fallback
public struct DefaultDockDropZoneStyle: DockDropZoneStyle {
    public func makeBody(configuration: DockDropZoneConfiguration) -> some View {
        Group {
            if configuration.isActive {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    )
            }
        }
    }
}

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
        // VS Code-inspired Dark Theme
        self.colors = DockColorScheme(
            background: Color(hex: 0x1E1E1E),           // Editor background
            secondaryBackground: Color(hex: 0x252526),  // Side bar background
            tertiaryBackground: Color(hex: 0x2D2D30),   // Activity bar / Status bar
            panelBackground: Color(hex: 0x1E1E1E),      // Panel background
            headerBackground: Color(hex: 0x252526),     // Header background
            activeHeaderBackground: Color(hex: 0x303031), // Active header
            separator: Color(hex: 0x454545),            // Split view separator
            border: Color(hex: 0x3E3E42),               // Borders
            activeBorder: Color(hex: 0x007FD4),         // Focus border
            text: Color(hex: 0xCCCCCC),                 // Main text
            secondaryText: Color(hex: 0x969696),        // Secondary text
            tertiaryText: Color(hex: 0x606060),         // Disabled/Dimmed
            accent: Color(hex: 0x007FD4),               // Blue accent
            accentSecondary: Color(hex: 0x0E639C),      // Darker accent
            dropZoneHighlight: Color(hex: 0x007FD4),    // Drop zone
            dropZoneBackground: Color(hex: 0x007FD4).opacity(0.2),
            resizeHandle: Color.clear,                  // Invisible handle area
            tabBackground: Color(hex: 0x2D2D2D),        // Inactive tab
            activeTabBackground: Color(hex: 0x1E1E1E),  // Active tab
            hoverBackground: Color(hex: 0x2A2D2E),      // List hover
            shadowColor: Color.black.opacity(0.4)
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
            floatingShadowRadius: 8,
            floatingShadowOffset: CGSize(width: 0, height: 4),
            floatingShadowOpacity: 0.3
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
