import SwiftUI

// MARK: - Editor Panel

/// Displays a single document inside a docked panel
public struct IDEEditorPanel: View {
    @ObservedObject var document: IDEDocument
    @EnvironmentObject var ideState: IDEState
    @Environment(\.dockTheme) var theme
    
    public init(document: IDEDocument) {
        self.document = document
    }

// MARK: - Agent Change Controls

private struct AgentChangeActionBar: View {
    let snapshot: AgentChangeSnapshot
    let onAccept: () -> Void
    let onReject: () -> Void
    let onDismiss: () -> Void
    @Environment(\.dockTheme) private var theme
    
    private var timestampText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: snapshot.timestamp)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            infoChip(icon: "arrow.up.circle", text: "Agent edits", detail: timestampText)
            actionButton(title: "Accept", icon: "checkmark", foreground: theme.colors.panelBackground, background: theme.colors.accent, action: onAccept)
            actionButton(title: "Reject", icon: "xmark", foreground: theme.colors.text, background: theme.colors.secondaryBackground, action: onReject)
            iconButton(systemName: "eye.slash", action: onDismiss)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(.clear)
    }
    
    private func infoChip(icon: String, text: String, detail: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.system(size: 11, weight: .semibold))
                Text(detail)
                    .font(.system(size: 10))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(theme.colors.secondaryBackground.opacity(0.85))
        .foregroundColor(theme.colors.text)
        .clipShape(Capsule())
    }
    
    private func actionButton(title: String, icon: String, foreground: Color, background: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 11, weight: .semibold))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(background)
            .foregroundColor(foreground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private func iconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .padding(8)
                .background(theme.colors.secondaryBackground.opacity(0.85))
                .foregroundColor(theme.colors.tertiaryText)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Hide agent diff overlay")
    }
}
    
    public var body: some View {
        VStack(spacing: 0) {
            DockPanelToolbar { documentToolbar }
            IDEEditorRegistry.shared.editorView(for: document)
        }
        .background(theme.colors.panelBackground)
        .overlay(alignment: .bottom) {
            if let snapshot = document.agentChange {
                AgentChangeActionBar(
                    snapshot: snapshot,
                    onAccept: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            document.acceptAgentChange()
                        }
                    },
                    onReject: {
                        Task {
                            await document.rejectAgentChange()
                        }
                    },
                    onDismiss: {
                        withAnimation(.easeInOut) {
                            document.clearAgentChange()
                        }
                    }
                )
                .padding(.bottom, 12)
                .padding(.horizontal, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private var documentToolbar: some View {
        DockToolbarScaffold(leading: {
            DockToolbarChip(icon: document.icon, title: relativeFilePathDisplay)
        }, trailing: {
            if let language = document.fileType.language {
                DockToolbarChip(title: language.uppercased())
            }
            
            DockToolbarIconButton(
                "square.and.arrow.down",
                accessibilityLabel: "Save document",
                role: document.isDirty ? .accent : .normal,
                isActive: document.isDirty
            ) {
                saveDocument()
            }
            .disabled(!document.isDirty)
        })
    }
    
    private var relativeFilePathDisplay: String {
        guard let projectRoot = ideState.workspaceManager.project?.rootURL else {
            return document.fileURL.lastPathComponent
        }
        let documentPath = document.fileURL.path
        let rootPath = projectRoot.path
        if documentPath.hasPrefix(rootPath) {
            var relative = String(documentPath.dropFirst(rootPath.count))
            if relative.hasPrefix("/") {
                relative.removeFirst()
            }
            return relative.isEmpty ? document.fileURL.lastPathComponent : relative
        }
        return document.fileURL.lastPathComponent
    }
    
    private func saveDocument() {
        Task {
            await ideState.saveDocument(document)
        }
    }
}
