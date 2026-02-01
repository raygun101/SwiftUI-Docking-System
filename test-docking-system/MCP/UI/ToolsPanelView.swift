import SwiftUI

// MARK: - Tools Panel View

public struct ToolsPanelView: View {
    @StateObject private var registry = MCPToolRegistry.shared
    @State private var searchText: String = ""
    @State private var selectedCategory: ToolDefinition.ToolCategory?
    @State private var selectedTool: ToolDefinition?
    @State private var showingToolRunner = false
    
    @Environment(\.dockTheme) var theme
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            toolsHeader
            
            Divider()
            
            // Category tabs
            categoryTabs
            
            Divider()
            
            // Tools list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredTools, id: \.id) { tool in
                        ToolCard(tool: tool, isSelected: selectedTool?.id == tool.id) {
                            selectedTool = tool
                        } onRun: {
                            selectedTool = tool
                            showingToolRunner = true
                        }
                    }
                }
                .padding()
            }
        }
        .background(theme.colors.panelBackground)
        .sheet(isPresented: $showingToolRunner) {
            if let tool = selectedTool {
                ToolRunnerSheet(tool: tool)
            }
        }
    }
    
    private var toolsHeader: some View {
        HStack {
            Image(systemName: "wrench.and.screwdriver")
                .foregroundColor(.orange)
            
            Text("Tools")
                .font(.headline)
            
            Spacer()
            
            Text("\(registry.tools.count)")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(theme.colors.secondaryBackground)
                .cornerRadius(10)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(theme.colors.headerBackground)
    }
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryTab(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                ForEach(ToolDefinition.ToolCategory.allCases, id: \.self) { category in
                    if let tools = registry.categories[category], !tools.isEmpty {
                        CategoryTab(
                            title: category.rawValue,
                            icon: categoryIcon(category),
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(theme.colors.secondaryBackground.opacity(0.5))
    }
    
    private var filteredTools: [ToolDefinition] {
        var tools = registry.allDefinitions()
        
        if let category = selectedCategory {
            tools = tools.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            tools = tools.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return tools.sorted { $0.name < $1.name }
    }
    
    private func categoryIcon(_ category: ToolDefinition.ToolCategory) -> String {
        switch category {
        case .file: return "folder"
        case .code: return "curlybraces"
        case .image: return "photo"
        case .audio: return "speaker.wave.2"
        case .chat: return "bubble.left.and.bubble.right"
        case .project: return "folder.badge.gearshape"
        case .web: return "globe"
        case .system: return "terminal"
        case .custom: return "puzzlepiece"
        }
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.orange.opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? .orange : .secondary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tool Card

struct ToolCard: View {
    let tool: ToolDefinition
    let isSelected: Bool
    let onSelect: () -> Void
    let onRun: () -> Void
    
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: tool.icon)
                        .font(.title3)
                        .foregroundColor(.orange)
                        .frame(width: 32, height: 32)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tool.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(tool.category.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: onRun) {
                        Image(systemName: "play.fill")
                            .font(.caption)
                            .padding(6)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                
                Text(tool.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if !tool.parameters.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tool.parameters.prefix(3)) { param in
                            Text(param.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(theme.colors.secondaryBackground)
                                .cornerRadius(4)
                        }
                        if tool.parameters.count > 3 {
                            Text("+\(tool.parameters.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(12)
            .background(isSelected ? Color.orange.opacity(0.1) : theme.colors.secondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tool Runner Sheet

struct ToolRunnerSheet: View {
    let tool: ToolDefinition
    
    @State private var parameterValues: [String: String] = [:]
    @State private var isRunning = false
    @State private var result: ToolResult?
    @Environment(\.dismiss) var dismiss
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Tool info
                        HStack {
                            Image(systemName: tool.icon)
                                .font(.title2)
                                .foregroundColor(.orange)
                                .frame(width: 44, height: 44)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(10)
                            
                            VStack(alignment: .leading) {
                                Text(tool.name)
                                    .font(.headline)
                                Text(tool.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.colors.secondaryBackground)
                        .cornerRadius(12)
                        
                        // Parameters
                        if !tool.parameters.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Parameters")
                                    .font(.headline)
                                
                                ForEach(tool.parameters) { param in
                                    ParameterInput(
                                        parameter: param,
                                        value: Binding(
                                            get: { parameterValues[param.name] ?? param.defaultValue ?? "" },
                                            set: { parameterValues[param.name] = $0 }
                                        )
                                    )
                                }
                            }
                        }
                        
                        // Result
                        if let result = result {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Result")
                                    .font(.headline)
                                
                                ToolResultView(result: result)
                            }
                        }
                    }
                    .padding()
                }
                
                // Run button
                Button(action: runTool) {
                    HStack {
                        if isRunning {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text(isRunning ? "Running..." : "Run Tool")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isRunning)
                .padding()
            }
            .navigationTitle("Run Tool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func runTool() {
        isRunning = true
        result = nil
        
        Task {
            var params: [String: ToolParameterValue] = [:]
            for (key, value) in parameterValues {
                params[key] = .string(value)
            }
            
            let invocation = ToolInvocation(toolID: tool.id, parameters: params)
            let toolResult = await MCPToolExecutor.shared.execute(invocation)
            
            await MainActor.run {
                result = toolResult
                isRunning = false
            }
        }
    }
}

// MARK: - Parameter Input

struct ParameterInput: View {
    let parameter: ToolParameter
    @Binding var value: String
    
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(parameter.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if parameter.required {
                    Text("*")
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Text(parameter.type.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.colors.secondaryBackground)
                    .cornerRadius(4)
            }
            
            Text(parameter.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let options = parameter.options, !options.isEmpty {
                Picker("", selection: $value) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
            } else {
                switch parameter.type {
                case .boolean:
                    Toggle("", isOn: Binding(
                        get: { value == "true" },
                        set: { value = $0 ? "true" : "false" }
                    ))
                    .labelsHidden()
                    
                case .number:
                    TextField("Enter number", text: $value)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                    
                default:
                    if parameter.type == .string && parameter.name.contains("content") {
                        TextEditor(text: $value)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3))
                            )
                    } else {
                        TextField("Enter \(parameter.name)", text: $value)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
        .padding(12)
        .background(theme.colors.secondaryBackground.opacity(0.5))
        .cornerRadius(10)
    }
}
