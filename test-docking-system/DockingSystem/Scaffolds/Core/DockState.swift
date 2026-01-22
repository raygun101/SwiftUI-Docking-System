import SwiftUI
import Combine

// MARK: - Dock State Manager

/// Central state manager for the docking system
public class DockState: ObservableObject {
    @Published public var layout: DockLayout
    @Published public var activePanel: DockPanel?
    @Published public var draggedPanel: DockPanel?
    @Published public var pendingDragPanel: DockPanel?
    @Published public var dropZone: DockDropZone = .none
    @Published private(set) var dragHasMoved: Bool = false
    @Published public var isResizing: Bool = false
    @Published public var resizingPosition: DockPosition?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(layout: DockLayout = DockLayout()) {
        self.layout = layout
        setupObservers()
    }
    
    private func setupObservers() {
        layout.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Panel Actions
    
    public func activatePanel(_ panel: DockPanel) {
        activePanel?.isActive = false
        activePanel = panel
        panel.isActive = true
        
        if let group = layout.findPanelGroup(containing: panel.id) {
            group.activatePanel(panel)
        }
    }
    
    public func closePanel(_ panel: DockPanel) {
        guard let group = layout.findPanelGroup(containing: panel.id) else { return }
        
        withAnimation(.spring(response: 0.3)) {
            group.removePanel(panel)
            
            if group.panels.isEmpty {
                removePanelGroup(group)
            }
            
            if activePanel?.id == panel.id {
                activePanel = group.activePanel ?? layout.allPanels().first
            }
        }
    }
    
    public func floatPanel(_ panel: DockPanel, at frame: CGRect? = nil) {
        guard let group = layout.findPanelGroup(containing: panel.id) else { return }
        
        withAnimation(.spring(response: 0.3)) {
            group.removePanel(panel)
            
            if group.panels.isEmpty {
                removePanelGroup(group)
            }
            
            let floatingGroup = DockPanelGroup(
                panels: [panel],
                position: .floating,
                size: panel.size
            )
            layout.floatingPanels.append(floatingGroup)
            panel.float(at: frame)
        }
    }
    
    public func dockPanel(_ panel: DockPanel, to position: DockPosition) {
        guard let sourceGroup = layout.findPanelGroup(containing: panel.id) else { return }
        
        withAnimation(.spring(response: 0.3)) {
            sourceGroup.removePanel(panel)
            
            if sourceGroup.panels.isEmpty {
                removePanelGroup(sourceGroup)
            }
            
            layout.floatingPanels.removeAll { $0.id == sourceGroup.id }
            
            panel.dock(to: position)
            addPanelToPosition(panel, position: position)
        }
    }
    
    public func movePanel(_ panel: DockPanel, to dropZone: DockDropZone) {
        guard case .position(let position) = dropZone else {
            handleComplexDrop(panel: panel, dropZone: dropZone)
            return
        }
        dockPanel(panel, to: position)
    }
    
    private func handleComplexDrop(panel: DockPanel, dropZone: DockDropZone) {
        switch dropZone {
        case .tab(let panelID, let index):
            guard let targetGroup = layout.findPanelGroup(containing: panelID),
                  let sourceGroup = layout.findPanelGroup(containing: panel.id) else { return }
            
            withAnimation(.spring(response: 0.3)) {
                sourceGroup.removePanel(panel)
                if sourceGroup.panels.isEmpty {
                    removePanelGroup(sourceGroup)
                }
                
                let insertIndex = min(index, targetGroup.panels.count)
                targetGroup.panels.insert(panel, at: insertIndex)
                targetGroup.activeTabIndex = insertIndex
            }
            
        case .split(let panelID, let splitPosition):
            splitAndDock(panel: panel, targetPanelID: panelID, splitPosition: splitPosition)
            
        default:
            break
        }
    }
    
    private func splitAndDock(panel: DockPanel, targetPanelID: DockPanelID, splitPosition: DockPosition) {
        guard let targetGroup = layout.findPanelGroup(containing: targetPanelID),
              let sourceGroup = layout.findPanelGroup(containing: panel.id) else { return }
        
        withAnimation(.spring(response: 0.3)) {
            sourceGroup.removePanel(panel)
            if sourceGroup.panels.isEmpty {
                removePanelGroup(sourceGroup)
            }
            
            let newGroup = DockPanelGroup(
                panels: [panel],
                position: targetGroup.position
            )
            
            let orientation: DockSplitOrientation = splitPosition.isHorizontalEdge ? .horizontal : .vertical
            let isFirstPosition = splitPosition == .left || splitPosition == .top
            
            let splitNode = DockSplitNode(
                orientation: orientation,
                first: isFirstPosition ? .panel(newGroup) : .panel(targetGroup),
                second: isFirstPosition ? .panel(targetGroup) : .panel(newGroup),
                splitRatio: 0.5
            )
            
            replacePanelGroupWithSplit(targetGroup, splitNode: splitNode)
        }
    }
    
    private func replacePanelGroupWithSplit(_ group: DockPanelGroup, splitNode: DockSplitNode) {
        for position in DockPosition.allCases {
            let node = layout.node(for: position)
            if let newNode = replaceInNode(node, group: group, with: .split(splitNode)) {
                layout.setNode(newNode, for: position)
                return
            }
        }
    }
    
    private func replaceInNode(_ node: DockLayoutNode, group: DockPanelGroup, with replacement: DockLayoutNode) -> DockLayoutNode? {
        switch node {
        case .panel(let panelGroup):
            if panelGroup.id == group.id {
                return replacement
            }
        case .split(let splitNode):
            if let newFirst = replaceInNode(splitNode.first, group: group, with: replacement) {
                splitNode.first = newFirst
                return .split(splitNode)
            }
            if let newSecond = replaceInNode(splitNode.second, group: group, with: replacement) {
                splitNode.second = newSecond
                return .split(splitNode)
            }
        case .empty:
            break
        }
        return nil
    }
    
    private func addPanelToPosition(_ panel: DockPanel, position: DockPosition) {
        let currentNode = layout.node(for: position)
        
        switch currentNode {
        case .empty:
            let group = DockPanelGroup(panels: [panel], position: position)
            layout.setNode(.panel(group), for: position)
            
        case .panel(let group):
            group.addPanel(panel)
            
        case .split:
            if let firstGroup = findFirstPanelGroup(in: currentNode) {
                firstGroup.addPanel(panel)
            }
        }
    }
    
    private func findFirstPanelGroup(in node: DockLayoutNode) -> DockPanelGroup? {
        switch node {
        case .panel(let group):
            return group
        case .split(let splitNode):
            return findFirstPanelGroup(in: splitNode.first) ?? findFirstPanelGroup(in: splitNode.second)
        case .empty:
            return nil
        }
    }
    
    private func removePanelGroup(_ group: DockPanelGroup) {
        for position in DockPosition.allCases {
            let node = layout.node(for: position)
            if let newNode = removeGroupFromNode(node, group: group) {
                layout.setNode(newNode, for: position)
                return
            }
        }
        
        layout.floatingPanels.removeAll { $0.id == group.id }
    }
    
    private func removeGroupFromNode(_ node: DockLayoutNode, group: DockPanelGroup) -> DockLayoutNode? {
        switch node {
        case .panel(let panelGroup):
            if panelGroup.id == group.id {
                return .empty
            }
        case .split(let splitNode):
            if case .panel(let firstGroup) = splitNode.first, firstGroup.id == group.id {
                return splitNode.second
            }
            if case .panel(let secondGroup) = splitNode.second, secondGroup.id == group.id {
                return splitNode.first
            }
            
            if let newFirst = removeGroupFromNode(splitNode.first, group: group) {
                splitNode.first = newFirst
                if case .empty = newFirst {
                    return splitNode.second
                }
                return .split(splitNode)
            }
            if let newSecond = removeGroupFromNode(splitNode.second, group: group) {
                splitNode.second = newSecond
                if case .empty = newSecond {
                    return splitNode.first
                }
                return .split(splitNode)
            }
        case .empty:
            break
        }
        return nil
    }
    
    // MARK: - Resize Actions
    
    public func startResize(position: DockPosition) {
        isResizing = true
        resizingPosition = position
    }
    
    public func updateResize(delta: CGFloat, position: DockPosition) {
        switch position {
        case .left:
            layout.leftWidth = max(100, layout.leftWidth + delta)
        case .right:
            layout.rightWidth = max(100, layout.rightWidth - delta)
        case .top:
            layout.topHeight = max(50, layout.topHeight + delta)
        case .bottom:
            layout.bottomHeight = max(50, layout.bottomHeight - delta)
        default:
            break
        }
    }
    
    public func endResize() {
        isResizing = false
        resizingPosition = nil
    }
    
    // MARK: - Drag Actions
    
    public func armDrag(_ panel: DockPanel) {
        pendingDragPanel = panel
        draggedPanel = nil
        dragHasMoved = false
        dropZone = .none
    }

    public func activatePendingDragIfNeeded() {
        if draggedPanel == nil, let panel = pendingDragPanel {
            draggedPanel = panel
            pendingDragPanel = nil
            dragHasMoved = false
            dropZone = .none
        }
    }

    public func startDrag(_ panel: DockPanel) {
        pendingDragPanel = nil
        draggedPanel = panel
        dragHasMoved = false
        dropZone = .none
    }

    public func markDragMovement() {
        guard draggedPanel != nil else { return }
        dragHasMoved = true
    }
    
    public func updateDropZone(_ zone: DockDropZone) {
        guard dropZone != zone else { return }
        withAnimation(.easeInOut(duration: 0.12)) {
            dropZone = zone
        }
    }
    
    public func endDrag() {
        if let panel = draggedPanel, dropZone != .none {
            movePanel(panel, to: dropZone)
        }
        draggedPanel = nil
        pendingDragPanel = nil
        dropZone = .none
        dragHasMoved = false
    }
    
    public func cancelDrag() {
        draggedPanel = nil
        pendingDragPanel = nil
        dropZone = .none
        dragHasMoved = false
    }
    
    // MARK: - State Persistence
    
    private static let persistenceKey = "DockLayoutState"
    
    /// Saves the current layout state to UserDefaults
    public func saveToUserDefaults() {
        let state = PersistedLayoutState(
            leftWidth: layout.leftWidth,
            rightWidth: layout.rightWidth,
            topHeight: layout.topHeight,
            bottomHeight: layout.bottomHeight,
            isLeftCollapsed: layout.isLeftCollapsed,
            isRightCollapsed: layout.isRightCollapsed,
            isTopCollapsed: layout.isTopCollapsed,
            isBottomCollapsed: layout.isBottomCollapsed
        )
        
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.persistenceKey)
        }
    }
    
    /// Loads the layout state from UserDefaults
    public func loadFromUserDefaults() {
        guard let data = UserDefaults.standard.data(forKey: Self.persistenceKey),
              let state = try? JSONDecoder().decode(PersistedLayoutState.self, from: data) else {
            return
        }
        
        layout.leftWidth = state.leftWidth
        layout.rightWidth = state.rightWidth
        layout.topHeight = state.topHeight
        layout.bottomHeight = state.bottomHeight
        layout.isLeftCollapsed = state.isLeftCollapsed
        layout.isRightCollapsed = state.isRightCollapsed
        layout.isTopCollapsed = state.isTopCollapsed
        layout.isBottomCollapsed = state.isBottomCollapsed
    }
    
    /// Clears persisted state
    public func clearPersistedState() {
        UserDefaults.standard.removeObject(forKey: Self.persistenceKey)
    }
}

// MARK: - Persisted Layout State

struct PersistedLayoutState: Codable {
    var leftWidth: CGFloat
    var rightWidth: CGFloat
    var topHeight: CGFloat
    var bottomHeight: CGFloat
    var isLeftCollapsed: Bool
    var isRightCollapsed: Bool
    var isTopCollapsed: Bool
    var isBottomCollapsed: Bool
}
