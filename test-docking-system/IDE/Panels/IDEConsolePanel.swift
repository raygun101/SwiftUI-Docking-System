import SwiftUI

// MARK: - Console Panel

/// Console/output panel for the IDE showing logs and messages
public struct IDEConsolePanel: View {
    @EnvironmentObject var ideState: IDEState
    @Environment(\.dockTheme) var theme
    
    @State private var logs: [ConsoleLogEntry] = []
    @State private var filter: LogFilter = .all
    @State private var searchText: String = ""
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            DockPanelToolbar { consoleToolbar }
            consoleOutput
        }
        .background(theme.colors.panelBackground)
    }
    
    // MARK: - Toolbar
    
    private var consoleToolbar: some View {
        HStack(spacing: 12) {
            Text("Console")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.colors.text)
            
            Spacer()
            
            // Filter picker
            Picker("Filter", selection: $filter) {
                ForEach(LogFilter.allCases, id: \.self) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            
            // Clear button
            Button(action: clearLogs) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundColor(theme.colors.secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.colors.headerBackground)
    }
    
    // MARK: - Output
    
    private var consoleOutput: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(filteredLogs) { entry in
                        ConsoleLogRow(entry: entry)
                    }
                }
                .padding(8)
            }
            .onChange(of: logs.count) { _, _ in
                if let lastLog = logs.last {
                    withAnimation {
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
        }
        .font(.system(size: 12, design: .monospaced))
        .onAppear {
            // Add initial log
            addLog("IDE initialized", level: .info)
            addLog("Project loaded successfully", level: .success)
        }
    }
    
    private var filteredLogs: [ConsoleLogEntry] {
        logs.filter { entry in
            switch filter {
            case .all: return true
            case .errors: return entry.level == .error
            case .warnings: return entry.level == .warning
            case .info: return entry.level == .info || entry.level == .success
            }
        }
    }
    
    // MARK: - Actions
    
    private func clearLogs() {
        logs.removeAll()
    }
    
    private func addLog(_ message: String, level: LogLevel) {
        let entry = ConsoleLogEntry(message: message, level: level)
        logs.append(entry)
    }
}

// MARK: - Console Log Entry

struct ConsoleLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let level: LogLevel
    
    init(message: String, level: LogLevel = .info) {
        self.timestamp = Date()
        self.message = message
        self.level = level
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

enum LogLevel: String {
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
    case success = "OK"
    case debug = "DEBUG"
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .success: return .green
        case .debug: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .success: return "checkmark.circle"
        case .debug: return "ant"
        }
    }
}

enum LogFilter: String, CaseIterable {
    case all = "All"
    case errors = "Errors"
    case warnings = "Warnings"
    case info = "Info"
}

// MARK: - Console Log Row

struct ConsoleLogRow: View {
    let entry: ConsoleLogEntry
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Timestamp
            Text(entry.formattedTime)
                .foregroundColor(theme.colors.tertiaryText)
                .frame(width: 60, alignment: .leading)
            
            // Level indicator
            Image(systemName: entry.level.icon)
                .foregroundColor(entry.level.color)
                .frame(width: 16)
            
            // Message
            Text(entry.message)
                .foregroundColor(theme.colors.text)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
