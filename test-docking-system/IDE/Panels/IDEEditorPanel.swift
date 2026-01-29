import SwiftUI

// MARK: - Editor Panel

/// Main code/document editor panel for the IDE
public struct IDEEditorPanel: View {
    @ObservedObject var project: IDEProject
    @EnvironmentObject var ideState: IDEState
    @Environment(\.dockTheme) var theme
    
    public init(project: IDEProject) {
        self.project = project
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Tab bar for open documents
            if !project.openDocuments.isEmpty {
                documentTabBar
                Divider()
            }
            
            // Editor content
            editorContent
        }
        .background(theme.colors.panelBackground)
    }
    
    // MARK: - Tab Bar
    
    private var documentTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(project.openDocuments) { document in
                    DocumentTab(
                        document: document,
                        isActive: document.id == project.activeDocument?.id,
                        onSelect: {
                            project.activeDocument = document
                        },
                        onClose: {
                            project.closeDocument(document)
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 36)
        .background(theme.colors.headerBackground)
    }
    
    // MARK: - Editor Content
    
    @ViewBuilder
    private var editorContent: some View {
        if let document = project.activeDocument {
            VStack(spacing: 0) {
                // Document toolbar
                documentToolbar(for: document)
                
                Divider()
                
                // Editor view
                IDEEditorRegistry.shared.editorView(for: document)
            }
        } else {
            emptyEditorView
        }
    }
    
    private func documentToolbar(for document: IDEDocument) -> some View {
        HStack(spacing: 12) {
            // File info
            HStack(spacing: 6) {
                Image(systemName: document.icon)
                    .font(.system(size: 12))
                    .foregroundColor(document.fileType.iconColor)
                
                Text(document.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.colors.text)
                
                if document.isDirty {
                    Circle()
                        .fill(theme.colors.accent)
                        .frame(width: 6, height: 6)
                }
            }
            
            Spacer()
            
            // Language indicator
            if let language = document.fileType.language {
                Text(language.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.colors.tertiaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.colors.tertiaryBackground)
                    .cornerRadius(4)
            }
            
            // Save button
            Button(action: saveDocument) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundColor(document.isDirty ? theme.colors.accent : theme.colors.tertiaryText)
            .disabled(!document.isDirty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(theme.colors.secondaryBackground)
    }
    
    private var emptyEditorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.tertiaryText)
            
            Text("No file open")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(theme.colors.secondaryText)
            
            Text("Select a file from the explorer to edit")
                .font(.system(size: 13))
                .foregroundColor(theme.colors.tertiaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func saveDocument() {
        Task {
            await ideState.saveCurrentDocument()
        }
    }
}

// MARK: - Document Tab

struct DocumentTab: View {
    @ObservedObject var document: IDEDocument
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: document.icon)
                .font(.system(size: 11))
                .foregroundColor(document.fileType.iconColor)
            
            Text(document.name)
                .font(.system(size: 12))
                .foregroundColor(isActive ? theme.colors.text : theme.colors.secondaryText)
                .lineLimit(1)
            
            if document.isDirty {
                Circle()
                    .fill(theme.colors.accent)
                    .frame(width: 5, height: 5)
            }
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(theme.colors.tertiaryText)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? theme.colors.activeTabBackground : (isHovered ? theme.colors.hoverBackground : Color.clear))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
