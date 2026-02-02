import SwiftUI

// MARK: - User Info Keys

/// Keys used for storing lifecycle callbacks in a panel's userInfo dictionary
public enum DockPanelUserInfoKey {
    public static let onCloseHandler = "DockPanelUserInfoKey.onClose"
    public static let onActivateHandler = "DockPanelUserInfoKey.onActivate"
    public static let toolbarProvider = "DockPanelUserInfoKey.toolbarProvider"
}

// MARK: - Dock Panel Model

/// Represents a single dockable panel with its content and configuration
public class DockPanel: ObservableObject, Identifiable, Hashable {
    public let id: DockPanelID
    public let title: String
    public let icon: String?
    
    @Published public var state: DockPanelState
    @Published public var position: DockPosition
    @Published public var size: CGSize
    @Published public var floatingFrame: CGRect?
    @Published public var isActive: Bool = false
    
    public let constraints: DockSizeConstraint
    public let visibility: DockPanelVisibility
    public let userInfo: [String: Any]
    
    private let contentBuilder: () -> AnyView
    
    public init<Content: View>(
        id: DockPanelID,
        title: String,
        icon: String? = nil,
        position: DockPosition = .left,
        state: DockPanelState = .expanded,
        size: CGSize = CGSize(width: 250, height: 200),
        constraints: DockSizeConstraint = .default,
        visibility: DockPanelVisibility = .standard,
        userInfo: [String: Any] = [:],
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.position = position
        self.state = state
        self.size = size
        self.constraints = constraints
        self.visibility = visibility
        self.userInfo = userInfo
        self.contentBuilder = { AnyView(content()) }
    }
    
    @ViewBuilder
    public func content() -> some View {
        contentBuilder()
    }
    
    // MARK: - Hashable
    
    public static func == (lhs: DockPanel, rhs: DockPanel) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Actions
    
    public func collapse() {
        withAnimation(.spring(response: 0.3)) {
            state = .collapsed
        }
    }
    
    public func expand() {
        withAnimation(.spring(response: 0.3)) {
            state = .expanded
        }
    }
    
    public func minimize() {
        withAnimation(.spring(response: 0.3)) {
            state = .minimized
        }
    }
    
    public func maximize() {
        withAnimation(.spring(response: 0.3)) {
            state = .maximized
        }
    }
    
    public func float(at frame: CGRect? = nil) {
        withAnimation(.spring(response: 0.3)) {
            state = .floating
            floatingFrame = frame ?? CGRect(x: 100, y: 100, width: size.width, height: size.height)
            position = .floating
        }
    }
    
    public func dock(to position: DockPosition) {
        withAnimation(.spring(response: 0.3)) {
            self.position = position
            if state == .floating {
                state = .expanded
            }
        }
    }
    
    public func toggle() {
        if state == .collapsed {
            expand()
        } else {
            collapse()
        }
    }
}

// MARK: - Panel Group

/// A group of panels that can be tabbed together
public class DockPanelGroup: ObservableObject, Identifiable, Hashable {
    public let id: String
    @Published public var panels: [DockPanel]
    @Published public var activeTabIndex: Int
    @Published public var position: DockPosition
    @Published public var size: CGSize
    @Published public var isCollapsed: Bool = false
    
    public var activePanel: DockPanel? {
        guard activeTabIndex >= 0 && activeTabIndex < panels.count else { return nil }
        return panels[activeTabIndex]
    }
    
    public init(
        id: String = UUID().uuidString,
        panels: [DockPanel],
        position: DockPosition,
        activeTabIndex: Int = 0,
        size: CGSize = CGSize(width: 250, height: 200)
    ) {
        self.id = id
        self.panels = panels
        self.position = position
        self.activeTabIndex = min(activeTabIndex, max(0, panels.count - 1))
        self.size = size
    }
    
    public static func == (lhs: DockPanelGroup, rhs: DockPanelGroup) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public func addPanel(_ panel: DockPanel, activate: Bool = true) {
        panels.append(panel)
        if activate {
            activeTabIndex = panels.count - 1
        }
    }
    
    public func removePanel(_ panel: DockPanel) {
        if let index = panels.firstIndex(of: panel) {
            panels.remove(at: index)
            if activeTabIndex >= panels.count {
                activeTabIndex = max(0, panels.count - 1)
            }
        }
    }
    
    public func activatePanel(_ panel: DockPanel) {
        if let index = panels.firstIndex(of: panel) {
            activeTabIndex = index
        }
    }
    
    public func movePanel(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0 && sourceIndex < panels.count,
              destinationIndex >= 0 && destinationIndex < panels.count else { return }
        
        let panel = panels.remove(at: sourceIndex)
        panels.insert(panel, at: destinationIndex)
        
        if activeTabIndex == sourceIndex {
            activeTabIndex = destinationIndex
        }
    }
}
