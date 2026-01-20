import SwiftUI

// MARK: - Layout Persistence

/// Serializable layout configuration for saving/restoring dock layouts
public struct DockLayoutConfiguration: Codable {
    public var leftWidth: CGFloat
    public var rightWidth: CGFloat
    public var topHeight: CGFloat
    public var bottomHeight: CGFloat
    public var isLeftCollapsed: Bool
    public var isRightCollapsed: Bool
    public var isTopCollapsed: Bool
    public var isBottomCollapsed: Bool
    public var panelConfigurations: [PanelConfiguration]
    
    public init(from layout: DockLayout) {
        self.leftWidth = layout.leftWidth
        self.rightWidth = layout.rightWidth
        self.topHeight = layout.topHeight
        self.bottomHeight = layout.bottomHeight
        self.isLeftCollapsed = layout.isLeftCollapsed
        self.isRightCollapsed = layout.isRightCollapsed
        self.isTopCollapsed = layout.isTopCollapsed
        self.isBottomCollapsed = layout.isBottomCollapsed
        self.panelConfigurations = layout.allPanels().map { PanelConfiguration(from: $0) }
    }
    
    public func apply(to layout: DockLayout) {
        layout.leftWidth = leftWidth
        layout.rightWidth = rightWidth
        layout.topHeight = topHeight
        layout.bottomHeight = bottomHeight
        layout.isLeftCollapsed = isLeftCollapsed
        layout.isRightCollapsed = isRightCollapsed
        layout.isTopCollapsed = isTopCollapsed
        layout.isBottomCollapsed = isBottomCollapsed
    }
}

/// Serializable panel configuration
public struct PanelConfiguration: Codable, Identifiable {
    public var id: String
    public var position: DockPosition
    public var state: DockPanelState
    public var width: CGFloat
    public var height: CGFloat
    public var floatingFrame: CGRect?
    public var groupId: String?
    public var tabIndex: Int?
    
    public init(from panel: DockPanel) {
        self.id = panel.id
        self.position = panel.position
        self.state = panel.state
        self.width = panel.size.width
        self.height = panel.size.height
        self.floatingFrame = panel.floatingFrame
    }
}

// MARK: - Layout Manager

/// Manages layout persistence and presets
public class DockLayoutManager: ObservableObject {
    @Published public var savedLayouts: [String: DockLayoutConfiguration] = [:]
    
    private let userDefaultsKey = "DockSavedLayouts"
    
    public init() {
        loadSavedLayouts()
    }
    
    // MARK: - Save/Load
    
    public func saveLayout(_ layout: DockLayout, as name: String) {
        let config = DockLayoutConfiguration(from: layout)
        savedLayouts[name] = config
        persistLayouts()
    }
    
    public func loadLayout(named name: String, into layout: DockLayout) {
        guard let config = savedLayouts[name] else { return }
        config.apply(to: layout)
    }
    
    public func deleteLayout(named name: String) {
        savedLayouts.removeValue(forKey: name)
        persistLayouts()
    }
    
    public func renameLayout(from oldName: String, to newName: String) {
        guard let config = savedLayouts[oldName] else { return }
        savedLayouts.removeValue(forKey: oldName)
        savedLayouts[newName] = config
        persistLayouts()
    }
    
    // MARK: - Persistence
    
    private func persistLayouts() {
        if let data = try? JSONEncoder().encode(savedLayouts) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadSavedLayouts() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let layouts = try? JSONDecoder().decode([String: DockLayoutConfiguration].self, from: data) else {
            return
        }
        savedLayouts = layouts
    }
    
    // MARK: - Export/Import
    
    public func exportLayout(_ layout: DockLayout) -> Data? {
        let config = DockLayoutConfiguration(from: layout)
        return try? JSONEncoder().encode(config)
    }
    
    public func importLayout(from data: Data, into layout: DockLayout) -> Bool {
        guard let config = try? JSONDecoder().decode(DockLayoutConfiguration.self, from: data) else {
            return false
        }
        config.apply(to: layout)
        return true
    }
}

// MARK: - Preset Layouts

public enum DockPresetLayout: String, CaseIterable {
    case ide = "IDE"
    case minimal = "Minimal"
    case writing = "Writing"
    case debugging = "Debugging"
    case presentation = "Presentation"
    
    public var description: String {
        switch self {
        case .ide:
            return "Full IDE layout with all panels"
        case .minimal:
            return "Clean workspace with minimal distractions"
        case .writing:
            return "Focused writing environment"
        case .debugging:
            return "Optimized for debugging sessions"
        case .presentation:
            return "Maximum content area for presentations"
        }
    }
    
    public func apply(to layout: DockLayout) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            switch self {
            case .ide:
                layout.isLeftCollapsed = false
                layout.isRightCollapsed = false
                layout.isBottomCollapsed = false
                layout.leftWidth = 260
                layout.rightWidth = 280
                layout.bottomHeight = 200
                
            case .minimal:
                layout.isLeftCollapsed = true
                layout.isRightCollapsed = true
                layout.isBottomCollapsed = true
                
            case .writing:
                layout.isLeftCollapsed = true
                layout.isRightCollapsed = false
                layout.isBottomCollapsed = true
                layout.rightWidth = 300
                
            case .debugging:
                layout.isLeftCollapsed = false
                layout.isRightCollapsed = false
                layout.isBottomCollapsed = false
                layout.leftWidth = 200
                layout.rightWidth = 350
                layout.bottomHeight = 280
                
            case .presentation:
                layout.isLeftCollapsed = true
                layout.isRightCollapsed = true
                layout.isBottomCollapsed = true
            }
        }
    }
}
