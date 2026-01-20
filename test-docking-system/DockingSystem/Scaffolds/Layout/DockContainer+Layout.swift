import SwiftUI

extension DockContainer {
    @ViewBuilder
    func mainLayout(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            if !isNodeEmpty(state.layout.topNode) {
                topSection(in: size)
            }
            
            HStack(spacing: 0) {
                if !isNodeEmpty(state.layout.leftNode) {
                    leftSection(in: size)
                }
                
                centerSection(in: size)
                
                if !isNodeEmpty(state.layout.rightNode) {
                    rightSection(in: size)
                }
            }
            
            if !isNodeEmpty(state.layout.bottomNode) {
                bottomSection(in: size)
            }
        }
    }
    
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
    
    @ViewBuilder
    func floatingPanels(in size: CGSize) -> some View {
        ForEach(state.layout.floatingPanels) { group in
            FloatingPanelView(group: group, containerSize: size)
        }
    }
    
    var minimizedPanelsBar: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 8) {
                ForEach(state.layout.minimizedPanels, id: \ .id) { panel in
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
    
    func isNodeEmpty(_ node: DockLayoutNode) -> Bool {
        if case .empty = node {
            return true
        }
        return false
    }
}
