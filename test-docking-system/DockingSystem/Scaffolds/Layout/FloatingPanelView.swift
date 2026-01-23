import SwiftUI

// MARK: - Floating Panel View (Scaffold)

/// A floating, draggable panel window that uses the style system for theming
struct FloatingPanelView: View {
    @ObservedObject var group: DockPanelGroup
    let containerSize: CGSize
    
    @EnvironmentObject var state: DockState
    @Environment(\.dockTheme) var theme
    @Environment(\.dockFloatingPanelStyle) var floatingPanelStyle
    
    @State private var position: CGPoint = CGPoint(x: 100, y: 100)
    @State private var size: CGSize = CGSize(width: 300, height: 250)
    @State private var isDragging = false
    @State private var dragStartPosition: CGPoint = .zero
    @State private var isResizing = false
    @State private var resizeStartSize: CGSize = .zero
    
    var body: some View {
        let configuration = makeConfiguration()
        
        ZStack {
            // Styled floating panel content
            AnyView(floatingPanelStyle.makeBody(configuration: configuration))
            
            // Resize handle overlay (theme-independent interaction layer)
            resizeHandleOverlay
        }
        .position(x: position.x + size.width / 2, y: position.y + size.height / 2)
        .onAppear {
            if let frame = group.activePanel?.floatingFrame {
                position = CGPoint(x: frame.origin.x, y: frame.origin.y)
                size = frame.size
            }
        }
        .gesture(dragGesture)
    }
    
    // MARK: - Configuration Builder
    
    private func makeConfiguration() -> DockFloatingPanelConfiguration {
        let activePanel = group.activePanel
        let tabs = group.panels.map { panel in
            DockTabItem(
                id: panel.id,
                title: panel.title,
                icon: panel.icon,
                isActive: panel.id == activePanel?.id
            )
        }
        
        return DockFloatingPanelConfiguration(
            title: activePanel?.title ?? "Panel",
            icon: activePanel?.icon,
            isActive: activePanel?.isActive ?? false,
            hasMultipleTabs: group.panels.count > 1,
            tabs: tabs,
            activeTabIndex: group.activeTabIndex,
            size: size,
            content: AnyView(
                Group {
                    if let activePanel = activePanel {
                        activePanel.content()
                    }
                }
            ),
            onClose: closeFloatingPanel,
            onMinimize: minimizeFloatingPanel,
            onMaximize: maximizeFloatingPanel,
            onDock: dockPanel,
            onTabSelect: { index in group.activeTabIndex = index },
            onTabClose: { index in
                if index < group.panels.count {
                    state.closePanel(group.panels[index])
                }
            }
        )
    }
    
    // MARK: - Drag Gesture (Smooth 1:1 tracking)
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                if !isDragging {
                    // Store starting position on drag start
                    isDragging = true
                    dragStartPosition = position
                }
                
                // Direct 1:1 position update - no offset, no animation lag
                position = CGPoint(
                    x: dragStartPosition.x + value.translation.width,
                    y: dragStartPosition.y + value.translation.height
                )
            }
            .onEnded { _ in
                isDragging = false
                
                // Constrain to container bounds
                position.x = max(0, min(containerSize.width - size.width, position.x))
                position.y = max(0, min(containerSize.height - size.height, position.y))
            }
    }
    
    // MARK: - Resize Handle Overlay
    
    private var resizeHandleOverlay: some View {
        GeometryReader { _ in
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    resizeHandle
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
    
    private var resizeHandle: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 10))
            .foregroundColor(theme.colors.tertiaryText)
            .frame(width: 16, height: 16)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if !isResizing {
                            isResizing = true
                            resizeStartSize = size
                        }
                        
                        let newWidth = max(200, resizeStartSize.width + value.translation.width)
                        let newHeight = max(150, resizeStartSize.height + value.translation.height)
                        size = CGSize(width: newWidth, height: newHeight)
                    }
                    .onEnded { _ in
                        isResizing = false
                    }
            )
            .padding(4)
    }
    
    // MARK: - Actions
    
    private func closeFloatingPanel() {
        withAnimation(theme.animations.springAnimation) {
            state.layout.floatingPanels.removeAll { $0.id == group.id }
        }
    }
    
    private func minimizeFloatingPanel() {
        if let panel = group.activePanel {
            withAnimation(theme.animations.springAnimation) {
                panel.minimize()
                state.layout.minimizedPanels.append(panel)
                state.layout.floatingPanels.removeAll { $0.id == group.id }
            }
        }
    }
    
    private func maximizeFloatingPanel() {
        withAnimation(theme.animations.springAnimation) {
            position = .zero
            size = containerSize
        }
    }
    
    private func dockPanel() {
        if let panel = group.activePanel {
            state.dockPanel(panel, to: .right)
        }
    }
}
