import SwiftUI

// MARK: - Theme Modifiers

public extension View {
    /// Apply a dock theme to this view and its descendants.
    func dockTheme(_ theme: DockThemeProtocol) -> some View {
        environment(\.dockTheme, theme)
    }
    
    /// Apply a theme by style class and palette identifiers.
    func dockTheme(style styleName: String, palette paletteName: String) -> some View {
        let theme = ThemeRegistry.shared.createTheme(style: styleName, palette: paletteName) ?? DefaultDockTheme()
        return dockTheme(theme)
    }
    
    /// Apply a named preset registered with the ThemeRegistry.
    func dockTheme(named presetName: String) -> some View {
        let theme = ThemeRegistry.shared.createTheme(named: presetName) ?? DefaultDockTheme()
        return dockTheme(theme)
    }
    
    func dockHeaderStyle(_ style: any DockHeaderStyle) -> some View {
        environment(\.dockHeaderStyle, style)
    }
    
    func dockTabBarStyle(_ style: any DockTabBarStyle) -> some View {
        environment(\.dockTabBarStyle, style)
    }
    
    func dockResizeHandleStyle(_ style: any DockResizeHandleStyle) -> some View {
        environment(\.dockResizeHandleStyle, style)
    }
    
    func dockDropZoneStyle(_ style: any DockDropZoneStyle) -> some View {
        environment(\.dockDropZoneStyle, style)
    }
}

// MARK: - Theme Builder

public extension View {
    /// Configure a theme using the builder DSL.
    func configureTheme(_ builder: ThemeBuilder) -> some View {
        dockTheme(builder.build() ?? DefaultDockTheme())
    }
}

// MARK: - Convenience Presets

public extension View {
    func retroMacClassic() -> some View {
        dockTheme(style: "RetroMaxOS9StyleClass", palette: "ClassicPlatinum")
    }
    
    func retroMacBlueGrape() -> some View {
        dockTheme(style: "RetroMaxOS9StyleClass", palette: "BlueGrape")
    }
    
    func midnightDark() -> some View {
        dockTheme(style: "DefaultStyleClass", palette: "Midnight")
    }
    
    func modernTheme() -> some View {
        dockTheme(DefaultDockTheme())
    }
}

// MARK: - Theme Animations

public extension View {
    func animatedTheme() -> some View {
        animation(.easeInOut(duration: 0.3), value: ThemeRegistry.shared.availableThemes)
    }
}
