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
    
    public var body: some View {
        VStack(spacing: 0) {
            documentToolbar
            Divider()
            IDEEditorRegistry.shared.editorView(for: document)
        }
        .background(theme.colors.panelBackground)
    }
    
    private var documentToolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: document.icon)
                    .font(.system(size: 12))
                    .foregroundColor(document.fileType.iconColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(document.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.colors.text)
                    
                    Text(document.fileURL.path)
                        .font(.system(size: 9))
                        .foregroundColor(theme.colors.tertiaryText)
                        .lineLimit(1)
                }
                
                if document.isDirty {
                    Circle()
                        .fill(theme.colors.accent)
                        .frame(width: 6, height: 6)
                }
            }
            
            Spacer()
            
            if let language = document.fileType.language {
                Text(language.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.colors.tertiaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.colors.tertiaryBackground)
                    .cornerRadius(4)
            }
            
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
    
    private func saveDocument() {
        Task {
            await ideState.saveDocument(document)
        }
    }
}
