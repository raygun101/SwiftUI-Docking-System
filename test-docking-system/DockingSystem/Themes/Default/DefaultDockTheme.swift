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

