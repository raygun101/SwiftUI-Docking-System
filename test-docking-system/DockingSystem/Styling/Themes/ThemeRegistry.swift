import SwiftUI

// MARK: - Theme Combination

public struct ThemeCombination: Equatable {
    public let name: String
    public let styleClassName: String
    public let paletteName: String
    public let displayName: String
    public let description: String
    
    public init(
        name: String,
        styleClassName: String,
        paletteName: String,
        displayName: String,
        description: String
    ) {
        self.name = name
        self.styleClassName = styleClassName
        self.paletteName = paletteName
        self.displayName = displayName
        self.description = description
    }
    
    public static func == (lhs: ThemeCombination, rhs: ThemeCombination) -> Bool {
        lhs.name == rhs.name
    }
}

// MARK: - Theme Registry

public final class ThemeRegistry: ObservableObject {
    public static let shared = ThemeRegistry()
    
    @Published public private(set) var availableThemes: [ThemeCombination] = []
    
    private var registeredStyles: [String: any DockStyleClass.Type] = [:]
    private var registeredPalettes: [String: any DockPalette.Type] = [:]
    private var themePresets: [String: ThemeCombination] = [:]
    
    private init() {
        registerDefaults()
    }
    
    // MARK: Registration
    
    public func registerStyle<S: DockStyleClass>(_ style: S.Type, named name: String) {
        registeredStyles[name] = style
    }
    
    public func registerPalette<P: DockPalette>(_ palette: P.Type, named name: String) {
        registeredPalettes[name] = palette
    }
    
    public func registerTheme(
        style: String,
        palette: String,
        named: String,
        displayName: String? = nil,
        description: String = ""
    ) {
        let combination = ThemeCombination(
            name: named,
            styleClassName: style,
            paletteName: palette,
            displayName: displayName ?? named,
            description: description
        )
        
        themePresets[named] = combination
        availableThemes = themePresets.values.sorted { $0.displayName < $1.displayName }
    }
    
    // MARK: Theme Creation
    
    public func createTheme(style: String, palette: String) -> (any DockThemeProtocol)? {
        guard let styleType = registeredStyles[style],
              let paletteType = registeredPalettes[palette] else {
            return nil
        }
        
        return buildTheme(styleType: styleType, paletteType: paletteType)
    }
    
    public func createTheme(named name: String) -> (any DockThemeProtocol)? {
        guard let combination = themePresets[name] else { return nil }
        return createTheme(style: combination.styleClassName, palette: combination.paletteName)
    }
    
    // MARK: Queries
    
    public func getAvailableStyles() -> [String] {
        registeredStyles.keys.sorted()
    }
    
    public func getAvailablePalettes() -> [String] {
        registeredPalettes.keys.sorted()
    }
    
    public func getThemePresets() -> [ThemeCombination] {
        availableThemes
    }
    
    private func registerDefaults() { }
    
    private func buildTheme(
        styleType: any DockStyleClass.Type,
        paletteType: any DockPalette.Type
    ) -> (any DockThemeProtocol) {
        func openStyle<Style: DockStyleClass>(_ concreteStyle: Style.Type) -> (any DockThemeProtocol) {
            func openPalette<Palette: DockPalette>(_ concretePalette: Palette.Type) -> any DockThemeProtocol {
                ComposableDockTheme(styleClass: Style.init(), palette: Palette.init())
            }
            return _openExistential(paletteType, do: openPalette)
        }
        
        return _openExistential(styleType, do: openStyle)
    }
}

// MARK: - Theme Builder

public final class ThemeBuilder {
    private var styleClassName: String?
    private var paletteName: String?
    
    public init() {}
    
    @discardableResult
    public func withStyle(_ name: String) -> ThemeBuilder {
        styleClassName = name
        return self
    }
    
    @discardableResult
    public func withPalette(_ name: String) -> ThemeBuilder {
        paletteName = name
        return self
    }
    
    public func build() -> (any DockThemeProtocol)? {
        guard let style = styleClassName,
              let palette = paletteName else {
            return nil
        }
        
        return ThemeRegistry.shared.createTheme(style: style, palette: palette)
    }
}

// MARK: - Convenience Extensions

public extension ThemeRegistry {
    static func theme(style: String, palette: String) -> (any DockThemeProtocol)? {
        shared.createTheme(style: style, palette: palette)
    }
    
    static func theme(named name: String) -> (any DockThemeProtocol)? {
        shared.createTheme(named: name)
    }
    
    static func register<S: DockStyleClass, P: DockPalette>(
        style: S.Type,
        palette: P.Type,
        named: String,
        displayName: String? = nil,
        description: String = ""
    ) {
        let styleName = String(describing: style)
        let paletteName = String(describing: palette)
        
        shared.registerStyle(style, named: styleName)
        shared.registerPalette(palette, named: paletteName)
        shared.registerTheme(
            style: styleName,
            palette: paletteName,
            named: named,
            displayName: displayName,
            description: description
        )
    }
}
