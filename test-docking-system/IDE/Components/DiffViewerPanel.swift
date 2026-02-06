import SwiftUI

// MARK: - Diff Viewer Panel

/// A content panel that shows a diff between the saved disk version and the current in-memory version
/// of a document. When agent changes are present, shows old vs new agent content instead.
struct DiffViewerPanel: View {
    @ObservedObject var document: IDEDocument
    @Environment(\.dockTheme) var theme
    
    @State private var showOnlyChanges = false
    
    private var diffSource: DiffSource {
        if let agentChange = document.agentChange {
            return DiffSource(
                label: "Agent Changes",
                icon: "wand.and.stars",
                oldContent: agentChange.oldContent,
                newContent: agentChange.newContent,
                timestamp: agentChange.timestamp
            )
        } else {
            return DiffSource(
                label: document.isDirty ? "Unsaved Changes" : "No Changes",
                icon: document.isDirty ? "pencil.circle" : "checkmark.circle",
                oldContent: document.buffer.diskContent,
                newContent: document.buffer.currentContent,
                timestamp: document.lastModified
            )
        }
    }
    
    private var diffLines: [DiffLine] {
        let lines = DiffBuilder.buildDiff(oldText: diffSource.oldContent, newText: diffSource.newContent)
        if showOnlyChanges {
            return lines.filter { $0.changeType != .unchanged }
        }
        return lines
    }
    
    private var stats: DiffStats {
        let all = DiffBuilder.buildDiff(oldText: diffSource.oldContent, newText: diffSource.newContent)
        let additions = all.filter { $0.changeType == .addition }.count
        let removals = all.filter { $0.changeType == .removal }.count
        return DiffStats(additions: additions, removals: removals)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            diffToolbar
            Divider().overlay(theme.colors.border)
            
            if diffSource.oldContent == diffSource.newContent {
                noChangesView
            } else {
                diffContent
            }
        }
        .background(theme.colors.panelBackground)
    }
    
    // MARK: - Toolbar
    
    private var diffToolbar: some View {
        HStack(spacing: 10) {
            Image(systemName: diffSource.icon)
                .foregroundColor(theme.colors.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(document.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.colors.text)
                Text(diffSource.label)
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.secondaryText)
            }
            
            Spacer()
            
            // Stats badges
            if stats.additions > 0 {
                statBadge(count: stats.additions, symbol: "+", color: .green)
            }
            if stats.removals > 0 {
                statBadge(count: stats.removals, symbol: "-", color: .red)
            }
            
            // Filter toggle
            Button(action: { showOnlyChanges.toggle() }) {
                HStack(spacing: 4) {
                    Image(systemName: showOnlyChanges ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 12))
                    Text(showOnlyChanges ? "Changes" : "All")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(theme.colors.tertiaryBackground)
                .foregroundColor(showOnlyChanges ? theme.colors.accent : theme.colors.secondaryText)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            // Accept/Reject for agent changes
            if document.agentChange != nil {
                Button(action: { document.acceptAgentChange() }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .padding(6)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(action: { Task { await document.rejectAgentChange() } }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .padding(6)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.colors.headerBackground)
    }
    
    // MARK: - Diff Content
    
    private var diffContent: some View {
        ScrollView([.vertical, .horizontal], showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(diffLines) { line in
                    DiffLineView(line: line)
                }
            }
            .padding(8)
        }
    }
    
    // MARK: - No Changes
    
    private var noChangesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 36))
                .foregroundColor(theme.colors.accent.opacity(0.6))
            Text("No changes detected")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.secondaryText)
            Text("The file content matches the saved version on disk.")
                .font(.system(size: 12))
                .foregroundColor(theme.colors.tertiaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    
    private func statBadge(count: Int, symbol: String, color: Color) -> some View {
        Text("\(symbol)\(count)")
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

// MARK: - Supporting Types

private struct DiffSource {
    let label: String
    let icon: String
    let oldContent: String
    let newContent: String
    let timestamp: Date?
}

private struct DiffStats {
    let additions: Int
    let removals: Int
}
