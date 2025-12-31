import SwiftUI

// MARK: - Main Dock Container

/// The main container view for the docking system
public struct DockContainer: View {
    @ObservedObject var state: DockState
    @Environment(\.dockTheme) var theme
    @State private var dragLocation: CGPoint = .zero
    @State private var containerSize: CGSize = .zero
    
    public init(state: DockState) {
        self.state = state
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main layout
                mainLayout(in: geometry.size)
                
                // Interactive drop zone overlay when dragging
                if state.draggedPanel != nil {
                    InteractiveDropZoneOverlay(
                        containerSize: geometry.size,
                        dragLocation: $dragLocation
                    )
                }
                
                // Floating panels
                floatingPanels(in: geometry.size)
                
                // Drag preview
                if let panel = state.draggedPanel {
                    DragPreviewView(panel: panel, location: dragLocation)
                }
                
                // Minimized panels bar
                if !state.layout.minimizedPanels.isEmpty {
                    minimizedPanelsBar
                }
            }
            .background(theme.colors.background)
            .onAppear { containerSize = geometry.size }
            .onChange(of: geometry.size) { _, newSize in containerSize = newSize }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if state.draggedPanel != nil {
                            dragLocation = value.location
                            updateDropZoneFromLocation(value.location, in: geometry.size)
                        }
                    }
                    .onEnded { _ in
                        if state.draggedPanel != nil {
                            state.endDrag()
                            dragLocation = .zero
                        }
                    }
            )
        }
    }
    
    private func updateDropZoneFromLocation(_ location: CGPoint, in size: CGSize) {
        let edgeThreshold: CGFloat = 80
        
        // Check edges first
        if location.x < edgeThreshold {
            state.updateDropZone(.position(.left))
        } else if location.x > size.width - edgeThreshold {
            state.updateDropZone(.position(.right))
        } else if location.y < edgeThreshold {
            state.updateDropZone(.position(.top))
        } else if location.y > size.height - edgeThreshold {
            state.updateDropZone(.position(.bottom))
        } else {
            // Check for split drop zones within center area
            if let splitDropZone = findSplitDropZone(at: location, in: size) {
                state.updateDropZone(splitDropZone)
            } else {
                state.updateDropZone(.position(.center))
            }
        }
    }
    
    private func findSplitDropZone(at location: CGPoint, in size: CGSize) -> DockDropZone? {
        // Check all zones, not just center
        let layout = state.layout
        
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        
        // Check top zone
        if !isNodeEmpty(layout.topNode) {
            let topHeight = layout.isTopCollapsed ? theme.spacing.collapsedWidth : layout.topHeight
            let topFrame = CGRect(x: 0, y: 0, width: size.width, height: topHeight)
            if topFrame.contains(location) {
                return findSplitDropZoneInNode(layout.topNode, at: location, in: size, containerFrame: topFrame)
            }
            currentY += topHeight
        }
        
        // Check middle section (left, center, right)
        var leftWidth: CGFloat = 0
        var rightWidth: CGFloat = 0
        
        // Check left zone
        if !isNodeEmpty(layout.leftNode) {
            leftWidth = layout.isLeftCollapsed ? theme.spacing.collapsedWidth : layout.leftWidth
            let leftFrame = CGRect(x: 0, y: currentY, width: leftWidth, height: size.height - currentY)
            if leftFrame.contains(location) {
                return findSplitDropZoneInNode(layout.leftNode, at: location, in: size, containerFrame: leftFrame)
            }
        }
        
        // Check right zone
        if !isNodeEmpty(layout.rightNode) {
            rightWidth = layout.isRightCollapsed ? theme.spacing.collapsedWidth : layout.rightWidth
            let rightFrame = CGRect(x: size.width - rightWidth, y: currentY, width: rightWidth, height: size.height - currentY)
            if rightFrame.contains(location) {
                return findSplitDropZoneInNode(layout.rightNode, at: location, in: size, containerFrame: rightFrame)
            }
        }
        
        // Check center zone
        if !isNodeEmpty(layout.centerNode) {
            let centerFrame = CGRect(
                x: leftWidth,
                y: currentY,
                width: size.width - leftWidth - rightWidth,
                height: size.height - currentY
            )
            
            if centerFrame.contains(location) {
                return findSplitDropZoneInNode(layout.centerNode, at: location, in: size, containerFrame: centerFrame)
            }
        }
        
        // Check bottom zone
        if !isNodeEmpty(layout.bottomNode) {
            let bottomHeight = layout.isBottomCollapsed ? theme.spacing.collapsedWidth : layout.bottomHeight
            let bottomFrame = CGRect(x: 0, y: size.height - bottomHeight, width: size.width, height: bottomHeight)
            if bottomFrame.contains(location) {
                return findSplitDropZoneInNode(layout.bottomNode, at: location, in: size, containerFrame: bottomFrame)
            }
        }
        
        return nil
    }
    
    private func findSplitDropZoneInNode(_ node: DockLayoutNode, at location: CGPoint, in containerSize: CGSize, containerFrame: CGRect) -> DockDropZone? {
        switch node {
        case .panel(let group):
            // Check if we can split this panel
            if let panel = group.activePanel {
                if containerFrame.contains(location) {
                    return findSplitPositionInPanel(panel, at: location, panelFrame: containerFrame)
                }
            }
            
        case .split(let splitNode):
            // Calculate frames for children based on split orientation and ratio
            let (firstFrame, secondFrame) = calculateSplitFrames(
                orientation: splitNode.orientation,
                ratio: splitNode.splitRatio,
                containerFrame: containerFrame
            )
            
            // Recursively check children
            if firstFrame.contains(location) {
                return findSplitDropZoneInNode(splitNode.first, at: location, in: containerSize, containerFrame: firstFrame)
            } else if secondFrame.contains(location) {
                return findSplitDropZoneInNode(splitNode.second, at: location, in: containerSize, containerFrame: secondFrame)
            }
            
        case .empty:
            break
        }
        
        return nil
    }
    
    private func calculateSplitFrames(orientation: DockSplitOrientation, ratio: CGFloat, containerFrame: CGRect) -> (CGRect, CGRect) {
        switch orientation {
        case .horizontal:
            let firstWidth = containerFrame.width * ratio
            let firstFrame = CGRect(
                x: containerFrame.minX,
                y: containerFrame.minY,
                width: firstWidth,
                height: containerFrame.height
            )
            let secondFrame = CGRect(
                x: containerFrame.minX + firstWidth,
                y: containerFrame.minY,
                width: containerFrame.width - firstWidth,
                height: containerFrame.height
            )
            return (firstFrame, secondFrame)
            
        case .vertical:
            let firstHeight = containerFrame.height * ratio
            let firstFrame = CGRect(
                x: containerFrame.minX,
                y: containerFrame.minY,
                width: containerFrame.width,
                height: firstHeight
            )
            let secondFrame = CGRect(
                x: containerFrame.minX,
                y: containerFrame.minY + firstHeight,
                width: containerFrame.width,
                height: containerFrame.height - firstHeight
            )
            return (firstFrame, secondFrame)
        }
    }
    
    private func findSplitPositionInPanel(_ panel: DockPanel, at location: CGPoint, panelFrame: CGRect) -> DockDropZone? {
        let localLocation = CGPoint(
            x: location.x - panelFrame.minX,
            y: location.y - panelFrame.minY
        )
        
        let panelSize = panelFrame.size
        let threshold: CGFloat = 40
        
        // Check edges of this specific panel
        if localLocation.x < threshold {
            return .split(panelID: panel.id, position: .left)
        } else if localLocation.x > panelSize.width - threshold {
            return .split(panelID: panel.id, position: .right)
        } else if localLocation.y < threshold {
            return .split(panelID: panel.id, position: .top)
        } else if localLocation.y > panelSize.height - threshold {
            return .split(panelID: panel.id, position: .bottom)
        }
        
        // Check for tab drop zone (center area)
        return .tab(panelID: panel.id, index: 0)
    }
    
    // MARK: - Main Layout
    
    @ViewBuilder
    private func mainLayout(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            // Top panel
            if !isNodeEmpty(state.layout.topNode) {
                topSection(in: size)
            }
            
            // Middle section (left, center, right)
            HStack(spacing: 0) {
                // Left panel
                if !isNodeEmpty(state.layout.leftNode) {
                    leftSection(in: size)
                }
                
                // Center area
                centerSection(in: size)
                
                // Right panel
                if !isNodeEmpty(state.layout.rightNode) {
                    rightSection(in: size)
                }
            }
            
            // Bottom panel
            if !isNodeEmpty(state.layout.bottomNode) {
                bottomSection(in: size)
            }
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private func leftSection(in size: CGSize) -> some View {
        HStack(spacing: 0) {
            DockRegionView(
                node: state.layout.leftNode,
                position: .left,
                isCollapsed: state.layout.isLeftCollapsed,
                size: CGSize(
                    width: state.layout.isLeftCollapsed ? theme.spacing.collapsedWidth : state.layout.leftWidth,
                    height: size.height
                )
            )
            .frame(width: state.layout.isLeftCollapsed ? theme.spacing.collapsedWidth : state.layout.leftWidth)
            
            DockResizeHandle(
                position: .left,
                onResize: { delta in
                    state.layout.leftWidth = max(100, state.layout.leftWidth + delta)
                }
            )
        }
    }
    
    @ViewBuilder
    private func rightSection(in size: CGSize) -> some View {
        HStack(spacing: 0) {
            DockResizeHandle(
                position: .right,
                onResize: { delta in
                    state.layout.rightWidth = max(100, state.layout.rightWidth - delta)
                }
            )
            
            DockRegionView(
                node: state.layout.rightNode,
                position: .right,
                isCollapsed: state.layout.isRightCollapsed,
                size: CGSize(
                    width: state.layout.isRightCollapsed ? theme.spacing.collapsedWidth : state.layout.rightWidth,
                    height: size.height
                )
            )
            .frame(width: state.layout.isRightCollapsed ? theme.spacing.collapsedWidth : state.layout.rightWidth)
        }
    }
    
    @ViewBuilder
    private func topSection(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            DockRegionView(
                node: state.layout.topNode,
                position: .top,
                isCollapsed: state.layout.isTopCollapsed,
                size: CGSize(
                    width: size.width,
                    height: state.layout.isTopCollapsed ? theme.spacing.collapsedWidth : state.layout.topHeight
                )
            )
            .frame(height: state.layout.isTopCollapsed ? theme.spacing.collapsedWidth : state.layout.topHeight)
            
            DockResizeHandle(
                position: .top,
                onResize: { delta in
                    state.layout.topHeight = max(50, state.layout.topHeight + delta)
                }
            )
        }
    }
    
    @ViewBuilder
    private func bottomSection(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            DockResizeHandle(
                position: .bottom,
                onResize: { delta in
                    state.layout.bottomHeight = max(50, state.layout.bottomHeight - delta)
                }
            )
            
            DockRegionView(
                node: state.layout.bottomNode,
                position: .bottom,
                isCollapsed: state.layout.isBottomCollapsed,
                size: CGSize(
                    width: size.width,
                    height: state.layout.isBottomCollapsed ? theme.spacing.collapsedWidth : state.layout.bottomHeight
                )
            )
            .frame(height: state.layout.isBottomCollapsed ? theme.spacing.collapsedWidth : state.layout.bottomHeight)
        }
    }
    
    @ViewBuilder
    private func centerSection(in size: CGSize) -> some View {
        DockRegionView(
            node: state.layout.centerNode,
            position: .center,
            isCollapsed: false,
            size: size
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
        
    // MARK: - Floating Panels
    
    @ViewBuilder
    private func floatingPanels(in size: CGSize) -> some View {
        ForEach(state.layout.floatingPanels) { group in
            FloatingPanelView(group: group, containerSize: size)
        }
    }
    
    // MARK: - Minimized Panels Bar
    
    private var minimizedPanelsBar: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 8) {
                ForEach(state.layout.minimizedPanels, id: \.id) { panel in
                    MinimizedPanelButton(panel: panel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.colors.secondaryBackground)
                    .shadow(color: theme.colors.shadowColor, radius: 8, y: 2)
            )
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Helpers
    
    private func isNodeEmpty(_ node: DockLayoutNode) -> Bool {
        if case .empty = node {
            return true
        }
        return false
    }
}

// MARK: - Interactive Drop Zone Overlay

struct InteractiveDropZoneOverlay: View {
    let containerSize: CGSize
    @Binding var dragLocation: CGPoint
    @EnvironmentObject var state: DockState
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            // Drop zone indicators at edges
            dropZoneIndicators
            
            // Highlight for current drop zone
            currentDropZoneHighlight
        }
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private var dropZoneIndicators: some View {
        // Left indicator
        DropZoneIndicator(
            position: .left,
            isActive: isDropZone(.left),
            containerSize: containerSize
        )
        
        // Right indicator
        DropZoneIndicator(
            position: .right,
            isActive: isDropZone(.right),
            containerSize: containerSize
        )
        
        // Top indicator
        DropZoneIndicator(
            position: .top,
            isActive: isDropZone(.top),
            containerSize: containerSize
        )
        
        // Bottom indicator
        DropZoneIndicator(
            position: .bottom,
            isActive: isDropZone(.bottom),
            containerSize: containerSize
        )
        
        // Center indicator
        DropZoneIndicator(
            position: .center,
            isActive: isDropZone(.center),
            containerSize: containerSize
        )
    }
    
    @ViewBuilder
    private var currentDropZoneHighlight: some View {
        switch state.dropZone {
        case .position(let position):
            let frame = dropZoneFrame(for: position)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.colors.dropZoneBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            theme.colors.accent,
                            style: StrokeStyle(lineWidth: 3, dash: [8, 4])
                        )
                )
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .animation(.easeInOut(duration: 0.2), value: state.dropZone)
                
        case .split(let panelID, let position):
            if let frame = findPanelFrame(panelID: panelID) {
                let splitFrame = calculateSplitHighlightFrame(for: position, in: frame)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.colors.dropZoneBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(
                                theme.colors.accent,
                                style: StrokeStyle(lineWidth: 2, dash: [6, 3])
                            )
                    )
                    .frame(width: splitFrame.width, height: splitFrame.height)
                    .position(x: splitFrame.midX, y: splitFrame.midY)
                    .animation(.easeInOut(duration: 0.15), value: state.dropZone)
            }
            
        case .tab(let panelID, _):
            if let frame = findPanelFrame(panelID: panelID) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.colors.dropZoneBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                theme.colors.accent,
                                style: StrokeStyle(lineWidth: 3, dash: [8, 4])
                            )
                    )
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
                    .animation(.easeInOut(duration: 0.2), value: state.dropZone)
            }
            
        case .none:
            EmptyView()
        }
    }
    
    private func isDropZone(_ position: DockPosition) -> Bool {
        if case .position(let p) = state.dropZone {
            return p == position
        }
        return false
    }
    
    private func dropZoneFrame(for position: DockPosition) -> CGRect {
        switch position {
        case .left:
            return CGRect(x: 0, y: 0, width: min(250, containerSize.width * 0.25), height: containerSize.height)
        case .right:
            let width = min(250, containerSize.width * 0.25)
            return CGRect(x: containerSize.width - width, y: 0, width: width, height: containerSize.height)
        case .top:
            return CGRect(x: 0, y: 0, width: containerSize.width, height: min(200, containerSize.height * 0.25))
        case .bottom:
            let height = min(200, containerSize.height * 0.25)
            return CGRect(x: 0, y: containerSize.height - height, width: containerSize.width, height: height)
        case .center:
            let margin = containerSize.width * 0.15
            return CGRect(
                x: margin,
                y: margin,
                width: containerSize.width - margin * 2,
                height: containerSize.height - margin * 2
            )
        case .floating:
            return .zero
        }
    }
    
    private func findPanelFrame(panelID: DockPanelID) -> CGRect? {
        // Search through all zones to find the panel's frame
        let layout = state.layout
        let size = containerSize
        
        var currentY: CGFloat = 0
        
        // Check top zone
        if !isNodeEmpty(layout.topNode) {
            let topHeight = layout.isTopCollapsed ? theme.spacing.collapsedWidth : layout.topHeight
            let topFrame = CGRect(x: 0, y: 0, width: size.width, height: topHeight)
            if let frame = findPanelFrameInNode(layout.topNode, panelID: panelID, containerFrame: topFrame) {
                return frame
            }
            currentY += topHeight
        }
        
        // Check middle section (left, center, right)
        var leftWidth: CGFloat = 0
        var rightWidth: CGFloat = 0
        
        // Check left zone
        if !isNodeEmpty(layout.leftNode) {
            leftWidth = layout.isLeftCollapsed ? theme.spacing.collapsedWidth : layout.leftWidth
            let leftFrame = CGRect(x: 0, y: currentY, width: leftWidth, height: size.height - currentY)
            if let frame = findPanelFrameInNode(layout.leftNode, panelID: panelID, containerFrame: leftFrame) {
                return frame
            }
        }
        
        // Check right zone
        if !isNodeEmpty(layout.rightNode) {
            rightWidth = layout.isRightCollapsed ? theme.spacing.collapsedWidth : layout.rightWidth
            let rightFrame = CGRect(x: size.width - rightWidth, y: currentY, width: rightWidth, height: size.height - currentY)
            if let frame = findPanelFrameInNode(layout.rightNode, panelID: panelID, containerFrame: rightFrame) {
                return frame
            }
        }
        
        // Check center zone
        if !isNodeEmpty(layout.centerNode) {
            let centerFrame = CGRect(
                x: leftWidth,
                y: currentY,
                width: size.width - leftWidth - rightWidth,
                height: size.height - currentY
            )
            
            if let frame = findPanelFrameInNode(layout.centerNode, panelID: panelID, containerFrame: centerFrame) {
                return frame
            }
        }
        
        // Check bottom zone
        if !isNodeEmpty(layout.bottomNode) {
            let bottomHeight = layout.isBottomCollapsed ? theme.spacing.collapsedWidth : layout.bottomHeight
            let bottomFrame = CGRect(x: 0, y: size.height - bottomHeight, width: size.width, height: bottomHeight)
            if let frame = findPanelFrameInNode(layout.bottomNode, panelID: panelID, containerFrame: bottomFrame) {
                return frame
            }
        }
        
        return nil
    }
    
    private func findPanelFrameInNode(_ node: DockLayoutNode, panelID: DockPanelID, containerFrame: CGRect) -> CGRect? {
        switch node {
        case .panel(let group):
            if let panel = group.panels.first(where: { $0.id == panelID }) {
                return containerFrame
            }
            
        case .split(let splitNode):
            let (firstFrame, secondFrame) = calculateSplitFramesForNode(
                orientation: splitNode.orientation,
                ratio: splitNode.splitRatio,
                containerFrame: containerFrame
            )
            
            if let frame = findPanelFrameInNode(splitNode.first, panelID: panelID, containerFrame: firstFrame) {
                return frame
            }
            if let frame = findPanelFrameInNode(splitNode.second, panelID: panelID, containerFrame: secondFrame) {
                return frame
            }
            
        case .empty:
            break
        }
        
        return nil
    }
    
    private func calculateSplitFramesForNode(orientation: DockSplitOrientation, ratio: CGFloat, containerFrame: CGRect) -> (CGRect, CGRect) {
        switch orientation {
        case .horizontal:
            let firstWidth = containerFrame.width * ratio
            let firstFrame = CGRect(
                x: containerFrame.minX,
                y: containerFrame.minY,
                width: firstWidth,
                height: containerFrame.height
            )
            let secondFrame = CGRect(
                x: containerFrame.minX + firstWidth,
                y: containerFrame.minY,
                width: containerFrame.width - firstWidth,
                height: containerFrame.height
            )
            return (firstFrame, secondFrame)
            
        case .vertical:
            let firstHeight = containerFrame.height * ratio
            let firstFrame = CGRect(
                x: containerFrame.minX,
                y: containerFrame.minY,
                width: containerFrame.width,
                height: firstHeight
            )
            let secondFrame = CGRect(
                x: containerFrame.minX,
                y: containerFrame.minY + firstHeight,
                width: containerFrame.width,
                height: containerFrame.height - firstHeight
            )
            return (firstFrame, secondFrame)
        }
    }
    
    private func isNodeEmpty(_ node: DockLayoutNode) -> Bool {
        if case .empty = node {
            return true
        }
        return false
    }
    
    private func calculateSplitHighlightFrame(for position: DockPosition, in panelFrame: CGRect) -> CGRect {
        let inset: CGFloat = 20
        let thickness: CGFloat = 60
        
        switch position {
        case .left:
            return CGRect(
                x: panelFrame.minX,
                y: panelFrame.minY,
                width: thickness,
                height: panelFrame.height
            )
        case .right:
            return CGRect(
                x: panelFrame.maxX - thickness,
                y: panelFrame.minY,
                width: thickness,
                height: panelFrame.height
            )
        case .top:
            return CGRect(
                x: panelFrame.minX,
                y: panelFrame.minY,
                width: panelFrame.width,
                height: thickness
            )
        case .bottom:
            return CGRect(
                x: panelFrame.minX,
                y: panelFrame.maxY - thickness,
                width: panelFrame.width,
                height: thickness
            )
        default:
            return panelFrame.insetBy(dx: inset, dy: inset)
        }
    }
}

