import SwiftUI

extension DockContainer {
    func updateDropZoneFromLocation(_ location: CGPoint, in size: CGSize) {
        let edgeThreshold: CGFloat = 80
        
        if location.x < edgeThreshold {
            state.updateDropZone(.position(.left))
        } else if location.x > size.width - edgeThreshold {
            state.updateDropZone(.position(.right))
        } else if location.y < edgeThreshold {
            state.updateDropZone(.position(.top))
        } else if location.y > size.height - edgeThreshold {
            state.updateDropZone(.position(.bottom))
        } else if let splitDropZone = findSplitDropZone(at: location, in: size) {
            state.updateDropZone(splitDropZone)
        } else {
            state.updateDropZone(.position(.center))
        }
    }
    
    private func findSplitDropZone(at location: CGPoint, in size: CGSize) -> DockDropZone? {
        let metrics = dragLayoutMetrics(in: size)
        let layout = state.layout
        
        if metrics.topHeight > 0, !isNodeEmptyCheck(layout.topNode) {
            let topFrame = CGRect(x: 0, y: 0, width: size.width, height: metrics.topHeight)
            if topFrame.contains(location) {
                return findSplitDropZoneInNode(layout.topNode, at: location, in: size, containerFrame: topFrame)
            }
        }
        
        if metrics.leftDockWidth > 0, metrics.centerFrame.height > 0, !isNodeEmptyCheck(layout.leftNode) {
            let leftFrame = CGRect(
                x: 0,
                y: metrics.centerFrame.minY,
                width: metrics.leftDockWidth,
                height: metrics.centerFrame.height
            )
            if leftFrame.contains(location) {
                return findSplitDropZoneInNode(layout.leftNode, at: location, in: size, containerFrame: leftFrame)
            }
        }
        
        if metrics.centerFrame.width > 0, metrics.centerFrame.height > 0, !isNodeEmptyCheck(layout.centerNode) {
            if metrics.centerFrame.contains(location) {
                return findSplitDropZoneInNode(layout.centerNode, at: location, in: size, containerFrame: metrics.centerFrame)
            }
        }
        
        if metrics.rightDockWidth > 0, metrics.centerFrame.height > 0, !isNodeEmptyCheck(layout.rightNode) {
            let rightFrame = CGRect(
                x: size.width - metrics.rightDockWidth,
                y: metrics.centerFrame.minY,
                width: metrics.rightDockWidth,
                height: metrics.centerFrame.height
            )
            if rightFrame.contains(location) {
                return findSplitDropZoneInNode(layout.rightNode, at: location, in: size, containerFrame: rightFrame)
            }
        }
        
        if metrics.bottomHeight > 0, !isNodeEmptyCheck(layout.bottomNode) {
            let bottomFrame = CGRect(
                x: 0,
                y: size.height - metrics.bottomHeight,
                width: size.width,
                height: metrics.bottomHeight
            )
            if bottomFrame.contains(location) {
                return findSplitDropZoneInNode(layout.bottomNode, at: location, in: size, containerFrame: bottomFrame)
            }
        }
        
        return nil
    }
    
    private func findSplitDropZoneInNode(
        _ node: DockLayoutNode,
        at location: CGPoint,
        in containerSize: CGSize,
        containerFrame: CGRect
    ) -> DockDropZone? {
        switch node {
        case .panel(let group):
            if let panel = group.activePanel, containerFrame.contains(location) {
                return findSplitPositionInPanel(panel, at: location, panelFrame: containerFrame)
            }
            
        case .split(let splitNode):
            let (firstFrame, secondFrame) = calculateSplitFrames(
                orientation: splitNode.orientation,
                ratio: splitNode.splitRatio,
                containerFrame: containerFrame
            )
            
            if firstFrame.contains(location) {
                return findSplitDropZoneInNode(splitNode.first, at: location, in: containerSize, containerFrame: firstFrame)
            }
            if secondFrame.contains(location) {
                return findSplitDropZoneInNode(splitNode.second, at: location, in: containerSize, containerFrame: secondFrame)
            }
            
        case .empty:
            break
        }
        
        return nil
    }
    
    private func calculateSplitFrames(
        orientation: DockSplitOrientation,
        ratio: CGFloat,
        containerFrame: CGRect
    ) -> (CGRect, CGRect) {
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
    
    private func findSplitPositionInPanel(
        _ panel: DockPanel,
        at location: CGPoint,
        panelFrame: CGRect
    ) -> DockDropZone? {
        let localLocation = CGPoint(
            x: location.x - panelFrame.minX,
            y: location.y - panelFrame.minY
        )
        
        let panelSize = panelFrame.size
        let threshold: CGFloat = 40
        
        if localLocation.x < threshold {
            return .split(panelID: panel.id, position: .left)
        } else if localLocation.x > panelSize.width - threshold {
            return .split(panelID: panel.id, position: .right)
        } else if localLocation.y < threshold {
            return .split(panelID: panel.id, position: .top)
        } else if localLocation.y > panelSize.height - threshold {
            return .split(panelID: panel.id, position: .bottom)
        }
        
        return .tab(panelID: panel.id, index: 0)
    }
    
    private func dragLayoutMetrics(in size: CGSize) -> DragLayoutMetrics {
        let collapsed = theme.spacing.collapsedWidth
        let layout = state.layout
        let leftWidth = isNodeEmptyCheck(layout.leftNode) ? 0 : (layout.isLeftCollapsed ? collapsed : layout.leftWidth)
        let rightWidth = isNodeEmptyCheck(layout.rightNode) ? 0 : (layout.isRightCollapsed ? collapsed : layout.rightWidth)
        let topHeight = isNodeEmptyCheck(layout.topNode) ? 0 : (layout.isTopCollapsed ? collapsed : layout.topHeight)
        let bottomHeight = isNodeEmptyCheck(layout.bottomNode) ? 0 : (layout.isBottomCollapsed ? collapsed : layout.bottomHeight)
        
        let constrainedLeft = min(max(0, leftWidth), size.width * 0.5)
        let constrainedRight = min(max(0, rightWidth), size.width * 0.5)
        let constrainedTop = min(max(0, topHeight), size.height * 0.5)
        let constrainedBottom = min(max(0, bottomHeight), size.height * 0.5)
        let centerFrame = CGRect(
            x: constrainedLeft,
            y: constrainedTop,
            width: max(0, size.width - constrainedLeft - constrainedRight),
            height: max(0, size.height - constrainedTop - constrainedBottom)
        )
        
        return DragLayoutMetrics(
            leftDockWidth: constrainedLeft,
            rightDockWidth: constrainedRight,
            topHeight: constrainedTop,
            bottomHeight: constrainedBottom,
            centerFrame: centerFrame
        )
    }
}

private struct DragLayoutMetrics {
    let leftDockWidth: CGFloat
    let rightDockWidth: CGFloat
    let topHeight: CGFloat
    let bottomHeight: CGFloat
    let centerFrame: CGRect
}
