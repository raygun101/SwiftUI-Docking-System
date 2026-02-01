import SwiftUI

struct AgentDiffView: View {
    let snapshot: AgentChangeSnapshot
    @Binding var isCollapsed: Bool
    let onDismiss: () -> Void
    
    private var diffLines: [DiffLine] {
        DiffBuilder.buildDiff(oldText: snapshot.oldContent, newText: snapshot.newContent)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            if !isCollapsed {
                Divider()
                diffBody
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
    
    private var header: some View {
        HStack {
            Label("Agent updated this file", systemImage: "wand.and.stars")
                .font(.system(size: 13, weight: .medium))
            Spacer()
            Text(snapshot.timestamp, style: .time)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Button(action: { isCollapsed.toggle() }) {
                Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .padding(.leading, 6)
            Button("Dismiss", action: onDismiss)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(12)
    }
    
    private var diffBody: some View {
        ScrollView([.vertical, .horizontal], showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(diffLines) { line in
                    DiffLineView(line: line)
                }
            }
            .padding(8)
            .background(Color(.systemBackground))
        }
        .frame(maxHeight: 250)
    }
}

private struct DiffLineView: View {
    let line: DiffLine
    
    private var backgroundColor: Color {
        switch line.changeType {
        case .unchanged: return Color.clear
        case .addition: return Color.green.opacity(0.15)
        case .removal: return Color.red.opacity(0.15)
        }
    }
    
    private var prefixSymbol: String {
        switch line.changeType {
        case .unchanged: return " "
        case .addition: return "+"
        case .removal: return "-"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(line.oldLineNumber.map(String.init) ?? "")
                .font(.system(.caption, design: .monospaced))
                .frame(width: 40, alignment: .trailing)
                .foregroundColor(.secondary)
            Text(line.newLineNumber.map(String.init) ?? "")
                .font(.system(.caption, design: .monospaced))
                .frame(width: 40, alignment: .trailing)
                .foregroundColor(.secondary)
            Text(prefixSymbol)
                .font(.system(.body, design: .monospaced))
                .frame(width: 14, alignment: .leading)
                .foregroundColor(prefixColor)
            Text(line.content)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(backgroundColor)
    }
    
    private var prefixColor: Color {
        switch line.changeType {
        case .unchanged: return .secondary
        case .addition: return .green
        case .removal: return .red
        }
    }
}

private struct DiffLine: Identifiable {
    enum ChangeType {
        case unchanged
        case addition
        case removal
    }
    
    let id = UUID()
    let changeType: ChangeType
    let oldLineNumber: Int?
    let newLineNumber: Int?
    let content: String
}

private enum DiffBuilder {
    static func buildDiff(oldText: String, newText: String) -> [DiffLine] {
        let oldLines = oldText.components(separatedBy: "\n")
        let newLines = newText.components(separatedBy: "\n")
        let lcsTable = buildLCSTable(oldLines: oldLines, newLines: newLines)
        var lines: [DiffLine] = []
        var i = 0
        var j = 0
        var oldLineNumber = 1
        var newLineNumber = 1
        while i < oldLines.count || j < newLines.count {
            if i < oldLines.count, j < newLines.count, oldLines[i] == newLines[j] {
                lines.append(DiffLine(changeType: .unchanged, oldLineNumber: oldLineNumber, newLineNumber: newLineNumber, content: oldLines[i]))
                i += 1
                j += 1
                oldLineNumber += 1
                newLineNumber += 1
            } else if j < newLines.count, (i == oldLines.count || lcsTable[i][j + 1] >= lcsTable[i + 1][j]) {
                lines.append(DiffLine(changeType: .addition, oldLineNumber: nil, newLineNumber: newLineNumber, content: newLines[j]))
                j += 1
                newLineNumber += 1
            } else if i < oldLines.count {
                lines.append(DiffLine(changeType: .removal, oldLineNumber: oldLineNumber, newLineNumber: nil, content: oldLines[i]))
                i += 1
                oldLineNumber += 1
            }
        }
        return lines
    }
    
    private static func buildLCSTable(oldLines: [String], newLines: [String]) -> [[Int]] {
        let m = oldLines.count
        let n = newLines.count
        var table = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        if m == 0 || n == 0 {
            return table
        }
        for i in stride(from: m - 1, through: 0, by: -1) {
            for j in stride(from: n - 1, through: 0, by: -1) {
                if oldLines[i] == newLines[j] {
                    table[i][j] = table[i + 1][j + 1] + 1
                } else {
                    table[i][j] = max(table[i + 1][j], table[i][j + 1])
                }
            }
        }
        return table
    }
}
