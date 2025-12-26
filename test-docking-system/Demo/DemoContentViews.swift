import SwiftUI

// MARK: - Demo Content Views

/// File explorer panel content
struct FileExplorerView: View {
    @State private var expandedFolders: Set<String> = ["Sources"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                FileTreeItem(name: "MyProject", icon: "folder.fill", isFolder: true, level: 0, isExpanded: true) {
                    FileTreeItem(name: "Sources", icon: "folder.fill", isFolder: true, level: 1, isExpanded: expandedFolders.contains("Sources")) {
                        FileTreeItem(name: "App.swift", icon: "swift", isFolder: false, level: 2)
                        FileTreeItem(name: "ContentView.swift", icon: "swift", isFolder: false, level: 2)
                        FileTreeItem(name: "Models", icon: "folder.fill", isFolder: true, level: 2, isExpanded: false) {}
                        FileTreeItem(name: "Views", icon: "folder.fill", isFolder: true, level: 2, isExpanded: false) {}
                        FileTreeItem(name: "Utilities", icon: "folder.fill", isFolder: true, level: 2, isExpanded: false) {}
                    }
                    FileTreeItem(name: "Resources", icon: "folder.fill", isFolder: true, level: 1, isExpanded: false) {}
                    FileTreeItem(name: "Tests", icon: "folder.fill", isFolder: true, level: 1, isExpanded: false) {}
                    FileTreeItem(name: "Package.swift", icon: "swift", isFolder: false, level: 1)
                    FileTreeItem(name: "README.md", icon: "doc.text", isFolder: false, level: 1)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct FileTreeItem<Content: View>: View {
    let name: String
    let icon: String
    let isFolder: Bool
    let level: Int
    var isExpanded: Bool = false
    let content: () -> Content
    
    @State private var isHovered = false
    @State private var localExpanded: Bool
    
    init(
        name: String,
        icon: String,
        isFolder: Bool,
        level: Int,
        isExpanded: Bool = false,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.name = name
        self.icon = icon
        self.isFolder = isFolder
        self.level = level
        self.isExpanded = isExpanded
        self.content = content
        _localExpanded = State(initialValue: isExpanded)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                if isFolder {
                    Image(systemName: localExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 12)
                } else {
                    Spacer().frame(width: 12)
                }
                
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
                
                Text(name)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.leading, CGFloat(level) * 16 + 8)
            .padding(.vertical, 4)
            .background(isHovered ? Color.gray.opacity(0.15) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                if isFolder {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        localExpanded.toggle()
                    }
                }
            }
            .onHover { hovering in
                isHovered = hovering
            }
            
            if isFolder && localExpanded {
                content()
            }
        }
    }
    
    private var iconName: String {
        if icon == "swift" {
            return "swift"
        }
        return isFolder ? (localExpanded ? "folder.fill" : "folder.fill") : icon
    }
    
    private var iconColor: Color {
        if icon == "swift" {
            return .orange
        }
        return isFolder ? .blue : .secondary
    }
}

/// Code editor panel content
struct CodeEditorView: View {
    let fileName: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(sampleCode.enumerated()), id: \.offset) { index, line in
                    HStack(alignment: .top, spacing: 0) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                            .padding(.trailing, 12)
                        
                        Text(line)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(syntaxColor(for: line))
                        
                        Spacer()
                    }
                    .padding(.vertical, 1)
                }
            }
            .padding()
        }
        .background(Color(white: 0.12))
    }
    
    private func syntaxColor(for line: String) -> Color {
        if line.hasPrefix("import") || line.hasPrefix("struct") || line.hasPrefix("class") || line.hasPrefix("func") {
            return .purple
        } else if line.hasPrefix("//") {
            return .green
        } else if line.contains("\"") {
            return .red
        }
        return .white
    }
    
    private var sampleCode: [String] {
        [
            "import SwiftUI",
            "",
            "// Main content view",
            "struct ContentView: View {",
            "    @State private var count = 0",
            "    ",
            "    var body: some View {",
            "        VStack(spacing: 20) {",
            "            Text(\"Hello, World!\")",
            "                .font(.largeTitle)",
            "            ",
            "            Button(\"Tap me\") {",
            "                count += 1",
            "            }",
            "            ",
            "            Text(\"Count: \\(count)\")",
            "        }",
            "        .padding()",
            "    }",
            "}",
            "",
            "#Preview {",
            "    ContentView()",
            "}"
        ]
    }
}

