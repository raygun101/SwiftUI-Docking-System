import SwiftUI

// MARK: - Floating Panel View

/// A floating, draggable panel window
struct FloatingPanelView: View {
    @ObservedObject var group: DockPanelGroup
    let containerSize: CGSize
    
    @EnvironmentObject var state: DockState
    @Environment(\.dockTheme) var theme
    
    @State private var position: CGPoint = CGPoint(x: 100, y: 100)
    @State private var size: CGSize = CGSize(width: 300, height: 250)
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        VStack(spacing: 0) {
            // Floating header with drag handle
            floatingHeader
            
            // Tab bar if multiple panels
            if group.panels.count > 1 {
                floatingTabBar
            }
            
            // Content
            if let activePanel = group.activePanel {
                activePanel.content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
        }
        .frame(width: size.width, height: size.height)
        .background(theme.colors.panelBackground)
        .cornerRadius(theme.cornerRadii.floating)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadii.floating)
                .strokeBorder(
                    group.activePanel?.isActive == true ? theme.colors.activeBorder : theme.colors.border,
                    lineWidth: group.activePanel?.isActive == true
                        ? theme.borders.activeBorderWidth
                        : theme.borders.borderWidth
                )
        )
        .shadow(
            color: theme.colors.shadowColor,
            radius: theme.shadows.floatingShadowRadius,
            x: theme.shadows.floatingShadowOffset.width,
            y: theme.shadows.floatingShadowOffset.height
        )
        .overlay(resizeHandles)
        .position(x: position.x + size.width / 2, y: position.y + size.height / 2)
        .offset(dragOffset)
        .animation(isDragging ? nil : theme.animations.springAnimation, value: position)
        .onAppear {
            if let frame = group.activePanel?.floatingFrame {
                position = CGPoint(x: frame.origin.x, y: frame.origin.y)
                size = frame.size
            }
        }
    }
    
    // MARK: - Floating Header
    
    private var floatingHeader: some View {
        HStack(spacing: theme.spacing.tabPadding) {
            // Window controls
            HStack(spacing: 6) {
                WindowControlButton(color: .red) {
                    closeFloatingPanel()
                }
                
                WindowControlButton(color: .yellow) {
                    minimizeFloatingPanel()
                }
                
                WindowControlButton(color: .green) {
                    maximizeFloatingPanel()
                }
            }
            .padding(.leading, 4)
            
            Spacer()
            
            // Title
            if let panel = group.activePanel {
                HStack(spacing: 4) {
                    if let icon = panel.icon {
                        Image(systemName: icon)
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.secondaryText)
                    }
                    Text(panel.title)
                        .font(theme.typography.headerFont)
                        .fontWeight(theme.typography.headerFontWeight)
                        .foregroundColor(theme.colors.text)
                }
            }
            
            Spacer()
            
            // Dock button
            Button(action: dockPanel) {
                Image(systemName: "rectangle.inset.filled.and.person.filled")
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.secondaryText)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
        }
        .frame(height: 32)
        .background(theme.colors.headerBackground)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    isDragging = false
                    position.x += value.translation.width
                    position.y += value.translation.height
                    dragOffset = .zero
                    
                    // Constrain to container
                    position.x = max(0, min(containerSize.width - size.width, position.x))
                    position.y = max(0, min(containerSize.height - size.height, position.y))
                }
        )
    }
    
    // MARK: - Tab Bar
    
    private var floatingTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(group.panels.enumerated()), id: \.element.id) { index, panel in
                    FloatingTabItem(
                        panel: panel,
                        isActive: index == group.activeTabIndex,
                        onSelect: { group.activeTabIndex = index },
                        onClose: { state.closePanel(panel) }
                    )
                }
            }
        }
        .frame(height: 28)
        .background(theme.colors.tabBackground)
        .overlay(
            Rectangle()
                .frame(height: theme.borders.separatorWidth)
                .foregroundColor(theme.colors.separator),
            alignment: .bottom
        )
    }
    
    // MARK: - Resize Handles
    
    private var resizeHandles: some View {
        GeometryReader { geometry in
            // Bottom-right corner resize
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10))
                        .foregroundColor(theme.colors.tertiaryText)
                        .frame(width: 16, height: 16)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 1)
                                .onChanged { value in
                                    let newWidth = max(200, size.width + value.translation.width)
                                    let newHeight = max(150, size.height + value.translation.height)
                                    size = CGSize(width: newWidth, height: newHeight)
                                }
                        )
                }
            }
            .padding(4)
        }
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

// MARK: - Window Control Button

struct WindowControlButton: View {
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .opacity(isHovered ? 1.0 : 0.8)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Floating Tab Item

struct FloatingTabItem: View {
    let panel: DockPanel
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = panel.icon {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(isActive ? theme.colors.accent : theme.colors.secondaryText)
            }
            
            Text(panel.title)
                .font(.system(size: 11))
                .foregroundColor(isActive ? theme.colors.text : theme.colors.secondaryText)
                .lineLimit(1)
            
            if isHovered || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(theme.colors.tertiaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isActive ? theme.colors.activeTabBackground : (isHovered ? theme.colors.hoverBackground : Color.clear))
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
