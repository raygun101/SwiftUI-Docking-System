import SwiftUI

// MARK: - Theme Presets Registration

public class ThemePresets {
    public static func registerAll() {
        let registry = ThemeRegistry.shared
        
        // MARK: - Register Style Classes
        
        registry.registerStyle(DefaultStyleClass.self, named: "DefaultStyleClass")
        registry.registerStyle(RetroMaxOS9StyleClass.self, named: "RetroMaxOS9StyleClass")
        
        // MARK: - Register Palettes
        
        // Retro Mac OS 9 Palettes
        registry.registerPalette(ClassicPlatinum.self, named: "ClassicPlatinum")
        registry.registerPalette(BlueGrape.self, named: "BlueGrape")
        
        // Dark Palettes
        registry.registerPalette(Midnight.self, named: "Midnight")
        
        // Light Palettes
        registry.registerPalette(Daylight.self, named: "Daylight")
        
        // MARK: - Register Theme Combinations
        
        // Retro Mac OS 9 Themes
        registry.registerTheme(
            style: "RetroMaxOS9StyleClass",
            palette: "ClassicPlatinum",
            named: "RetroMacClassic",
            displayName: "Retro Mac - Classic Platinum",
            description: "Classic Mac OS 9 platinum appearance with beveled edges"
        )
        
        registry.registerTheme(
            style: "RetroMaxOS9StyleClass",
            palette: "BlueGrape",
            named: "RetroMacBlueGrape",
            displayName: "Retro Mac - Blue Grape",
            description: "Mac OS 9 style with blue and grape color scheme"
        )
        
        // Modern Themes
        registry.registerTheme(
            style: "DefaultStyleClass",
            palette: "Midnight",
            named: "ModernDark",
            displayName: "Modern Dark",
            description: "Clean modern dark theme with blue accents"
        )
        
        registry.registerTheme(
            style: "DefaultStyleClass",
            palette: "Daylight",
            named: "ModernLight",
            displayName: "Modern Light",
            description: "Clean modern light theme with subtle shadows"
        )
        
        // Default Theme (fallback) - use DefaultDockTheme directly
        // This theme doesn't need registration as it's the fallback
    }
    
    // MARK: - Theme Categories
    
    public enum ThemeCategory: String, CaseIterable {
        case retro = "Retro"
        case modern = "Modern"
        case dark = "Dark"
        case light = "Light"
        case custom = "Custom"
        
        public var displayName: String {
            return self.rawValue
        }
    }
    
    // MARK: - Theme Metadata
    
    public struct ThemeMetadata {
        public let name: String
        public let displayName: String
        public let description: String
        public let category: ThemeCategory
        public let styleClassName: String
        public let paletteName: String
        public let isBuiltIn: Bool
        
        public init(
            name: String,
            displayName: String,
            description: String,
            category: ThemeCategory,
            styleClassName: String,
            paletteName: String,
            isBuiltIn: Bool = true
        ) {
            self.name = name
            self.displayName = displayName
            self.description = description
            self.category = category
            self.styleClassName = styleClassName
            self.paletteName = paletteName
            self.isBuiltIn = isBuiltIn
        }
    }
    
    // MARK: - Theme Discovery
    
    public static func getAllThemes() -> [ThemeMetadata] {
        let registry = ThemeRegistry.shared
        return registry.availableThemes.map { combination in
            let category = determineCategory(for: combination)
            return ThemeMetadata(
                name: combination.name,
                displayName: combination.displayName,
                description: combination.description,
                category: category,
                styleClassName: combination.styleClassName,
                paletteName: combination.paletteName
            )
        }
    }
    
    public static func getThemes(in category: ThemeCategory) -> [ThemeMetadata] {
        return getAllThemes().filter { $0.category == category }
    }
    
    public static func searchThemes(query: String) -> [ThemeMetadata] {
        let allThemes = getAllThemes()
        guard !query.isEmpty else { return allThemes }
        
        return allThemes.filter { theme in
            theme.displayName.localizedCaseInsensitiveContains(query) ||
            theme.description.localizedCaseInsensitiveContains(query) ||
            theme.styleClassName.localizedCaseInsensitiveContains(query) ||
            theme.paletteName.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Private Helpers
    
    private static func determineCategory(for combination: ThemeCombination) -> ThemeCategory {
        let styleName = combination.styleClassName.lowercased()
        let paletteName = combination.paletteName.lowercased()
        
        // Determine category based on style and palette names
        if styleName.contains("retro") || paletteName.contains("platinum") || paletteName.contains("grape") {
            return .retro
        } else if paletteName.contains("dark") || paletteName.contains("midnight") || paletteName.contains("obsidian") {
            return .dark
        } else if paletteName.contains("light") || paletteName.contains("daylight") || paletteName.contains("paper") {
            return .light
        } else if styleName.contains("minimal") || styleName.contains("modern") || styleName.contains("default") {
            return .modern
        } else {
            return .custom
        }
    }
}

// MARK: - Theme Manager

public class ThemeManager: ObservableObject {
    @Published public private(set) var currentTheme: DockThemeProtocol = DefaultDockTheme()
    @Published public private(set) var availableThemes: [ThemePresets.ThemeMetadata] = []
    @Published public private(set) var selectedThemeMetadata: ThemePresets.ThemeMetadata?
    
    private let registry = ThemeRegistry.shared
    
    public init() {
        loadAvailableThemes()
        if availableThemes.contains(where: { $0.name == "ModernDark" }) {
            applyTheme(named: "ModernDark", animated: false)
        } else {
            applyDefaultTheme(animated: false)
        }
    }
    
    public func loadAvailableThemes() {
        availableThemes = ThemePresets
            .getAllThemes()
            .sorted { $0.displayName < $1.displayName }
    }
    
    public func applyTheme(named name: String, animated: Bool = true) {
        guard let theme = registry.createTheme(named: name) else { return }
        setTheme(theme, animated: animated)
        if let metadata = availableThemes.first(where: { $0.name == name }) {
            selectedThemeMetadata = metadata
        } else if let metadata = ThemePresets.getAllThemes().first(where: { $0.name == name }) {
            selectedThemeMetadata = metadata
        }
    }
    
    public func applyTheme(style: String, palette: String, animated: Bool = true) {
        guard let theme = registry.createTheme(style: style, palette: palette) else { return }
        selectedThemeMetadata = nil
        setTheme(theme, animated: animated)
    }
    
    public func applyDefaultTheme(animated: Bool = true) {
        selectedThemeMetadata = nil
        setTheme(DefaultDockTheme(), animated: animated)
    }
    
    public func createCustomTheme(style: String, palette: String) -> DockThemeProtocol? {
        return registry.createTheme(style: style, palette: palette)
    }
    
    public func registerCustomTheme(
        style: String,
        palette: String,
        named: String,
        displayName: String,
        description: String
    ) {
        registry.registerTheme(
            style: style,
            palette: palette,
            named: named,
            displayName: displayName,
            description: description
        )
        loadAvailableThemes()
    }
    
    private func setTheme(_ theme: DockThemeProtocol, animated: Bool) {
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentTheme = theme
            }
        } else {
            currentTheme = theme
        }
    }
}
