import SwiftUI
import Combine

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
    @FocusState private var searchFieldFocused: Bool

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
        let isActive = !searchQuery.isEmpty || searchFieldFocused
        return HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(isActive ? theme.colors.accent : theme.colors.tertiaryText)
                .font(.system(size: 12))
            
            TextField("Search files...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(theme.colors.text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($searchFieldFocused)
            
            if !searchQuery.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.colors.tertiaryText)
                        .opacity(0.9)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(theme.colors.tertiaryBackground.opacity(isActive ? 1.0 : 0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isActive ? theme.colors.accent.opacity(0.35) : Color.clear, lineWidth: 1)
                )
        )
        .shadow(color: isActive ? theme.colors.accent.opacity(0.12) : .clear, radius: 8, y: 4)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .animation(.easeInOut(duration: 0.18), value: isActive)
    }
    
    // MARK: - File Tree
    
    private func fileTreeView(rootNode: IDEFileNode) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if let children = rootNode.sortedChildren {
                    let nodes = filteredNodes(children)
                    if nodes.isEmpty && !searchQuery.isEmpty {
                        searchEmptyState
                    } else {
                        ForEach(nodes) { node in
                            FileNodeRow(
                                node: node,
                                depth: 0,
                                searchText: searchQuery,
                                selectedURL: ideState.selectedFileURL,
                                onSelect: { selectedNode in
                                    handleNodeSelection(selectedNode)
                                },
                                onToggle: { toggledNode in
                                    toggledNode.isExpanded.toggle()
                                },
                                onPreview: { previewNode in
                                    handlePreviewSelection(previewNode)
                                },
                                onOpenAs: { node, descriptor in
                                    handleOpenAs(node, descriptor: descriptor)
                                },
                                onSave: { node in
                                    handleSave(node)
                                },
                                onRevert: { node in
                                    handleRevert(node)
                                }
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func filteredNodes(_ nodes: [IDEFileNode]) -> [IDEFileNode] {
        guard !searchQuery.isEmpty else { return nodes }
        return nodes.filter { nodeMatchesSearch($0, searchText: searchQuery) }
    }

    private func nodeMatchesSearch(_ node: IDEFileNode, searchText: String) -> Bool {
        let matchesSelf = node.name.localizedCaseInsensitiveContains(searchText)
        guard let children = node.sortedChildren else {
            return matchesSelf
        }
        let childMatches = children.contains { child in
            nodeMatchesSearch(child, searchText: searchText)
        }
        if childMatches && !node.isExpanded {
            node.isExpanded = true
        }
        return matchesSelf || childMatches
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
    
    private func handleOpenAs(_ node: IDEFileNode, descriptor: ContentPanelDescriptor) {
        guard !node.isDirectory else { return }
        Task {
            await ideState.openFile(node.url)
            // TODO: Open with specific panel descriptor
            // For now, just open the file - panel switching will be handled in future iteration
        }
    }
    
    private func handleSave(_ node: IDEFileNode) {
        guard !node.isDirectory else { return }
        Task {
            _ = await IDEContentStore.shared.save(url: node.url)
        }
    }
    
    private func handleRevert(_ node: IDEFileNode) {
        guard !node.isDirectory else { return }
        Task {
            await IDEContentStore.shared.revert(url: node.url)
        }
    }

    private var searchQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchEmptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(theme.colors.tertiaryText)
            Text("No matches for \"\(searchQuery)\"")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.colors.secondaryText)
            Text("Try another name or clear the search to browse the full tree.")
                .font(.system(size: 11))
                .foregroundColor(theme.colors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
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
    var onOpenAs: ((IDEFileNode, ContentPanelDescriptor) -> Void)?
    var onSave: ((IDEFileNode) -> Void)?
    var onRevert: ((IDEFileNode) -> Void)?
    
    @Environment(\.dockTheme) var theme
    @State private var isHovered: Bool = false
    @State private var dirtyState: Bool = false
    
    private let contentStore = IDEContentStore.shared
    
    private func availablePanels(for node: IDEFileNode) -> [ContentPanelDescriptor] {
        ContentPanelRegistry.shared.availablePanels(for: node.fileType)
    }
    
    private func hasBuffer(for node: IDEFileNode) -> Bool {
        contentStore.hasBuffer(for: node.url)
    }
    
    private func isBufferDirty(for node: IDEFileNode) -> Bool {
        contentStore.buffer(for: node.url)?.isDirty ?? false
    }
    
    private var dirtyPublisher: AnyPublisher<Bool, Never>? {
        guard !node.isDirectory else { return nil }
        return NotificationCenter.default.publisher(for: .contentBufferDirtyStateChanged)
            .compactMap { notification -> Bool? in
                guard let changedURL = notification.userInfo?["url"] as? URL,
                      let isDirty = notification.userInfo?["isDirty"] as? Bool,
                      changedURL == node.url else {
                    return nil
                }
                return isDirty
            }
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
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
                
                // Name with dirty indicator
                HStack(spacing: 4) {
                    highlightedName(for: node.name, searchText: searchText)
                        .font(.system(size: 13))
                        .lineLimit(1)
                    
                    // Dirty indicator
                    if !node.isDirectory && dirtyState {
                        Circle()
                            .fill(theme.colors.accent)
                            .frame(width: 6, height: 6)
                    }
                }
                
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
                    
                    // Open As submenu with available panel types
                    Menu("Open As") {
                        ForEach(availablePanels(for: node)) { descriptor in
                            Button {
                                onOpenAs?(node, descriptor)
                            } label: {
                                Label(descriptor.name, systemImage: descriptor.icon)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Save/Revert actions (only if file has a buffer)
                    if hasBuffer(for: node) {
                        if dirtyState {
                            Button("Save", action: { onSave?(node) })
                            Button("Revert", action: { onRevert?(node) })
                        } else {
                            Button("Save", action: { onSave?(node) })
                                .disabled(true)
                        }
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
                        onPreview: onPreview,
                        onOpenAs: onOpenAs,
                        onSave: onSave,
                        onRevert: onRevert
                    )
                }
            }
        }
        .onAppear {
            dirtyState = isBufferDirty(for: node)
        }
        .onReceive(dirtyPublisher ?? Empty<Bool, Never>().eraseToAnyPublisher()) { isDirty in
            dirtyState = isDirty
        }
    }
}

private extension FileNodeRow {
    func highlightedName(for value: String, searchText: String) -> Text {
        guard !searchText.isEmpty else {
            return Text(value).foregroundColor(theme.colors.text)
        }

        let nsValue = value as NSString
        var cursor = 0
        let length = nsValue.length
        var composed = Text("")
        let highlightColor = theme.colors.accent

        while cursor < length {
            let remainingLength = length - cursor
            let range = NSRange(location: cursor, length: remainingLength)
            let match = nsValue.range(of: searchText, options: [.caseInsensitive], range: range)

            if match.location == NSNotFound {
                let tail = nsValue.substring(with: range)
                composed = composed + Text(tail).foregroundColor(theme.colors.text)
                break
            }

            if match.location > cursor {
                let prefixRange = NSRange(location: cursor, length: match.location - cursor)
                let prefix = nsValue.substring(with: prefixRange)
                composed = composed + Text(prefix).foregroundColor(theme.colors.text)
            }

            let matchString = nsValue.substring(with: match)
            composed = composed + Text(matchString)
                .foregroundColor(highlightColor)
                .fontWeight(.semibold)

            cursor = match.location + match.length
        }

        return composed
    }
}