// MARK: - Drop Zone Indicator

struct DropZoneIndicator: View {
    let position: DockPosition
    let isActive: Bool
    let containerSize: CGSize
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        let frame = indicatorFrame
        
        ZStack {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(isActive ? .white : theme.colors.secondaryText)
        }
        .frame(width: 60, height: 60)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? theme.colors.accent : theme.colors.secondaryBackground.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        )
        .position(x: frame.midX, y: frame.midY)
        .scaleEffect(isActive ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
    
    private var iconName: String {
        switch position {
        case .left: return "arrow.left.to.line"
        case .right: return "arrow.right.to.line"
        case .top: return "arrow.up.to.line"
        case .bottom: return "arrow.down.to.line"
        case .center: return "rectangle.center.inset.filled"
        case .floating: return "uiwindow.split.2x1"
        }
    }
    
    private var indicatorFrame: CGRect {
        let padding: CGFloat = 40
        switch position {
        case .left:
            return CGRect(x: padding, y: containerSize.height / 2, width: 60, height: 60)
        case .right:
            return CGRect(x: containerSize.width - padding, y: containerSize.height / 2, width: 60, height: 60)
        case .top:
            return CGRect(x: containerSize.width / 2, y: padding, width: 60, height: 60)
        case .bottom:
            return CGRect(x: containerSize.width / 2, y: containerSize.height - padding, width: 60, height: 60)
        case .center:
            return CGRect(x: containerSize.width / 2, y: containerSize.height / 2, width: 60, height: 60)
        case .floating:
            return .zero
        }
    }
}

// MARK: - Drag Preview View

struct DragPreviewView: View {
    let panel: DockPanel
    let location: CGPoint
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        if location != .zero {
            HStack(spacing: 8) {
                if let icon = panel.icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(theme.colors.accent)
                }
                
                Text(panel.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.colors.text)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.colors.panelBackground)
                    .shadow(color: theme.colors.shadowColor, radius: 16, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(theme.colors.accent, lineWidth: 2)
            )
            .position(x: location.x, y: location.y - 40)
        }
    }
}

// MARK: - Minimized Panel Button

struct MinimizedPanelButton: View {
    let panel: DockPanel
    @EnvironmentObject var state: DockState
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        Button(action: { panel.expand() }) {
            HStack(spacing: 4) {
                if let icon = panel.icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(panel.title)
                    .font(.system(size: 11))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(theme.colors.tertiaryBackground)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
