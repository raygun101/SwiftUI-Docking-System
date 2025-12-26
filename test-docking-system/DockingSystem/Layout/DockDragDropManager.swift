import SwiftUI

// MARK: - Drag Drop Manager

/// Manages drag and drop operations for panels
public class DockDragDropManager: ObservableObject {
    @Published public var isDragging: Bool = false
    @Published public var draggedPanel: DockPanel?
    @Published public var dragLocation: CGPoint = .zero
    @Published public var currentDropZone: DockDropZone = .none
    @Published public var dropZoneFrames: [DockDropZone: CGRect] = [:]
    
    public weak var state: DockState?
    
    public init() {}
    
    // MARK: - Drag Operations
    
    public func startDrag(_ panel: DockPanel, at location: CGPoint) {
        guard panel.visibility.contains(.allowDrag) else { return }
        
        withAnimation(.easeOut(duration: 0.15)) {
            isDragging = true
            draggedPanel = panel
            dragLocation = location
        }
    }
    
    public func updateDrag(to location: CGPoint) {
        dragLocation = location
        currentDropZone = calculateDropZone(at: location)
    }
    
    public func endDrag() {
        guard let panel = draggedPanel, currentDropZone != .none else {
            cancelDrag()
            return
        }
        
        state?.movePanel(panel, to: currentDropZone)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isDragging = false
            draggedPanel = nil
            currentDropZone = .none
        }
    }
    
    public func cancelDrag() {
        withAnimation(.easeOut(duration: 0.15)) {
            isDragging = false
            draggedPanel = nil
            currentDropZone = .none
        }
    }
    
    // MARK: - Drop Zone Calculation
    
    public func registerDropZone(_ zone: DockDropZone, frame: CGRect) {
        dropZoneFrames[zone] = frame
    }
    
    public func unregisterDropZone(_ zone: DockDropZone) {
        dropZoneFrames.removeValue(forKey: zone)
    }
    
    private func calculateDropZone(at location: CGPoint) -> DockDropZone {
        // Check each registered drop zone
        for (zone, frame) in dropZoneFrames {
            if frame.contains(location) {
                return zone
            }
        }
        return .none
    }
    
    // MARK: - Drop Zone Highlights
    
    public func isHighlighted(_ zone: DockDropZone) -> Bool {
        isDragging && currentDropZone == zone
    }
    
    public func dropZoneOpacity(for zone: DockDropZone) -> Double {
        if !isDragging { return 0 }
        return currentDropZone == zone ? 1.0 : 0.3
    }
}

// MARK: - Draggable Panel Modifier

struct DraggablePanelModifier: ViewModifier {
    let panel: DockPanel
    @EnvironmentObject var state: DockState
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .opacity(isDragging ? 0.6 : 1.0)
            .scaleEffect(isDragging ? 0.98 : 1.0)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        if !isDragging && panel.visibility.contains(.allowDrag) {
                            isDragging = true
                            state.startDrag(panel)
                        }
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        isDragging = false
                        dragOffset = .zero
                        state.endDrag()
                    }
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isDragging)
    }
}

extension View {
    func draggablePanel(_ panel: DockPanel) -> some View {
        modifier(DraggablePanelModifier(panel: panel))
    }
}

// MARK: - Drop Zone View

struct DropZoneView: View {
    let position: DockPosition
    let frame: CGRect
    
    @EnvironmentObject var state: DockState
    @Environment(\.dockTheme) var theme
    
    var isHighlighted: Bool {
        if case .position(let pos) = state.dropZone {
            return pos == position
        }
        return false
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadii.dropZone)
            .fill(isHighlighted ? theme.colors.dropZoneBackground : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadii.dropZone)
                    .strokeBorder(
                        isHighlighted ? theme.colors.dropZoneHighlight : theme.colors.border.opacity(0.3),
                        style: StrokeStyle(lineWidth: isHighlighted ? 3 : 1, dash: isHighlighted ? [] : [8, 4])
                    )
            )
            .contentShape(Rectangle())
            .animation(theme.animations.quickAnimation, value: isHighlighted)
    }
}

// MARK: - Drop Zone Indicator Overlay

struct DropZoneIndicatorOverlay: View {
    let containerSize: CGSize
    
    @EnvironmentObject var state: DockState
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        ZStack {
            if state.draggedPanel != nil {
                // Show drop zone indicators
                dropZoneIndicators
            }
        }
    }
    
    @ViewBuilder
    private var dropZoneIndicators: some View {
        // Center compass indicator
        VStack(spacing: 4) {
            // Top
            DropIndicatorButton(position: .top, icon: "arrow.up")
            
            HStack(spacing: 4) {
                // Left
                DropIndicatorButton(position: .left, icon: "arrow.left")
                
                // Center
                DropIndicatorButton(position: .center, icon: "rectangle.center.inset.filled")
                
                // Right
                DropIndicatorButton(position: .right, icon: "arrow.right")
            }
            
            // Bottom
            DropIndicatorButton(position: .bottom, icon: "arrow.down")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.colors.secondaryBackground.opacity(0.95))
                .shadow(color: theme.colors.shadowColor, radius: 20, y: 8)
        )
        .position(x: containerSize.width / 2, y: containerSize.height / 2)
    }
}

struct DropIndicatorButton: View {
    let position: DockPosition
    let icon: String
    
    @EnvironmentObject var state: DockState
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    
    var isActive: Bool {
        if case .position(let pos) = state.dropZone {
            return pos == position
        }
        return false
    }
    
    var body: some View {
        Button(action: {
            state.updateDropZone(.position(position))
        }) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isActive ? .white : theme.colors.secondaryText)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isActive ? theme.colors.accent : (isHovered ? theme.colors.hoverBackground : theme.colors.tertiaryBackground))
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering && state.draggedPanel != nil {
                state.updateDropZone(.position(position))
            }
        }
        .scaleEffect(isActive ? 1.1 : 1.0)
        .animation(theme.animations.quickAnimation, value: isActive)
    }
}

// MARK: - Panel Drag Preview

struct PanelDragPreview: View {
    let panel: DockPanel
    let location: CGPoint
    
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = panel.icon {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.accent)
            }
            
            Text(panel.title)
                .font(theme.typography.headerFont)
                .fontWeight(theme.typography.headerFontWeight)
                .foregroundColor(theme.colors.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.colors.panelBackground)
                .shadow(color: theme.colors.shadowColor, radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(theme.colors.accent, lineWidth: 2)
        )
        .position(location)
    }
}
