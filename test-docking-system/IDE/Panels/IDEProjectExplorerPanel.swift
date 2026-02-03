import SwiftUI

// MARK: - Project Explorer Panel

/// File hierarchy explorer panel for the IDE
public struct IDEProjectExplorerPanel: View {
    @ObservedObject var project: IDEProject
    @EnvironmentObject var ideState: IDEState
    @Environment(\.dockTheme) var theme
    
    @State private var searchText: String = ""
    @State private var showNewFileSheet: Bool = false
    @State private var showNewFolderSheet: Bool = false
    @State private var selectedNodeForAction: IDEFileNode?
    
    public init(project: IDEProject) {
        self.project = project
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            DockPanelToolbar { explorerToolbar }

            // Search bar
            searchBar
            
            // File tree
            if project.isLoading {
                loadingView
            } else if let rootNode = project.rootNode {
                fileTreeView(rootNode: rootNode)
            } else {
                emptyView
            }
        }
        .background(theme.colors.panelBackground)
    }
    
    // MARK: - Toolbar
    
    private var explorerToolbar: some View {
        DockToolbarScaffold(leading: {
            DockToolbarChip(icon: "folder", title: project.name)
        }, trailing: {
            DockToolbarIconButton("doc.badge.plus", accessibilityLabel: "Create file", role: .accent) {
                showNewFileSheet = true
            }
            
            DockToolbarIconButton("folder.badge.plus", accessibilityLabel: "Create folder", role: .accent) {
                showNewFolderSheet = true
            }
            
            DockToolbarIconButton("arrow.clockwise", accessibilityLabel: "Refresh project") {
                refreshProject()
            }
        })
    }
    
    // MARK: - Search
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.colors.tertiaryText)
                .font(.system(size: 12))
            
            TextField("Search files...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(8)
        .background(theme.colors.tertiaryBackground)
        .cornerRadius(6)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
    
    // MARK: - File Tree
    
    private func fileTreeView(rootNode: IDEFileNode) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if let children = rootNode.sortedChildren {
                    ForEach(filteredNodes(children)) { node in
                        FileNodeRow(
                            node: node,
                            depth: 0,
                            searchText: searchText,
                            selectedURL: ideState.selectedFileURL,
                            onSelect: { selectedNode in
                                handleNodeSelection(selectedNode)
                            },
                            onToggle: { toggledNode in
                                toggledNode.isExpanded.toggle()
                            },
                            onPreview: { previewNode in
                                handlePreviewSelection(previewNode)
                            }
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func filteredNodes(_ nodes: [IDEFileNode]) -> [IDEFileNode] {
        if searchText.isEmpty {
            return nodes
        }
        return nodes.filter { node in
            node.name.localizedCaseInsensitiveContains(searchText) ||
            (node.children?.contains { $0.name.localizedCaseInsensitiveContains(searchText) } ?? false)
        }
    }
    
    // MARK: - States
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading project...")
                .font(.system(size: 13))
                .foregroundColor(theme.colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.system(size: 32))
                .foregroundColor(theme.colors.tertiaryText)
            Text("No files found")
                .font(.system(size: 13))
                .foregroundColor(theme.colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func handleNodeSelection(_ node: IDEFileNode) {
        if !node.isDirectory {
            Task {
                await ideState.openFile(node.url)
            }
        }
    }

    private func handlePreviewSelection(_ node: IDEFileNode) {
        guard !node.isDirectory else { return }
        Task {
            await ideState.openFile(node.url)
            await MainActor.run {
                ideState.previewURL = node.url
            }
        }
    }
    
    private func refreshProject() {
        Task {
            await ideState.refreshProject()
        }
    }
}

// MARK: - File Node Row

struct FileNodeRow: View {
    @ObservedObject var node: IDEFileNode
    let depth: Int
    let searchText: String
    let selectedURL: URL?
    let onSelect: (IDEFileNode) -> Void
    let onToggle: (IDEFileNode) -> Void
    let onPreview: (IDEFileNode) -> Void
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered: Bool = false
    
    var body: some View {
        let isSelected = selectedURL == node.url
        let rowBackground: Color = {
            if isSelected {
                return theme.colors.activeTabBackground.opacity(0.85)
            }
            if isHovered {
                return theme.colors.hoverBackground
            }
            return Color.clear
        }()
        
        VStack(alignment: .leading, spacing: 0) {
            // Node row
            HStack(spacing: 6) {
                // Expand/collapse arrow for directories
                if node.isDirectory {
                    Button(action: { onToggle(node) }) {
                        Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(theme.colors.tertiaryText)
                            .frame(width: 12)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer().frame(width: 12)
                }
                
                // Icon
                Image(systemName: node.icon)
                    .font(.system(size: 14))
                    .foregroundColor(node.iconColor)
                    .frame(width: 18)
                
                // Name
                Text(node.name)
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.text)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.leading, CGFloat(depth * 16) + 8)
            .padding(.trailing, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(rowBackground)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if node.isDirectory {
                    onToggle(node)
                } else {
                    onSelect(node)
                }
            }
            .onHover { hovering in
                isHovered = hovering
            }
            .contextMenu {
                if node.isDirectory {
                    Button("Open", action: { onToggle(node) })
                } else {
                    Button("Open", action: { onSelect(node) })
                    if node.fileType.canPreview {
                        Button("Open Preview", action: { onPreview(node) })
                    }
                }
            }
            
            // Children (if expanded)
            if node.isDirectory && node.isExpanded, let children = node.sortedChildren {
                ForEach(children) { child in
                    FileNodeRow(
                        node: child,
                        depth: depth + 1,
                        searchText: searchText,
                        selectedURL: selectedURL,
                        onSelect: onSelect,
                        onToggle: onToggle,
                        onPreview: onPreview
                    )
                }
            }
        }
    }
}
