import SwiftUI

// MARK: - Dashboard Demo

/// Demo showing dashboard-style layout
struct DashboardDemoView: View {
    @StateObject private var dockState: DockState
    
    init() {
        let layout = Self.createDashboardLayout()
        _dockState = StateObject(wrappedValue: DockState(layout: layout))
    }
    
    var body: some View {
        DockingSystem(state: dockState, theme: DarkDockTheme())
    }
    
    static func createDashboardLayout() -> DockLayout {
        let layout = DockLayout()
        
        // Left - Navigation
        let navigation = DockPanel(
            id: "navigation",
            title: "Navigation",
            icon: "sidebar.left",
            position: .left,
            visibility: [.showHeader, .allowDrag]
        ) {
            NavigationPanelContent()
        }
        
        let leftGroup = DockPanelGroup(panels: [navigation], position: .left)
        layout.leftNode = .panel(leftGroup)
        layout.leftWidth = 220
        
        // Center - Main dashboard with splits
        let chart1 = DockPanel(id: "chart1", title: "Revenue", icon: "chart.line.uptrend.xyaxis") {
            ChartWidgetView(title: "Revenue", color: .green)
        }
        let chart2 = DockPanel(id: "chart2", title: "Users", icon: "person.2") {
            ChartWidgetView(title: "Active Users", color: .blue)
        }
        let chart3 = DockPanel(id: "chart3", title: "Performance", icon: "gauge") {
            ChartWidgetView(title: "Performance", color: .orange)
        }
        let chart4 = DockPanel(id: "chart4", title: "Conversion", icon: "arrow.triangle.2.circlepath") {
            ChartWidgetView(title: "Conversion Rate", color: .purple)
        }
        
        // Create 2x2 grid using nested splits
        let topSplit = DockSplitNode(
            orientation: .horizontal,
            first: .panel(DockPanelGroup(panels: [chart1], position: .center)),
            second: .panel(DockPanelGroup(panels: [chart2], position: .center)),
            splitRatio: 0.5
        )
        
        let bottomSplit = DockSplitNode(
            orientation: .horizontal,
            first: .panel(DockPanelGroup(panels: [chart3], position: .center)),
            second: .panel(DockPanelGroup(panels: [chart4], position: .center)),
            splitRatio: 0.5
        )
        
        let mainSplit = DockSplitNode(
            orientation: .vertical,
            first: .split(topSplit),
            second: .split(bottomSplit),
            splitRatio: 0.5
        )
        
        layout.centerNode = .split(mainSplit)
        
        // Right - Details
        let details = DockPanel(
            id: "details",
            title: "Details",
            icon: "info.circle",
            position: .right
        ) {
            DetailsPanelContent()
        }
        
        let rightGroup = DockPanelGroup(panels: [details], position: .right)
        layout.rightNode = .panel(rightGroup)
        layout.rightWidth = 300
        
        return layout
    }
}

// MARK: - Dashboard Content Views

struct NavigationPanelContent: View {
    @State private var selectedItem = "Dashboard"
    
