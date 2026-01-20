import SwiftUI

// MARK: - Layout Node

/// Represents a node in the dock layout tree
public indirect enum DockLayoutNode: Identifiable, Hashable {
    case panel(DockPanelGroup)
    case split(DockSplitNode)
    case empty
    
    public var id: String {
        switch self {
        case .panel(let group): return "panel-\(group.id)"
        case .split(let node): return "split-\(node.id)"
        case .empty: return "empty"
        }
    }
    
    public static func == (lhs: DockLayoutNode, rhs: DockLayoutNode) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// A split node containing two child layout nodes
public class DockSplitNode: ObservableObject, Identifiable, Hashable {
    public let id: String
    @Published public var orientation: DockSplitOrientation
    @Published public var first: DockLayoutNode
    @Published public var second: DockLayoutNode
    @Published public var splitRatio: CGFloat
    @Published public var isResizing: Bool = false
    
    public let minRatio: CGFloat
    public let maxRatio: CGFloat
    
    public init(
        id: String = UUID().uuidString,
        orientation: DockSplitOrientation,
        first: DockLayoutNode,
        second: DockLayoutNode,
        splitRatio: CGFloat = 0.5,
        minRatio: CGFloat = 0.1,
        maxRatio: CGFloat = 0.9
    ) {
        self.id = id
        self.orientation = orientation
        self.first = first
        self.second = second
        self.splitRatio = min(max(splitRatio, minRatio), maxRatio)
        self.minRatio = minRatio
        self.maxRatio = maxRatio
    }
    
    public static func == (lhs: DockSplitNode, rhs: DockSplitNode) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public func updateRatio(_ newRatio: CGFloat) {
        splitRatio = min(max(newRatio, minRatio), maxRatio)
    }
}

// MARK: - Dock Layout

/// The complete dock layout configuration
public class DockLayout: ObservableObject {
    @Published public var leftNode: DockLayoutNode = .empty
    @Published public var rightNode: DockLayoutNode = .empty
    @Published public var topNode: DockLayoutNode = .empty
    @Published public var bottomNode: DockLayoutNode = .empty
    @Published public var centerNode: DockLayoutNode = .empty
    @Published public var floatingPanels: [DockPanelGroup] = []
    @Published public var minimizedPanels: [DockPanel] = []
    
    @Published public var leftWidth: CGFloat = 250
    @Published public var rightWidth: CGFloat = 250
    @Published public var topHeight: CGFloat = 200
    @Published public var bottomHeight: CGFloat = 200
    
    @Published public var isLeftCollapsed: Bool = false
    @Published public var isRightCollapsed: Bool = false
    @Published public var isTopCollapsed: Bool = false
    @Published public var isBottomCollapsed: Bool = false
    
    public init() {}
    
    // MARK: - Layout Queries
    
    public func node(for position: DockPosition) -> DockLayoutNode {
        switch position {
        case .left: return leftNode
        case .right: return rightNode
        case .top: return topNode
        case .bottom: return bottomNode
        case .center: return centerNode
        case .floating: return .empty
        }
    }
    
    public func setNode(_ node: DockLayoutNode, for position: DockPosition) {
        switch position {
        case .left: leftNode = node
        case .right: rightNode = node
        case .top: topNode = node
        case .bottom: bottomNode = node
        case .center: centerNode = node
        case .floating: break
        }
    }
    
    public func size(for position: DockPosition, in containerSize: CGSize) -> CGSize {
        switch position {
        case .left:
            return CGSize(width: isLeftCollapsed ? 44 : leftWidth, height: containerSize.height)
        case .right:
            return CGSize(width: isRightCollapsed ? 44 : rightWidth, height: containerSize.height)
        case .top:
            return CGSize(width: containerSize.width, height: isTopCollapsed ? 44 : topHeight)
        case .bottom:
            return CGSize(width: containerSize.width, height: isBottomCollapsed ? 44 : bottomHeight)
        case .center, .floating:
            return containerSize
        }
    }
    
    public func isCollapsed(for position: DockPosition) -> Bool {
        switch position {
        case .left: return isLeftCollapsed
        case .right: return isRightCollapsed
        case .top: return isTopCollapsed
        case .bottom: return isBottomCollapsed
        default: return false
        }
    }
    
    public func toggleCollapse(for position: DockPosition) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            switch position {
            case .left: isLeftCollapsed.toggle()
            case .right: isRightCollapsed.toggle()
            case .top: isTopCollapsed.toggle()
            case .bottom: isBottomCollapsed.toggle()
            default: break
            }
        }
    }
    
    // MARK: - Panel Management
    
    public func findPanelGroup(containing panelID: DockPanelID) -> DockPanelGroup? {
        for node in [leftNode, rightNode, topNode, bottomNode, centerNode] {
            if let group = findPanelGroupInNode(node, panelID: panelID) {
                return group
            }
        }
        return floatingPanels.first { $0.panels.contains { $0.id == panelID } }
    }
    
    private func findPanelGroupInNode(_ node: DockLayoutNode, panelID: DockPanelID) -> DockPanelGroup? {
        switch node {
        case .panel(let group):
            if group.panels.contains(where: { $0.id == panelID }) {
                return group
            }
        case .split(let splitNode):
            if let found = findPanelGroupInNode(splitNode.first, panelID: panelID) {
                return found
            }
            if let found = findPanelGroupInNode(splitNode.second, panelID: panelID) {
                return found
            }
        case .empty:
            break
        }
        return nil
    }
    
    public func allPanelGroups() -> [DockPanelGroup] {
        var groups: [DockPanelGroup] = []
        for node in [leftNode, rightNode, topNode, bottomNode, centerNode] {
            groups.append(contentsOf: collectPanelGroups(from: node))
        }
        groups.append(contentsOf: floatingPanels)
        return groups
    }
    
    private func collectPanelGroups(from node: DockLayoutNode) -> [DockPanelGroup] {
        switch node {
        case .panel(let group):
            return [group]
        case .split(let splitNode):
            return collectPanelGroups(from: splitNode.first) + collectPanelGroups(from: splitNode.second)
        case .empty:
            return []
        }
    }
    
    public func allPanels() -> [DockPanel] {
        allPanelGroups().flatMap { $0.panels }
    }
}

