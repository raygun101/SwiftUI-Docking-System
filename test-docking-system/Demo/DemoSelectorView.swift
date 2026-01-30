import SwiftUI

// MARK: - Demo Selector View

/// Main view for selecting and viewing different demo layouts
struct DemoSelectorView: View {
    @State private var selectedDemo: DemoType = .fullIDE
    @State private var showDemoInfo = false
    
    var body: some View {
        ZStack {
            // Selected demo
            Group {
                switch selectedDemo {
                case .fullIDE:
                    IDEAppView()
                case .ide:
                    IDEDemoView()
                case .dashboard:
                    DashboardDemoView()
                case .creative:
                    CreativeAppDemoView()
                case .simple:
                    SimpleDemoView()
                }
            }
            
            // Demo selector overlay
            VStack {
                Spacer()
                
                HStack {
                    demoSelector
                        .padding(16)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var demoSelector: some View {
        HStack(spacing: 8) {
            ForEach(DemoType.allCases, id: \.self) { demo in
                DemoSelectorButton(
                    demo: demo,
                    isSelected: selectedDemo == demo
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedDemo = demo
                    }
                }
            }
            
            Divider()
                .frame(height: 24)
            
            Button(action: { showDemoInfo.toggle() }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDemoInfo) {
                demoInfoPopover
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
    }
    
    private var demoInfoPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("iOS Docking System Demo")
                .font(.headline)
            
            Text("This demo showcases a professional IDE-quality docking panel system for iOS applications.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "rectangle.split.3x1", text: "Flexible panel positions")
                FeatureRow(icon: "arrow.left.and.right", text: "Resizable panels")
                FeatureRow(icon: "rectangle.stack", text: "Tabbed panel groups")
                FeatureRow(icon: "uiwindow.split.2x1", text: "Floating windows")
                FeatureRow(icon: "paintbrush", text: "Multiple themes")
                FeatureRow(icon: "hand.draw", text: "Long-press to drag panels")
                FeatureRow(icon: "arrow.clockwise", text: "Layout auto-saved")
            }
            
            Divider()
            
            Text("Long-press on a panel header or tab to start dragging. Drop on edges to dock.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 280)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
        }
    }
}

// MARK: - Demo Types

enum DemoType: String, CaseIterable {
    case fullIDE = "Web IDE"
    case ide = "Demo IDE"
    case dashboard = "Dashboard"
    case creative = "Creative"
    case simple = "Simple"
    
    var icon: String {
        switch self {
        case .fullIDE: return "globe"
        case .ide: return "hammer"
        case .dashboard: return "chart.bar"
        case .creative: return "paintbrush"
        case .simple: return "rectangle.split.3x1"
        }
    }
    
    var description: String {
        switch self {
        case .fullIDE: return "Full-featured web IDE with project management"
        case .ide: return "Demo IDE layout with file explorer, editor, console"
        case .dashboard: return "Dashboard with charts and analytics widgets"
        case .creative: return "Creative app with tools, layers, and canvas"
        case .simple: return "Simple layout demonstrating basic features"
        }
    }
}

struct DemoSelectorButton: View {
    let demo: DemoType
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: demo.icon)
                    .font(.system(size: 12))
                
                if isSelected {
                    Text(demo.rawValue)
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, isSelected ? 12 : 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : (isHovered ? Color.gray.opacity(0.2) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Simple Demo View

/// Simple demo showing basic docking capabilities
struct SimpleDemoView: View {
    @StateObject private var dockState: DockState
    @EnvironmentObject private var themeManager: ThemeManager
    
    init() {
        let layout = Self.createSimpleLayout()
        _dockState = StateObject(wrappedValue: DockState(layout: layout))
    }
    
    var body: some View {
        DockingSystem(state: dockState, theme: themeManager.currentTheme)
    }
    
    static func createSimpleLayout() -> DockLayout {
        let layout = DockLayout()
        
        // Left panel
        let leftPanel = DockPanel(
            id: "left",
            title: "Left Panel",
            icon: "sidebar.left",
            position: .left
        ) {
            SimplePanelContent(title: "Left Panel", color: .blue)
        }
        
        let leftGroup = DockPanelGroup(panels: [leftPanel], position: .left)
        layout.leftNode = .panel(leftGroup)
        layout.leftWidth = 250
        
        // Center panel
        let centerPanel = DockPanel(
            id: "center",
            title: "Main Content",
            icon: "doc.text",
            position: .center
        ) {
            SimplePanelContent(title: "Main Content Area", color: .green)
        }
        
        let centerGroup = DockPanelGroup(panels: [centerPanel], position: .center)
        layout.centerNode = .panel(centerGroup)
        
        // Right panel
        let rightPanel = DockPanel(
            id: "right",
            title: "Right Panel",
            icon: "sidebar.right",
            position: .right
        ) {
            SimplePanelContent(title: "Right Panel", color: .orange)
        }
        
        let rightGroup = DockPanelGroup(panels: [rightPanel], position: .right)
        layout.rightNode = .panel(rightGroup)
        layout.rightWidth = 250
        
        // Bottom panel
        let bottomPanel = DockPanel(
            id: "bottom",
            title: "Bottom Panel",
            icon: "rectangle.bottomthird.inset.filled",
            position: .bottom
        ) {
            SimplePanelContent(title: "Bottom Panel", color: .purple)
        }
        
        let bottomGroup = DockPanelGroup(panels: [bottomPanel], position: .bottom)
        layout.bottomNode = .panel(bottomGroup)
        layout.bottomHeight = 180
        
        return layout
    }
}

struct SimplePanelContent: View {
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.dashed")
                .font(.system(size: 40))
                .foregroundColor(color.opacity(0.5))
            
            Text(title)
                .font(.headline)
            
            Text("Drag the panel header to rearrange.\nResize using the panel borders.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color.opacity(0.05))
    }
}

// MARK: - Preview

#Preview {
    DemoSelectorView()
        .environmentObject(ThemeManager())
}
