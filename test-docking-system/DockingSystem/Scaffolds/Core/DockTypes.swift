import SwiftUI

// MARK: - Core Types

/// Unique identifier for dock panels
public typealias DockPanelID = String

/// Position where a panel can be docked
public enum DockPosition: String, CaseIterable, Codable, Hashable {
    case left
    case right
    case top
    case bottom
    case center
    case floating
    
    public var isHorizontalEdge: Bool {
        self == .left || self == .right
    }
    
    public var isVerticalEdge: Bool {
        self == .top || self == .bottom
    }
    
    public var opposite: DockPosition {
        switch self {
        case .left: return .right
        case .right: return .left
        case .top: return .bottom
        case .bottom: return .top
        case .center: return .center
        case .floating: return .floating
        }
    }
}

/// Drop zone indicator for drag operations
public enum DockDropZone: Equatable, Hashable {
    case none
    case position(DockPosition)
    case tab(panelID: DockPanelID, index: Int)
    case split(panelID: DockPanelID, position: DockPosition)
}

/// State of a dock panel
public enum DockPanelState: String, Codable, Hashable {
    case expanded
    case collapsed
    case minimized
    case floating
    case maximized
}

/// Resize direction
public enum ResizeDirection: Hashable {
    case horizontal
    case vertical
    case both
}

/// Split orientation for dock containers
public enum DockSplitOrientation: String, Codable, Hashable {
    case horizontal
    case vertical
}

/// Constraint for panel sizes
public struct DockSizeConstraint: Codable, Hashable {
    public var minWidth: CGFloat?
    public var maxWidth: CGFloat?
    public var minHeight: CGFloat?
    public var maxHeight: CGFloat?
    public var preferredWidth: CGFloat?
    public var preferredHeight: CGFloat?
    
    public static let `default` = DockSizeConstraint(
        minWidth: 100,
        maxWidth: nil,
        minHeight: 50,
        maxHeight: nil,
        preferredWidth: 250,
        preferredHeight: 200
    )
    
    public init(
        minWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        preferredWidth: CGFloat? = nil,
        preferredHeight: CGFloat? = nil
    ) {
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.preferredWidth = preferredWidth
        self.preferredHeight = preferredHeight
    }
}

/// Panel visibility options
public struct DockPanelVisibility: OptionSet, Codable, Hashable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let showHeader = DockPanelVisibility(rawValue: 1 << 0)
    public static let showCloseButton = DockPanelVisibility(rawValue: 1 << 1)
    public static let showMinimizeButton = DockPanelVisibility(rawValue: 1 << 2)
    public static let showMaximizeButton = DockPanelVisibility(rawValue: 1 << 3)
    public static let showCollapseButton = DockPanelVisibility(rawValue: 1 << 4)
    public static let allowDrag = DockPanelVisibility(rawValue: 1 << 5)
    public static let allowResize = DockPanelVisibility(rawValue: 1 << 6)
    public static let allowFloat = DockPanelVisibility(rawValue: 1 << 7)
    public static let allowClose = DockPanelVisibility(rawValue: 1 << 8)
    public static let allowTabbing = DockPanelVisibility(rawValue: 1 << 9)
    
    public static let all: DockPanelVisibility = [
        .showHeader, .showCloseButton, .showMinimizeButton,
        .showMaximizeButton, .showCollapseButton, .allowDrag,
        .allowResize, .allowFloat, .allowClose, .allowTabbing
    ]
    
    public static let standard: DockPanelVisibility = [
        .showHeader, .showCloseButton, .showCollapseButton,
        .allowDrag, .allowResize, .allowTabbing, .allowFloat
    ]
    
    public static let minimal: DockPanelVisibility = [
        .showHeader, .allowDrag, .allowFloat
    ]
}
