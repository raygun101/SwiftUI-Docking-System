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
        let layout = state.layout
        var currentY: CGFloat = 0
        
        if !isNodeEmpty(layout.topNode) {
            let topHeight = layout.isTopCollapsed ? theme.spacing.collapsedWidth : layout.topHeight
            let topFrame = CGRect(x: 0, y: 0, width: size.width, height: topHeight)
            if topFrame.contains(location) {
                return findSplitDropZoneInNode(layout.topNode, at: location, in: size, containerFrame: topFrame)
            }
            currentY += topHeight
        }
        
        var leftWidth: CGFloat = 0
        var rightWidth: CGFloat = 0
        
        if !isNodeEmpty(layout.leftNode) {
            leftWidth = layout.isLeftCollapsed ? theme.spacing.collapsedWidth : layout.leftWidth
            let leftFrame = CGRect(x: 0, y: currentY, width: leftWidth, height: size.height - currentY)
            if leftFrame.contains(location) {
                return findSplitDropZoneInNode(layout.leftNode, at: location, in: size, containerFrame: leftFrame)
            }
        }
        
        if !isNodeEmpty(layout.rightNode) {
            rightWidth = layout.isRightCollapsed ? theme.spacing.collapsedWidth : layout.rightWidth
            let rightFrame = CGRect(x: size.width - rightWidth, y: currentY, width: rightWidth, height: size.height - currentY)
            if rightFrame.contains(location) {
                return findSplitDropZoneInNode(layout.rightNode, at: location, in: size, containerFrame: rightFrame)
            }
        }
        
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
        
        if !isNodeEmpty(layout.bottomNode) {
            let bottomHeight = layout.isBottomCollapsed ? theme.spacing.collapsedWidth : layout.bottomHeight
            let bottomFrame = CGRect(x: 0, y: size.height - bottomHeight, width: size.width, height: bottomHeight)
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
}
