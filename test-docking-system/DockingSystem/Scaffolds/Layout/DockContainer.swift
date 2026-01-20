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
                        guard state.draggedPanel != nil else { return }
                        
                        if state.dropZone == .none {
                            state.cancelDrag()
                        } else {
                            state.endDrag()
                        }
                        
                        dragLocation = .zero
                    }
            )
        }
    }
}

// MARK: - Helper Functions

private func isNodeEmptyCheck(_ node: DockLayoutNode) -> Bool {
    if case .empty = node {
        return true
    }
    return false
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
            
            // Inner panel indicators
            panelSplitIndicators
            
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
    private var panelSplitIndicators: some View {
        ForEach(panelFrames) { info in
            let highlight = highlightPosition(for: info.panelID)
            let isHovered = info.frame.contains(dragLocation) && state.draggedPanel != nil
            
            if highlight != nil || isHovered {
                PanelSplitIndicatorView(
                    highlightPosition: highlight,
                    isHovered: isHovered
                )
                .frame(width: info.frame.width, height: info.frame.height)
                .position(x: info.frame.midX, y: info.frame.midY)
            }
        }
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
    
    private func highlightPosition(for panelID: DockPanelID) -> DockPosition? {
        switch state.dropZone {
        case .split(let targetID, let position) where targetID == panelID:
            return position
        case .tab(let targetID, _) where targetID == panelID:
            return .center
        default:
            return nil
        }
    }
    
    private var panelFrames: [PanelFrameInfo] {
        var frames: [PanelFrameInfo] = []
        let layout = state.layout
        let size = containerSize
        
        var currentY: CGFloat = 0
        
        if !isNodeEmptyCheck(layout.topNode) {
            let topHeight = layout.isTopCollapsed ? theme.spacing.collapsedWidth : layout.topHeight
            let topFrame = CGRect(x: 0, y: 0, width: size.width, height: topHeight)
            collectPanelFramesInNode(layout.topNode, frame: topFrame, result: &frames)
            currentY += topHeight
        }
        
        var leftWidth: CGFloat = 0
        var rightWidth: CGFloat = 0
        
        if !isNodeEmptyCheck(layout.leftNode) {
            leftWidth = layout.isLeftCollapsed ? theme.spacing.collapsedWidth : layout.leftWidth
            let leftFrame = CGRect(x: 0, y: currentY, width: leftWidth, height: size.height - currentY)
            collectPanelFramesInNode(layout.leftNode, frame: leftFrame, result: &frames)
        }
        
        if !isNodeEmptyCheck(layout.rightNode) {
            rightWidth = layout.isRightCollapsed ? theme.spacing.collapsedWidth : layout.rightWidth
            let rightFrame = CGRect(x: size.width - rightWidth, y: currentY, width: rightWidth, height: size.height - currentY)
            collectPanelFramesInNode(layout.rightNode, frame: rightFrame, result: &frames)
        }
        
        if !isNodeEmptyCheck(layout.centerNode) {
            let centerFrame = CGRect(
                x: leftWidth,
                y: currentY,
                width: size.width - leftWidth - rightWidth,
                height: size.height - currentY
            )
            collectPanelFramesInNode(layout.centerNode, frame: centerFrame, result: &frames)
        }
        
        if !isNodeEmptyCheck(layout.bottomNode) {
            let bottomHeight = layout.isBottomCollapsed ? theme.spacing.collapsedWidth : layout.bottomHeight
            let bottomFrame = CGRect(x: 0, y: size.height - bottomHeight, width: size.width, height: bottomHeight)
            collectPanelFramesInNode(layout.bottomNode, frame: bottomFrame, result: &frames)
        }
        
        return frames
    }
    
    private func collectPanelFramesInNode(_ node: DockLayoutNode, frame: CGRect, result: inout [PanelFrameInfo]) {
        switch node {
        case .panel(let group):
            if let panel = group.activePanel {
                result.append(PanelFrameInfo(panelID: panel.id, frame: frame))
            }
        case .split(let splitNode):
            let (firstFrame, secondFrame) = calculateSplitFramesForNode(
                orientation: splitNode.orientation,
                ratio: splitNode.splitRatio,
                containerFrame: frame
            )
            collectPanelFramesInNode(splitNode.first, frame: firstFrame, result: &result)
            collectPanelFramesInNode(splitNode.second, frame: secondFrame, result: &result)
        case .empty:
            break
        }
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
    
    private struct PanelFrameInfo: Identifiable {
        let panelID: DockPanelID
        let frame: CGRect
        
        var id: DockPanelID { panelID }
    }
    
    private func findPanelFrame(panelID: DockPanelID) -> CGRect? {
        let layout = state.layout
        let size = containerSize
        
        var currentY: CGFloat = 0
        
        if !isNodeEmptyCheck(layout.topNode) {
            let topHeight = layout.isTopCollapsed ? theme.spacing.collapsedWidth : layout.topHeight
            let topFrame = CGRect(x: 0, y: 0, width: size.width, height: topHeight)
            if let frame = findPanelFrameInNode(layout.topNode, panelID: panelID, containerFrame: topFrame) {
                return frame
            }
            currentY += topHeight
        }
        
        var leftWidth: CGFloat = 0
        var rightWidth: CGFloat = 0
        
        if !isNodeEmptyCheck(layout.leftNode) {
            leftWidth = layout.isLeftCollapsed ? theme.spacing.collapsedWidth : layout.leftWidth
            let leftFrame = CGRect(x: 0, y: currentY, width: leftWidth, height: size.height - currentY)
            if let frame = findPanelFrameInNode(layout.leftNode, panelID: panelID, containerFrame: leftFrame) {
                return frame
            }
        }
        
        if !isNodeEmptyCheck(layout.rightNode) {
            rightWidth = layout.isRightCollapsed ? theme.spacing.collapsedWidth : layout.rightWidth
            let rightFrame = CGRect(x: size.width - rightWidth, y: currentY, width: rightWidth, height: size.height - currentY)
            if let frame = findPanelFrameInNode(layout.rightNode, panelID: panelID, containerFrame: rightFrame) {
                return frame
            }
        }
        
        if !isNodeEmptyCheck(layout.centerNode) {
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
        
        if !isNodeEmptyCheck(layout.bottomNode) {
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

// MARK: - Panel Split Indicator View

private struct PanelSplitIndicatorView: View {
    let highlightPosition: DockPosition?
    let isHovered: Bool
    @Environment(\.dockTheme) var theme
    
    private let edgePadding: CGFloat = 12
    private let edgeLength: CGFloat = 32
    private let edgeThickness: CGFloat = 8
    private let centerSize: CGFloat = 22
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            
            ZStack {
                edgeIndicator(in: size, position: .top, icon: "chevron.up")
                edgeIndicator(in: size, position: .bottom, icon: "chevron.down")
                edgeIndicator(in: size, position: .left, icon: "chevron.left")
                edgeIndicator(in: size, position: .right, icon: "chevron.right")
                
                if highlightPosition == .center {
                    centerIndicator(in: size)
                }
            }
            .opacity((isHovered || highlightPosition != nil) ? 1 : 0)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
            .animation(.easeInOut(duration: 0.12), value: highlightPosition)
        }
    }
    
    @ViewBuilder
    private func edgeIndicator(in size: CGSize, position: DockPosition, icon: String) -> some View {
        let isActive = highlightPosition == position
        let baseColor = theme.colors.secondaryBackground.opacity(0.85)
        let activeColor = theme.colors.accent
        let textColor = isActive ? Color.white : theme.colors.secondaryText
        
        Capsule()
            .fill(isActive ? activeColor : baseColor)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(textColor)
            )
            .frame(width: width(for: position), height: height(for: position))
            .position(positionPoint(for: position, in: size))
            .shadow(color: theme.colors.shadowColor.opacity(isActive ? 0.6 : 0.3), radius: 4, y: 2)
            .scaleEffect(isActive ? 1.1 : 1.0)
    }
    
    private func centerIndicator(in size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .strokeBorder(theme.colors.accent, lineWidth: 2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.colors.dropZoneBackground)
            )
            .frame(width: centerSize, height: centerSize)
            .position(x: size.width / 2, y: size.height / 2)
            .shadow(color: theme.colors.shadowColor.opacity(0.5), radius: 4, y: 2)
    }
    
    private func width(for position: DockPosition) -> CGFloat {
        position.isHorizontalEdge ? edgeLength : edgeThickness
    }
    
    private func height(for position: DockPosition) -> CGFloat {
        position.isHorizontalEdge ? edgeThickness : edgeLength
    }
    
    private func positionPoint(for position: DockPosition, in size: CGSize) -> CGPoint {
        switch position {
        case .left:
            return CGPoint(x: edgePadding + edgeLength / 2, y: size.height / 2)
        case .right:
            return CGPoint(x: size.width - edgePadding - edgeLength / 2, y: size.height / 2)
        case .top:
            return CGPoint(x: size.width / 2, y: edgePadding + edgeLength / 2)
        case .bottom:
            return CGPoint(x: size.width / 2, y: size.height - edgePadding - edgeLength / 2)
        default:
            return CGPoint(x: size.width / 2, y: size.height / 2)
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
