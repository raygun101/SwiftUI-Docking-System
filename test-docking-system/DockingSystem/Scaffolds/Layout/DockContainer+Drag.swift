import SwiftUI

extension DockContainer {
    func updateDropZoneFromLocation(_ location: CGPoint, in size: CGSize) {
        let edgeThreshold: CGFloat = 80
        
        if let splitDropZone = findSplitDropZone(at: location, in: size) {
            state.updateDropZone(splitDropZone)
            return
        }
        
        let innerEdgeSafeZone: CGFloat = edgeThreshold - 20
        if location.x < edgeThreshold {
            let shouldPreferInner = location.x > innerEdgeSafeZone
            if shouldPreferInner {
                state.updateDropZone(.position(.center))
            } else {
                state.updateDropZone(.position(.left))
            }
            return
        }
        
        if location.x > size.width - edgeThreshold {
            let shouldPreferInner = location.x < size.width - innerEdgeSafeZone
            if shouldPreferInner {
                state.updateDropZone(.position(.center))
            } else {
                state.updateDropZone(.position(.right))
            }
            return
        }
        
        if location.y < edgeThreshold {
            let shouldPreferInner = location.y > innerEdgeSafeZone
            if shouldPreferInner {
                state.updateDropZone(.position(.center))
            } else {
                state.updateDropZone(.position(.top))
            }
            return
        }
        
        if location.y > size.height - edgeThreshold {
            let shouldPreferInner = location.y < size.height - innerEdgeSafeZone
            if shouldPreferInner {
                state.updateDropZone(.position(.center))
            } else {
                state.updateDropZone(.position(.bottom))
            }
            return
        }
        
        state.updateDropZone(.position(.center))
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
        
        if let innerDropZone = innerIndicatorDropZone(
            for: panel,
            localLocation: localLocation,
            panelSize: panelSize
        ) {
            return innerDropZone
        }
        
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

    private func innerIndicatorDropZone(
        for panel: DockPanel,
        localLocation: CGPoint,
        panelSize: CGSize
    ) -> DockDropZone? {
        let indicatorMargin: CGFloat = 16
        let indicatorSize = CGSize(
            width: max(panelSize.width - indicatorMargin * 2, 0),
            height: max(panelSize.height - indicatorMargin * 2, 0)
        )
        guard indicatorSize.width > 0, indicatorSize.height > 0 else { return nil }
        let indicatorPoint = CGPoint(
            x: localLocation.x - indicatorMargin,
            y: localLocation.y - indicatorMargin
        )
        guard indicatorPoint.x >= 0,
              indicatorPoint.y >= 0,
              indicatorPoint.x <= indicatorSize.width,
              indicatorPoint.y <= indicatorSize.height else {
            return nil
        }
        
        let edgePadding: CGFloat = 18
        let indicatorDiameter: CGFloat = 46
        let hitExpansion: CGFloat = 10
        let centerX = indicatorSize.width / 2
        let centerY = indicatorSize.height / 2
        
        func rectAround(center: CGPoint) -> CGRect {
            CGRect(
                x: center.x - indicatorDiameter / 2 - hitExpansion,
                y: center.y - indicatorDiameter / 2 - hitExpansion,
                width: indicatorDiameter + hitExpansion * 2,
                height: indicatorDiameter + hitExpansion * 2
            )
        }
        
        let leftCenter = CGPoint(
            x: max(edgePadding + indicatorDiameter / 2, indicatorDiameter / 2),
            y: centerY
        )
        let rightCenter = CGPoint(
            x: min(indicatorSize.width - edgePadding - indicatorDiameter / 2, indicatorSize.width - indicatorDiameter / 2),
            y: centerY
        )
        let topCenter = CGPoint(
            x: centerX,
            y: max(edgePadding + indicatorDiameter / 2, indicatorDiameter / 2)
        )
        let bottomCenter = CGPoint(
            x: centerX,
            y: min(indicatorSize.height - edgePadding - indicatorDiameter / 2, indicatorSize.height - indicatorDiameter / 2)
        )
        let middleCenter = CGPoint(x: centerX, y: centerY)
        
        if rectAround(center: leftCenter).contains(indicatorPoint) {
            return .split(panelID: panel.id, position: .left)
        }
        if rectAround(center: rightCenter).contains(indicatorPoint) {
            return .split(panelID: panel.id, position: .right)
        }
        if rectAround(center: topCenter).contains(indicatorPoint) {
            return .split(panelID: panel.id, position: .top)
        }
        if rectAround(center: bottomCenter).contains(indicatorPoint) {
            return .split(panelID: panel.id, position: .bottom)
        }
        if rectAround(center: middleCenter).contains(indicatorPoint) {
            return .tab(panelID: panel.id, index: 0)
        }
        
        return nil
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
