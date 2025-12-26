import SwiftUI

// MARK: - Docking System Public API

/// Main entry point for the docking system
public struct DockingSystem<Content: View>: View {
    @StateObject private var state: DockState
    private let theme: any DockThemeProtocol
    private let content: () -> Content
    
    public init(
        layout: DockLayout = DockLayout(),
        theme: any DockThemeProtocol = DefaultDockTheme(),
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        _state = StateObject(wrappedValue: DockState(layout: layout))
        self.theme = theme
        self.content = content
    }
    
    public init(
        state: DockState,
        theme: any DockThemeProtocol = DefaultDockTheme(),
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        _state = StateObject(wrappedValue: state)
        self.theme = theme
        self.content = content
    }
    
    public var body: some View {
        DockContainer(state: state)
            .environmentObject(state)
            .environment(\.dockTheme, theme)
            .overlay(content())
    }
}

// MARK: - Convenience Initializers

extension DockingSystem where Content == EmptyView {
    public init(
        layout: DockLayout,
        theme: any DockThemeProtocol = DefaultDockTheme()
    ) {
        self.init(layout: layout, theme: theme) { EmptyView() }
    }
    
    public init(
        state: DockState,
        theme: any DockThemeProtocol = DefaultDockTheme()
    ) {
        self.init(state: state, theme: theme) { EmptyView() }
    }
}

// MARK: - Panel Builder DSL

@resultBuilder
public struct DockPanelBuilder {
    public static func buildBlock(_ components: DockPanel...) -> [DockPanel] {
        components
    }
    
    public static func buildOptional(_ component: [DockPanel]?) -> [DockPanel] {
        component ?? []
    }
    
    public static func buildEither(first component: [DockPanel]) -> [DockPanel] {
        component
    }
    
    public static func buildEither(second component: [DockPanel]) -> [DockPanel] {
        component
    }
    
    public static func buildArray(_ components: [[DockPanel]]) -> [DockPanel] {
        components.flatMap { $0 }
    }
}

// MARK: - Layout Configuration DSL

public extension DockLayout {
    @discardableResult
    func configureLeft(
        width: CGFloat = 250,
        collapsed: Bool = false,
        @DockPanelBuilder panels: () -> [DockPanel]
    ) -> DockLayout {
        let panelList = panels()
        if !panelList.isEmpty {
            let group = DockPanelGroup(panels: panelList, position: .left)
            leftNode = .panel(group)
        }
        leftWidth = width
        isLeftCollapsed = collapsed
        return self
    }
    
    @discardableResult
    func configureRight(
        width: CGFloat = 250,
        collapsed: Bool = false,
        @DockPanelBuilder panels: () -> [DockPanel]
    ) -> DockLayout {
        let panelList = panels()
        if !panelList.isEmpty {
            let group = DockPanelGroup(panels: panelList, position: .right)
            rightNode = .panel(group)
        }
        rightWidth = width
        isRightCollapsed = collapsed
        return self
    }
    
    @discardableResult
    func configureTop(
        height: CGFloat = 200,
        collapsed: Bool = false,
        @DockPanelBuilder panels: () -> [DockPanel]
    ) -> DockLayout {
        let panelList = panels()
        if !panelList.isEmpty {
            let group = DockPanelGroup(panels: panelList, position: .top)
            topNode = .panel(group)
        }
        topHeight = height
        isTopCollapsed = collapsed
        return self
    }
    
    @discardableResult
    func configureBottom(
        height: CGFloat = 200,
        collapsed: Bool = false,
        @DockPanelBuilder panels: () -> [DockPanel]
    ) -> DockLayout {
        let panelList = panels()
        if !panelList.isEmpty {
            let group = DockPanelGroup(panels: panelList, position: .bottom)
            bottomNode = .panel(group)
        }
        bottomHeight = height
        isBottomCollapsed = collapsed
        return self
    }
    
    @discardableResult
    func configureCenter(
        @DockPanelBuilder panels: () -> [DockPanel]
    ) -> DockLayout {
        let panelList = panels()
        if !panelList.isEmpty {
            let group = DockPanelGroup(panels: panelList, position: .center)
            centerNode = .panel(group)
        }
        return self
    }
}

// MARK: - Quick Panel Creation

public extension DockPanel {
    static func create<Content: View>(
        id: String,
        title: String,
        icon: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> DockPanel {
        DockPanel(
            id: id,
            title: title,
            icon: icon,
            content: content
        )
    }
}