// MARK: - Layout Builder

/// Fluent builder for creating dock layouts
public class DockLayoutBuilder {
    private var layout = DockLayout()
    
    public init() {}
    
    @discardableResult
    public func left(_ panels: [DockPanel], width: CGFloat = 250) -> DockLayoutBuilder {
        let group = DockPanelGroup(panels: panels, position: .left)
        layout.leftNode = .panel(group)
        layout.leftWidth = width
        return self
    }
    
    @discardableResult
    public func right(_ panels: [DockPanel], width: CGFloat = 250) -> DockLayoutBuilder {
        let group = DockPanelGroup(panels: panels, position: .right)
        layout.rightNode = .panel(group)
        layout.rightWidth = width
        return self
    }
    
    @discardableResult
    public func top(_ panels: [DockPanel], height: CGFloat = 200) -> DockLayoutBuilder {
        let group = DockPanelGroup(panels: panels, position: .top)
        layout.topNode = .panel(group)
        layout.topHeight = height
        return self
    }
    
    @discardableResult
    public func bottom(_ panels: [DockPanel], height: CGFloat = 200) -> DockLayoutBuilder {
        let group = DockPanelGroup(panels: panels, position: .bottom)
        layout.bottomNode = .panel(group)
        layout.bottomHeight = height
        return self
    }
    
    @discardableResult
    public func center(_ panels: [DockPanel]) -> DockLayoutBuilder {
        let group = DockPanelGroup(panels: panels, position: .center)
        layout.centerNode = .panel(group)
        return self
    }
    
    @discardableResult
    public func leftSplit(
        _ first: [DockPanel],
        _ second: [DockPanel],
        ratio: CGFloat = 0.5,
        width: CGFloat = 250
    ) -> DockLayoutBuilder {
        let firstGroup = DockPanelGroup(panels: first, position: .left)
        let secondGroup = DockPanelGroup(panels: second, position: .left)
        let split = DockSplitNode(
            orientation: .vertical,
            first: .panel(firstGroup),
            second: .panel(secondGroup),
            splitRatio: ratio
        )
        layout.leftNode = .split(split)
        layout.leftWidth = width
        return self
    }
    
    @discardableResult
    public func rightSplit(
        _ first: [DockPanel],
        _ second: [DockPanel],
        ratio: CGFloat = 0.5,
        width: CGFloat = 250
    ) -> DockLayoutBuilder {
        let firstGroup = DockPanelGroup(panels: first, position: .right)
        let secondGroup = DockPanelGroup(panels: second, position: .right)
        let split = DockSplitNode(
            orientation: .vertical,
            first: .panel(firstGroup),
            second: .panel(secondGroup),
            splitRatio: ratio
        )
        layout.rightNode = .split(split)
        layout.rightWidth = width
        return self
    }
    
    public func build() -> DockLayout {
        return layout
    }
}
