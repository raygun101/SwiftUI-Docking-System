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

func isNodeEmptyCheck(_ node: DockLayoutNode) -> Bool {
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
            
            // Highlight for current drop zone (rendered beneath indicators)
            currentDropZoneHighlight
                .zIndex(0)
            
            // Inner panel indicators
            panelSplitIndicators
                .zIndex(3)
            
            // Drop zone indicators at edges
            dropZoneIndicators
                .zIndex(2)
        }
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private var dropZoneIndicators: some View {
        ZStack {
            DropZoneIndicator(position: .left, isActive: isDropZone(.left), frame: edgeIndicatorFrame(for: .left))
            DropZoneIndicator(position: .right, isActive: isDropZone(.right), frame: edgeIndicatorFrame(for: .right))
            DropZoneIndicator(position: .top, isActive: isDropZone(.top), frame: edgeIndicatorFrame(for: .top))
            DropZoneIndicator(position: .bottom, isActive: isDropZone(.bottom), frame: edgeIndicatorFrame(for: .bottom))
            DropZoneIndicator(position: .center, isActive: isDropZone(.center), frame: centerIndicatorFrame)
        }
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
                .frame(
                    width: max(0, info.frame.width - 32),
                    height: max(0, info.frame.height - 32)
                )
                .position(x: info.frame.midX, y: info.frame.midY)
                .zIndex(3)
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
        let metrics = layoutMetrics(in: containerSize)
        return dropZoneFrame(for: position, metrics: metrics, size: containerSize)
    }

    func dropZoneFrame(for position: DockPosition, metrics: LayoutMetrics, size: CGSize) -> CGRect {
        let defaultSideWidth = min(250, size.width * 0.25)
        let defaultVerticalHeight = min(200, size.height * 0.25)
        let centerFrame = metrics.centerFrame
        
        switch position {
        case .left:
            let width = metrics.leftDockWidth > 0 ? metrics.leftDockWidth : defaultSideWidth
            return CGRect(
                x: 0,
                y: centerFrame.minY,
                width: width,
                height: centerFrame.height
            )
        case .right:
            let width = metrics.rightDockWidth > 0 ? metrics.rightDockWidth : defaultSideWidth
            return CGRect(
                x: max(size.width - width, 0),
                y: centerFrame.minY,
                width: width,
                height: centerFrame.height
            )
        case .top:
            let height = metrics.topHeight > 0 ? metrics.topHeight : defaultVerticalHeight
            return CGRect(x: 0, y: 0, width: size.width, height: min(height, size.height))
        case .bottom:
            let height = metrics.bottomHeight > 0 ? metrics.bottomHeight : defaultVerticalHeight
            let clampedHeight = min(height, size.height)
            return CGRect(x: 0, y: max(size.height - clampedHeight, 0), width: size.width, height: clampedHeight)
        case .center:
            let margin: CGFloat = 36
            guard centerFrame.width > 0, centerFrame.height > 0 else { return centerFrame }
            let insetX = min(margin, centerFrame.width / 2)
            let insetY = min(margin, centerFrame.height / 2)
            return centerFrame.insetBy(dx: insetX, dy: insetY)
        case .floating:
            return .zero
        }
    }
    
    func layoutMetrics(in size: CGSize) -> LayoutMetrics {
        let layout = state.layout
        let collapsed = theme.spacing.collapsedWidth
        let leftWidth = isNodeEmptyCheck(layout.leftNode)
            ? 0
            : (layout.isLeftCollapsed ? collapsed : layout.leftWidth)
        let rightWidth = isNodeEmptyCheck(layout.rightNode)
            ? 0
            : (layout.isRightCollapsed ? collapsed : layout.rightWidth)
        let topHeight = isNodeEmptyCheck(layout.topNode)
            ? 0
            : (layout.isTopCollapsed ? collapsed : layout.topHeight)
        let bottomHeight = isNodeEmptyCheck(layout.bottomNode)
            ? 0
            : (layout.isBottomCollapsed ? collapsed : layout.bottomHeight)
        
        let constrainedLeft = min(max(0, leftWidth), size.width * 0.5)
        let constrainedRight = min(max(0, rightWidth), size.width * 0.5)
        let constrainedTop = min(max(0, topHeight), size.height * 0.5)
        let constrainedBottom = min(max(0, bottomHeight), size.height * 0.5)

        let centerWidth = max(0, size.width - constrainedLeft - constrainedRight)
        let centerHeight = max(0, size.height - constrainedTop - constrainedBottom)
        let centerFrame = CGRect(
            x: constrainedLeft,
            y: constrainedTop,
            width: centerWidth,
            height: centerHeight
        )
        
        return LayoutMetrics(
            leftDockWidth: constrainedLeft,
            rightDockWidth: constrainedRight,
            topHeight: constrainedTop,
            bottomHeight: constrainedBottom,
            centerFrame: centerFrame
        )
    }

    private func edgeIndicatorFrame(for position: DockPosition) -> CGRect {
        let frame = dropZoneFrame(for: position)
        let offset: CGFloat = min(36, min(frame.width, frame.height) / 3)
        switch position {
        case .left:
            return CGRect(x: frame.minX + offset, y: frame.midY, width: 56, height: 56)
        case .right:
            return CGRect(x: frame.maxX - offset, y: frame.midY, width: 56, height: 56)
        case .top:
            return CGRect(x: frame.midX, y: frame.minY + offset, width: 56, height: 56)
        case .bottom:
            return CGRect(x: frame.midX, y: frame.maxY - offset, width: 56, height: 56)
        default:
            return CGRect(x: frame.midX, y: frame.midY, width: 56, height: 56)
        }
    }
    
    private var centerIndicatorFrame: CGRect {
        let frame = dropZoneFrame(for: .center)
        return CGRect(x: frame.midX, y: frame.midY, width: 56, height: 56)
    }

    struct LayoutMetrics {
        let leftDockWidth: CGFloat
        let rightDockWidth: CGFloat
        let topHeight: CGFloat
        let bottomHeight: CGFloat
        let centerFrame: CGRect
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
        let metrics = layoutMetrics(in: containerSize)
        
        if metrics.topHeight > 0, !isNodeEmptyCheck(layout.topNode) {
            let topFrame = CGRect(x: 0, y: 0, width: containerSize.width, height: metrics.topHeight)
            collectPanelFramesInNode(layout.topNode, frame: topFrame, result: &frames)
        }
        
        if metrics.leftDockWidth > 0, metrics.centerFrame.height > 0, !isNodeEmptyCheck(layout.leftNode) {
            let leftFrame = CGRect(
                x: 0,
                y: metrics.centerFrame.minY,
                width: metrics.leftDockWidth,
                height: metrics.centerFrame.height
            )
            collectPanelFramesInNode(layout.leftNode, frame: leftFrame, result: &frames)
        }
        
        if metrics.centerFrame.width > 0, metrics.centerFrame.height > 0, !isNodeEmptyCheck(layout.centerNode) {
            collectPanelFramesInNode(layout.centerNode, frame: metrics.centerFrame, result: &frames)
        }
        
        if metrics.rightDockWidth > 0, metrics.centerFrame.height > 0, !isNodeEmptyCheck(layout.rightNode) {
            let rightFrame = CGRect(
                x: containerSize.width - metrics.rightDockWidth,
                y: metrics.centerFrame.minY,
                width: metrics.rightDockWidth,
                height: metrics.centerFrame.height
            )
            collectPanelFramesInNode(layout.rightNode, frame: rightFrame, result: &frames)
        }
        
        if metrics.bottomHeight > 0, !isNodeEmptyCheck(layout.bottomNode) {
            let bottomFrame = CGRect(
                x: 0,
                y: containerSize.height - metrics.bottomHeight,
                width: containerSize.width,
                height: metrics.bottomHeight
            )
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
        let metrics = layoutMetrics(in: containerSize)
        
        if metrics.topHeight > 0, !isNodeEmptyCheck(layout.topNode) {
            let topFrame = CGRect(x: 0, y: 0, width: containerSize.width, height: metrics.topHeight)
            if let frame = findPanelFrameInNode(layout.topNode, panelID: panelID, containerFrame: topFrame) {
                return frame
            }
        }
        
        if metrics.leftDockWidth > 0, metrics.centerFrame.height > 0, !isNodeEmptyCheck(layout.leftNode) {
            let leftFrame = CGRect(
                x: 0,
                y: metrics.centerFrame.minY,
                width: metrics.leftDockWidth,
                height: metrics.centerFrame.height
            )
            if let frame = findPanelFrameInNode(layout.leftNode, panelID: panelID, containerFrame: leftFrame) {
                return frame
            }
        }
        
        if metrics.centerFrame.width > 0, metrics.centerFrame.height > 0, !isNodeEmptyCheck(layout.centerNode) {
            if let frame = findPanelFrameInNode(layout.centerNode, panelID: panelID, containerFrame: metrics.centerFrame) {
                return frame
            }
        }
        
        if metrics.rightDockWidth > 0, metrics.centerFrame.height > 0, !isNodeEmptyCheck(layout.rightNode) {
            let rightFrame = CGRect(
                x: containerSize.width - metrics.rightDockWidth,
                y: metrics.centerFrame.minY,
                width: metrics.rightDockWidth,
                height: metrics.centerFrame.height
            )
            if let frame = findPanelFrameInNode(layout.rightNode, panelID: panelID, containerFrame: rightFrame) {
                return frame
            }
        }
        
        if metrics.bottomHeight > 0, !isNodeEmptyCheck(layout.bottomNode) {
            let bottomFrame = CGRect(
                x: 0,
                y: containerSize.height - metrics.bottomHeight,
                width: containerSize.width,
                height: metrics.bottomHeight
            )
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
    let frame: CGRect
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        ZStack {
            Image(systemName: iconName)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(isActive ? .white : theme.colors.secondaryText)
        }
        .frame(width: 56, height: 56)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isActive ? theme.colors.accent : theme.colors.secondaryBackground.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(theme.colors.shadowColor.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: theme.colors.shadowColor.opacity(isActive ? 0.6 : 0.35), radius: 8, y: 4)
        )
        .position(x: frame.midX, y: frame.midY)
        .scaleEffect(isActive ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isActive)
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