/// Console/Terminal panel content
struct ConsoleView: View {
    @State private var logs: [LogEntry] = [
        LogEntry(type: .info, message: "Build started..."),
        LogEntry(type: .info, message: "Compiling Swift sources..."),
        LogEntry(type: .success, message: "Build succeeded"),
        LogEntry(type: .info, message: "Running on iPhone 15 Pro..."),
        LogEntry(type: .debug, message: "App launched successfully"),
        LogEntry(type: .warning, message: "Deprecated API usage in ContentView.swift:15"),
        LogEntry(type: .info, message: "User interaction detected"),
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(logs) { log in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: log.type.icon)
                            .font(.system(size: 11))
                            .foregroundColor(log.type.color)
                            .frame(width: 14)
                        
                        Text(log.timestamp)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Text(log.message)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(log.type.color)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(white: 0.08))
    }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let type: LogType
    let message: String
    let timestamp: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }()
    
    enum LogType {
        case info, debug, warning, error, success
        
        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .debug: return "ladybug"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            case .success: return "checkmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .info: return .secondary
            case .debug: return .cyan
            case .warning: return .yellow
            case .error: return .red
            case .success: return .green
            }
        }
    }
}

/// Inspector panel content
struct InspectorView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                InspectorSection(title: "Identity") {
                    InspectorRow(label: "Name", value: "ContentView")
                    InspectorRow(label: "Type", value: "View")
                    InspectorRow(label: "Module", value: "MyApp")
                }
                
                InspectorSection(title: "Frame") {
                    InspectorRow(label: "X", value: "0")
                    InspectorRow(label: "Y", value: "0")
                    InspectorRow(label: "Width", value: "390")
                    InspectorRow(label: "Height", value: "844")
                }
                
                InspectorSection(title: "Appearance") {
                    InspectorRow(label: "Background", value: "System")
                    InspectorRow(label: "Opacity", value: "1.0")
                    InspectorRow(label: "Corner Radius", value: "0")
                }
                
                InspectorSection(title: "Layout") {
                    InspectorRow(label: "Alignment", value: "Center")
                    InspectorRow(label: "Spacing", value: "8")
                    InspectorRow(label: "Padding", value: "16")
                }
            }
            .padding()
        }
    }
}

struct InspectorSection<Content: View>: View {
    let title: String
    let content: () -> Content
    @State private var isExpanded = true
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Text(title.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 6) {
                    content()
                }
            }
        }
    }
}

struct InspectorRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(4)
        }
    }
}

/// Debug panel content
struct DebugView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                DebugSection(title: "Variables") {
                    DebugVariable(name: "count", type: "Int", value: "42")
                    DebugVariable(name: "isEnabled", type: "Bool", value: "true")
                    DebugVariable(name: "title", type: "String", value: "\"Hello\"")
                }
                
                DebugSection(title: "Call Stack") {
                    ForEach(0..<5) { i in
                        Text("\(i). ContentView.body.getter")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                
                DebugSection(title: "Breakpoints") {
                    BreakpointRow(file: "ContentView.swift", line: 15, enabled: true)
                    BreakpointRow(file: "App.swift", line: 8, enabled: false)
                }
            }
            .padding()
        }
    }
}

struct DebugSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            
            content()
        }
    }
}

struct DebugVariable: View {
    let name: String
    let type: String
    let value: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary)
            
            Text(type)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.purple)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.green)
        }
    }
}