    let items = [
        ("Dashboard", "square.grid.2x2"),
        ("Analytics", "chart.bar"),
        ("Reports", "doc.text"),
        ("Settings", "gear"),
        ("Users", "person.2"),
        ("Notifications", "bell")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(items, id: \.0) { item in
                    NavigationItem(
                        title: item.0,
                        icon: item.1,
                        isSelected: selectedItem == item.0
                    ) {
                        selectedItem = item.0
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct NavigationItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : (isHovered ? Color.gray.opacity(0.1) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct ChartWidgetView: View {
    let title: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(randomValue)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                Text(randomChange)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .cornerRadius(4)
            }
            
            // Simple chart visualization
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let points = generateChartPoints(width: width, height: height)
                    
                    path.move(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                
                // Area fill
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let points = generateChartPoints(width: width, height: height)
                    
                    path.move(to: CGPoint(x: 0, y: height))
                    path.addLine(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .padding()
    }
    
    private var randomValue: String {
        let value = Int.random(in: 1000...99999)
        return "$\(value.formatted())"
    }
    
    private var randomChange: String {
        let change = Double.random(in: -15...25)
        return String(format: "%+.1f%%", change)
    }
    
    private func generateChartPoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        let count = 12
        return (0..<count).map { i in
            CGPoint(
                x: CGFloat(i) / CGFloat(count - 1) * width,
                y: height * CGFloat.random(in: 0.2...0.8)
            )
        }
    }
}

struct DetailsPanelContent: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Stats cards
                VStack(spacing: 12) {
                    StatCard(title: "Total Revenue", value: "$124,500", change: "+12.5%", isPositive: true)
                    StatCard(title: "Active Users", value: "8,432", change: "+5.2%", isPositive: true)
                    StatCard(title: "Bounce Rate", value: "24.8%", change: "-3.1%", isPositive: true)
                    StatCard(title: "Avg. Session", value: "4m 32s", change: "-8.4%", isPositive: false)
                }
                
                Divider()
                
                // Recent activity
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Activity")
                        .font(.headline)
                    
                    ForEach(0..<5) { i in
                        ActivityRow(index: i)
                    }
                }
            }
            .padding()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(change)
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ActivityRow: View {
    let index: Int
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(colors[index % colors.count])
                .frame(width: 8, height: 8)
            
            Text(activities[index % activities.count])
                .font(.system(size: 12))
            
            Spacer()
            
            Text("\(Int.random(in: 1...59))m ago")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private let colors: [Color] = [.blue, .green, .orange, .purple, .red]
    private let activities = [
        "New user signed up",
        "Order completed",
        "Payment received",
        "Report generated",
        "Settings updated"
    ]
}

// MARK: - Creative App Demo

/// Demo showing creative app layout (like design tools)
struct CreativeAppDemoView: View {
    @StateObject private var dockState: DockState
    
    init() {
        let layout = Self.createCreativeLayout()
        _dockState = StateObject(wrappedValue: DockState(layout: layout))
    }
    
    var body: some View {
        DockingSystem(state: dockState, theme: VSCodeDockTheme())
    }
    
    static func createCreativeLayout() -> DockLayout {
        let layout = DockLayout()
        
        // Left - Tools & Layers
        let tools = DockPanel(
            id: "tools",
            title: "Tools",
            icon: "wrench.and.screwdriver"
        ) {
            ToolsPanelContent()
        }
        
        let layers = DockPanel(
            id: "layers",
            title: "Layers",
            icon: "square.3.layers.3d"
        ) {
            LayersPanelContent()
        }
        
        let assets = DockPanel(
            id: "assets",
            title: "Assets",
            icon: "photo.on.rectangle"
        ) {
            AssetsPanelContent()
        }
        
        // Create split for left side
        let leftSplit = DockSplitNode(
            orientation: .vertical,
            first: .panel(DockPanelGroup(panels: [tools], position: .left)),
            second: .panel(DockPanelGroup(panels: [layers, assets], position: .left)),
            splitRatio: 0.4
        )
        
        layout.leftNode = .split(leftSplit)
        layout.leftWidth = 240
        
        // Center - Canvas
        let canvas = DockPanel(
            id: "canvas",
            title: "Canvas",
            icon: "rectangle.dashed",
            visibility: [.showHeader, .allowTabbing]
        ) {
            CanvasView()
        }
        
        let centerGroup = DockPanelGroup(panels: [canvas], position: .center)
        layout.centerNode = .panel(centerGroup)
        
        // Right - Properties
        let properties = DockPanel(
            id: "properties",
            title: "Properties",
            icon: "slider.horizontal.3"
        ) {
            PropertiesPanelContent()
        }
        
        let rightGroup = DockPanelGroup(panels: [properties], position: .right)
        layout.rightNode = .panel(rightGroup)
        layout.rightWidth = 280
        
        return layout
    }
}

// MARK: - Creative App Content Views

struct ToolsPanelContent: View {
    @State private var selectedTool = "select"
    
    let tools = [
        ("select", "arrow.up.left.and.arrow.down.right"),
        ("move", "arrow.up.and.down.and.arrow.left.and.right"),
        ("pen", "pencil"),
        ("brush", "paintbrush"),
        ("eraser", "eraser"),
        ("shape", "rectangle"),
        ("text", "textformat"),
        ("eyedropper", "eyedropper")
    ]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 4) {
            ForEach(tools, id: \.0) { tool in
                ToolButton(
                    icon: tool.1,
                    isSelected: selectedTool == tool.0
                ) {
                    selectedTool = tool.0
                }
            }
        }
        .padding(8)
    }
}

