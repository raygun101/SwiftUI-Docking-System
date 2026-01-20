import SwiftUI

// MARK: - Dock Split View

/// Renders a split layout with two child nodes
struct DockSplitView: View {
    @ObservedObject var node: DockSplitNode
    let position: DockPosition
    let size: CGSize
    
    @EnvironmentObject var state: DockState
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        GeometryReader { geometry in
            let totalSize = geometry.size
            
            if node.orientation == .horizontal {
                horizontalSplit(in: totalSize)
            } else {
                verticalSplit(in: totalSize)
            }
        }
    }
    
    @ViewBuilder
    private func horizontalSplit(in totalSize: CGSize) -> some View {
        let firstWidth = totalSize.width * node.splitRatio
        let secondWidth = totalSize.width * (1 - node.splitRatio)
        
        HStack(spacing: 0) {
            // First node
            nodeView(node.first, size: CGSize(width: firstWidth, height: totalSize.height))
                .frame(width: firstWidth)
            
            // Resize handle
            SplitResizeHandle(
                orientation: .horizontal,
                isActive: node.isResizing,
                onDrag: { delta in
                    let newRatio = node.splitRatio + (delta / totalSize.width)
                    node.updateRatio(newRatio)
                },
                onDragStart: { node.isResizing = true },
                onDragEnd: { node.isResizing = false }
            )
            
            // Second node
            nodeView(node.second, size: CGSize(width: secondWidth, height: totalSize.height))
                .frame(width: secondWidth)
        }
    }
    
    @ViewBuilder
    private func verticalSplit(in totalSize: CGSize) -> some View {
        let firstHeight = totalSize.height * node.splitRatio
        let secondHeight = totalSize.height * (1 - node.splitRatio)
        
        VStack(spacing: 0) {
            // First node
            nodeView(node.first, size: CGSize(width: totalSize.width, height: firstHeight))
                .frame(height: firstHeight)
            
            // Resize handle
            SplitResizeHandle(
                orientation: .vertical,
                isActive: node.isResizing,
                onDrag: { delta in
                    let newRatio = node.splitRatio + (delta / totalSize.height)
                    node.updateRatio(newRatio)
                },
                onDragStart: { node.isResizing = true },
                onDragEnd: { node.isResizing = false }
            )
            
            // Second node
            nodeView(node.second, size: CGSize(width: totalSize.width, height: secondHeight))
                .frame(height: secondHeight)
        }
    }
    
    @ViewBuilder
    private func nodeView(_ childNode: DockLayoutNode, size: CGSize) -> some View {
        DockRegionView(
            node: childNode,
            position: position,
            isCollapsed: false,
            size: size
        )
    }
}

// MARK: - Split Resize Handle

struct SplitResizeHandle: View {
    let orientation: DockSplitOrientation
    let isActive: Bool
    let onDrag: (CGFloat) -> Void
    let onDragStart: () -> Void
    let onDragEnd: () -> Void
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    @GestureState private var isDragging = false
    
    var body: some View {
        Rectangle()
            .fill(handleColor)
            .frame(
                width: orientation == .horizontal ? theme.spacing.resizeHandleSize : nil,
                height: orientation == .vertical ? theme.spacing.resizeHandleSize : nil
            )
            .contentShape(Rectangle().inset(by: -4))
            .gesture(dragGesture)
            .onHover { hovering in
                isHovered = hovering
            }
            #if os(iOS)
            .hoverEffect(.highlight)
            #endif
    }
    
    private var handleColor: Color {
        if isActive || isDragging {
            return theme.colors.accent
        } else if isHovered {
            return theme.colors.accent.opacity(0.5)
        } else {
            return theme.colors.resizeHandle
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .updating($isDragging) { _, state, _ in
                if !state {
                    state = true
                    onDragStart()
                }
            }
            .onChanged { value in
                let delta = orientation == .horizontal ? value.translation.width : value.translation.height
                onDrag(delta / 100) // Normalize
            }
            .onEnded { _ in
                onDragEnd()
            }
    }
}
