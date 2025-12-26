import SwiftUI

// MARK: - Edge Resize Handle

/// Resize handle for dock region edges
struct DockResizeHandle: View {
    let position: DockPosition
    let onResize: (CGFloat) -> Void
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    @GestureState private var isDragging = false
    @State private var lastDragValue: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(handleColor)
                .frame(
                    width: isHorizontal ? theme.spacing.resizeHandleSize : nil,
                    height: isHorizontal ? nil : theme.spacing.resizeHandleSize
                )
                .contentShape(Rectangle().inset(by: -8))
                .gesture(dragGesture)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovered = hovering
                    }
                }
                #if os(iOS)
                .hoverEffect(.lift)
                #endif
        }
        .frame(
            width: isHorizontal ? theme.spacing.resizeHandleSize : nil,
            height: isHorizontal ? nil : theme.spacing.resizeHandleSize
        )
    }
    
    private var isHorizontal: Bool {
        position == .left || position == .right
    }
    
    private var handleColor: Color {
        if isDragging {
            return theme.colors.accent
        } else if isHovered {
            return theme.colors.accent.opacity(0.6)
        } else {
            return theme.colors.resizeHandle
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                let currentValue = isHorizontal ? value.translation.width : value.translation.height
                let delta = currentValue - lastDragValue
                onResize(delta)
                lastDragValue = currentValue
            }
            .onEnded { _ in
                lastDragValue = 0
            }
    }
}

// MARK: - Corner Resize Handle

/// Resize handle for floating panel corners
struct CornerResizeHandle: View {
    let corner: Corner
    let onResize: (CGSize) -> Void
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    @GestureState private var isDragging = false
    
    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
        
        var systemImage: String {
            switch self {
            case .topLeft: return "arrow.up.left"
            case .topRight: return "arrow.up.right"
            case .bottomLeft: return "arrow.down.left"
            case .bottomRight: return "arrow.down.right"
            }
        }
    }
    
    var body: some View {
        Image(systemName: corner == .bottomRight ? "arrow.down.right.and.arrow.up.left" : "")
            .font(.system(size: 8))
            .foregroundColor(isDragging ? theme.colors.accent : theme.colors.tertiaryText)
            .frame(width: 16, height: 16)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        var deltaWidth = value.translation.width
                        var deltaHeight = value.translation.height
                        
                        // Adjust direction based on corner
                        switch corner {
                        case .topLeft:
                            deltaWidth = -deltaWidth
                            deltaHeight = -deltaHeight
                        case .topRight:
                            deltaHeight = -deltaHeight
                        case .bottomLeft:
                            deltaWidth = -deltaWidth
                        case .bottomRight:
                            break
                        }
                        
                        onResize(CGSize(width: deltaWidth, height: deltaHeight))
                    }
            )
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Edge Resize Handles Container

/// Container for all edge resize handles on a floating panel
struct FloatingResizeHandles: View {
    let onResize: (DockPosition, CGFloat) -> Void
    let onCornerResize: (CGSize) -> Void
    
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Edge handles
                // Top
                EdgeHandle(edge: .top)
                    .frame(height: 6)
                    .frame(maxWidth: .infinity)
                    .position(x: geometry.size.width / 2, y: 3)
                    .gesture(edgeDragGesture(for: .top))
                
                // Bottom
                EdgeHandle(edge: .bottom)
                    .frame(height: 6)
                    .frame(maxWidth: .infinity)
                    .position(x: geometry.size.width / 2, y: geometry.size.height - 3)
                    .gesture(edgeDragGesture(for: .bottom))
                
                // Left
                EdgeHandle(edge: .left)
                    .frame(width: 6)
                    .frame(maxHeight: .infinity)
                    .position(x: 3, y: geometry.size.height / 2)
                    .gesture(edgeDragGesture(for: .left))
                
                // Right
                EdgeHandle(edge: .right)
                    .frame(width: 6)
                    .frame(maxHeight: .infinity)
                    .position(x: geometry.size.width - 3, y: geometry.size.height / 2)
                    .gesture(edgeDragGesture(for: .right))
                
                // Corner resize (bottom-right)
                CornerResizeHandle(corner: .bottomRight, onResize: onCornerResize)
                    .position(x: geometry.size.width - 8, y: geometry.size.height - 8)
            }
        }
    }
    
    private func edgeDragGesture(for position: DockPosition) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let delta: CGFloat
                switch position {
                case .top, .bottom:
                    delta = value.translation.height
                case .left, .right:
                    delta = value.translation.width
                default:
                    delta = 0
                }
                onResize(position, delta)
            }
    }
}

struct EdgeHandle: View {
    let edge: DockPosition
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