struct BreakpointRow: View {
    let file: String
    let line: Int
    let enabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: enabled ? "circle.fill" : "circle")
                .font(.system(size: 8))
                .foregroundColor(enabled ? .blue : .secondary)
            
            Text(file)
                .font(.system(size: 11))
                .foregroundColor(.primary)
            
            Text(":\(line)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

/// Search panel content
struct SearchView: View {
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(6)
            .padding()
            
            Divider()
            
            // Results
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SearchResult(file: "ContentView.swift", line: 5, preview: "struct ContentView: View {")
                    SearchResult(file: "ContentView.swift", line: 12, preview: "    Button(\"Tap me\") {")
                    SearchResult(file: "App.swift", line: 8, preview: "    ContentView()")
                }
            }
        }
    }
}

struct SearchResult: View {
    let file: String
    let line: Int
    let preview: String
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "swift")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                
                Text(file)
                    .font(.system(size: 12, weight: .medium))
                
                Text(":\(line)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text(preview)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isHovered ? Color.gray.opacity(0.15) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

/// Git/Source Control panel content
struct SourceControlView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Branch info
                HStack {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundColor(.green)
                    Text("main")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Text("↑2 ↓0")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Changes
                VStack(alignment: .leading, spacing: 8) {
                    Text("CHANGES")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    SourceControlFile(name: "ContentView.swift", status: .modified)
                    SourceControlFile(name: "NewFile.swift", status: .added)
                    SourceControlFile(name: "OldFile.swift", status: .deleted)
                }
            }
            .padding(.vertical)
        }
    }
}

struct SourceControlFile: View {
    let name: String
    let status: FileStatus
    @State private var isHovered = false
    
    enum FileStatus {
        case modified, added, deleted
        
        var icon: String {
            switch self {
            case .modified: return "M"
            case .added: return "A"
            case .deleted: return "D"
            }
        }
        
        var color: Color {
            switch self {
            case .modified: return .yellow
            case .added: return .green
            case .deleted: return .red
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "swift")
                .font(.system(size: 12))
                .foregroundColor(.orange)
            
            Text(name)
                .font(.system(size: 12))
            
            Spacer()
            
            Text(status.icon)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(isHovered ? Color.gray.opacity(0.15) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

/// Preview panel content
struct PreviewPanelView: View {
    @State private var selectedDevice = "iPhone 15 Pro"
    
    var body: some View {
        VStack(spacing: 0) {
            // Device selector
            HStack {
                Picker("Device", selection: $selectedDevice) {
                    Text("iPhone 15 Pro").tag("iPhone 15 Pro")
                    Text("iPhone 15").tag("iPhone 15")
                    Text("iPad Pro").tag("iPad Pro")
                }
                .pickerStyle(.menu)
                .frame(width: 150)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            
            // Preview area
            ZStack {
                Color.black.opacity(0.3)
                
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color.white)
                    .frame(width: 200, height: 400)
                    .overlay(
                        VStack {
                            Text("Preview")
                                .font(.title2)
                            Text("iPhone 15 Pro")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
                    .shadow(radius: 20)
            }
        }
    }
}

/// Problems panel content
struct ProblemsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ProblemRow(
                    type: .error,
                    message: "Cannot find 'undefined' in scope",
                    file: "ContentView.swift",
                    line: 25
                )
                ProblemRow(
                    type: .warning,
                    message: "Variable 'unused' was never used",
                    file: "Model.swift",
                    line: 12
                )
                ProblemRow(
                    type: .warning,
                    message: "Deprecated API usage",
                    file: "Network.swift",
                    line: 45
                )
            }
        }
    }
}

struct ProblemRow: View {
    let type: ProblemType
    let message: String
    let file: String
    let line: Int
    @State private var isHovered = false
    
    enum ProblemType {
        case error, warning
        
        var icon: String {
            switch self {
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .error: return .red
            case .warning: return .yellow
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: type.icon)
                .font(.system(size: 12))
                .foregroundColor(type.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.system(size: 12))
                
                HStack(spacing: 4) {
                    Text(file)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(":\(line)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Color.gray.opacity(0.15) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
