import SwiftUI

// MARK: - Main Dock Container

/// The main container view for the docking system
public struct DockContainer: View {
    @ObservedObject var state: DockState
    @Environment(\.dockTheme) var theme
    
    public init(state: DockState) {
        self.state = state
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main layout
                mainLayout(in: geometry.size)
                
                // Drop zone overlays when dragging
                if state.draggedPanel != nil {
                    dropZoneOverlay(in: geometry.size)
                }
                
                // Floating panels
                floatingPanels(in: geometry.size)
                
                // Minimized panels bar
                if !state.layout.minimizedPanels.isEmpty {
                    minimizedPanelsBar
                }
            }
            .background(theme.colors.background)
        }
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
    
    // MARK: - Drop Zone Overlay
    
    @ViewBuilder
    private func dropZoneOverlay(in size: CGSize) -> some View {
        ZStack {
            // Edge drop zones
            edgeDropZones(in: size)
            
            // Center drop zone indicator
            if case .position(let position) = state.dropZone {
                dropZoneIndicator(for: position, in: size)
            }
        }
        .allowsHitTesting(true)
    }
    
    @ViewBuilder
    private func edgeDropZones(in size: CGSize) -> some View {
        // Left drop zone
        DropZoneArea(position: .left, containerSize: size)
            .frame(width: 80)
            .frame(maxHeight: .infinity)
            .position(x: 40, y: size.height / 2)
        
        // Right drop zone
        DropZoneArea(position: .right, containerSize: size)
            .frame(width: 80)
            .frame(maxHeight: .infinity)
            .position(x: size.width - 40, y: size.height / 2)
        
        // Top drop zone
        DropZoneArea(position: .top, containerSize: size)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .position(x: size.width / 2, y: 30)
        
        // Bottom drop zone
        DropZoneArea(position: .bottom, containerSize: size)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .position(x: size.width / 2, y: size.height - 30)
        
        // Center drop zone
        DropZoneArea(position: .center, containerSize: size)
            .frame(width: 120, height: 80)
            .position(x: size.width / 2, y: size.height / 2)
    }
    
    @ViewBuilder
    private func dropZoneIndicator(for position: DockPosition, in size: CGSize) -> some View {
        let frame = dropZoneFrame(for: position, in: size)
        
        RoundedRectangle(cornerRadius: theme.cornerRadii.dropZone)
            .fill(theme.colors.dropZoneBackground)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadii.dropZone)
                    .strokeBorder(theme.colors.dropZoneHighlight, lineWidth: theme.borders.dropZoneBorderWidth)
            )
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
            .transition(.opacity)
            .animation(theme.animations.quickAnimation, value: state.dropZone)
    }
    
    private func dropZoneFrame(for position: DockPosition, in size: CGSize) -> CGRect {
        switch position {
        case .left:
            return CGRect(x: 0, y: 0, width: 250, height: size.height)
        case .right:
            return CGRect(x: size.width - 250, y: 0, width: 250, height: size.height)
        case .top:
            return CGRect(x: 0, y: 0, width: size.width, height: 200)
        case .bottom:
            return CGRect(x: 0, y: size.height - 200, width: size.width, height: 200)
        case .center:
            return CGRect(x: size.width * 0.2, y: size.height * 0.2, width: size.width * 0.6, height: size.height * 0.6)
        case .floating:
            return .zero
        }
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

// MARK: - Drop Zone Area

struct DropZoneArea: View {
    let position: DockPosition
    let containerSize: CGSize
    @EnvironmentObject var state: DockState
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .onDrop(of: [.text], isTargeted: nil) { providers in
                state.updateDropZone(.position(position))
                return true
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if state.draggedPanel != nil {
                            state.updateDropZone(.position(position))
                        }
                    }
            )
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