struct ToolButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.accentColor : (isHovered ? Color.gray.opacity(0.2) : Color.clear))
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct LayersPanelContent: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<8) { i in
                    LayerRow(index: i, isSelected: i == 2)
                }
            }
        }
    }
}

struct LayerRow: View {
    let index: Int
    let isSelected: Bool
    @State private var isVisible = true
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: { isVisible.toggle() }) {
                Image(systemName: isVisible ? "eye" : "eye.slash")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(colors[index % colors.count])
                .frame(width: 24, height: 24)
            
            Text("Layer \(index + 1)")
                .font(.system(size: 12))
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.2) : (isHovered ? Color.gray.opacity(0.1) : Color.clear))
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private let colors: [Color] = [.blue, .red, .green, .orange, .purple, .pink, .yellow, .cyan]
}

struct AssetsPanelContent: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
            ForEach(0..<12) { i in
                AssetThumbnail(index: i)
            }
        }
        .padding(8)
    }
}

struct AssetThumbnail: View {
    let index: Int
    @State private var isHovered = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.gray.opacity(0.2))
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Image(systemName: icons[index % icons.count])
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isHovered ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .onHover { hovering in
                isHovered = hovering
            }
    }
    
    private let icons = ["photo", "square", "circle", "triangle", "star", "heart", "bolt", "leaf", "drop", "flame", "moon", "sun.max"]
}

struct CanvasView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Checkerboard background
                CheckerboardPattern()
                
                // Artboard
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: min(geometry.size.width * 0.7, 400), height: min(geometry.size.height * 0.7, 300))
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                    .overlay(
                        VStack {
                            Image(systemName: "photo.artframe")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.3))
                            Text("Your Design Here")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
    }
}

struct CheckerboardPattern: View {
    var body: some View {
        GeometryReader { geometry in
            let size: CGFloat = 20
            let rows = Int(geometry.size.height / size) + 1
            let cols = Int(geometry.size.width / size) + 1
            
            Canvas { context, _ in
                for row in 0..<rows {
                    for col in 0..<cols {
                        let isEven = (row + col) % 2 == 0
                        let rect = CGRect(
                            x: CGFloat(col) * size,
                            y: CGFloat(row) * size,
                            width: size,
                            height: size
                        )
                        context.fill(
                            Path(rect),
                            with: .color(isEven ? Color(white: 0.15) : Color(white: 0.12))
                        )
                    }
                }
            }
        }
    }
}

struct PropertiesPanelContent: View {
    @State private var width: Double = 400
    @State private var height: Double = 300
    @State private var opacity: Double = 100
    @State private var cornerRadius: Double = 8
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PropertySection(title: "Transform") {
                    PropertySlider(label: "Width", value: $width, range: 100...800)
                    PropertySlider(label: "Height", value: $height, range: 100...600)
                }
                
                PropertySection(title: "Appearance") {
                    PropertySlider(label: "Opacity", value: $opacity, range: 0...100, suffix: "%")
                    PropertySlider(label: "Corner Radius", value: $cornerRadius, range: 0...50)
                }
                
                PropertySection(title: "Fill") {
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 24, height: 24)
                        Text("#007AFF")
                            .font(.system(size: 12, design: .monospaced))
                        Spacer()
                    }
                }
            }
            .padding()
        }
    }
}

struct PropertySection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            
            content()
        }
    }
}

struct PropertySlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var suffix: String = ""
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 12))
                Spacer()
                Text("\(Int(value))\(suffix)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $value, in: range)
                .tint(.accentColor)
        }
    }
}

// MARK: - Preview

#Preview("Dashboard") {
    DashboardDemoView()
}

#Preview("Creative App") {
    CreativeAppDemoView()
}
