import SwiftUI

// MARK: - View Extensions

extension View {
    /// Wraps content in a dock panel
    public func asDockPanel(
        id: String,
        title: String,
        icon: String? = nil,
        position: DockPosition = .center,
        visibility: DockPanelVisibility = .standard
    ) -> DockPanel {
        DockPanel(
            id: id,
            title: title,
            icon: icon,
            position: position,
            visibility: visibility
        ) {
            self
        }
    }
}

// MARK: - CGRect Extensions

extension CGRect {
    /// Creates a rect centered in a container
    static func centered(in container: CGSize, size: CGSize) -> CGRect {
        CGRect(
            x: (container.width - size.width) / 2,
            y: (container.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }
    
    /// Constrains rect within bounds
    func constrained(to bounds: CGRect, minSize: CGSize = CGSize(width: 100, height: 100)) -> CGRect {
        var result = self
        
        // Ensure minimum size
        result.size.width = max(result.size.width, minSize.width)
        result.size.height = max(result.size.height, minSize.height)
        
        // Constrain position
        result.origin.x = max(bounds.minX, min(bounds.maxX - result.width, result.origin.x))
        result.origin.y = max(bounds.minY, min(bounds.maxY - result.height, result.origin.y))
        
        return result
    }
}

// MARK: - Color Extensions

extension Color {
    /// Adjusts color brightness
    func adjusted(brightness: Double) -> Color {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightnessComponent: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(self).getHue(&hue, saturation: &saturation, brightness: &brightnessComponent, alpha: &alpha)
        
        return Color(hue: Double(hue),
                     saturation: Double(saturation),
                     brightness: Double(brightnessComponent) * brightness,
                     opacity: Double(alpha))
    }
}

// MARK: - Animation Helpers

extension Animation {
    /// Standard dock animation
    static var dockDefault: Animation {
        .spring(response: 0.3, dampingFraction: 0.8)
    }
    
    /// Quick dock animation
    static var dockQuick: Animation {
        .easeInOut(duration: 0.15)
    }
    
    /// Smooth dock animation
    static var dockSmooth: Animation {
        .easeInOut(duration: 0.25)
    }
}

// MARK: - Keyboard Shortcuts

#if os(iOS)
extension View {
    /// Adds keyboard shortcuts for dock operations
    @ViewBuilder
    func dockKeyboardShortcuts(state: DockState) -> some View {
        self
            .onKeyPress(.escape) {
                state.cancelDrag()
                return .handled
            }
    }
}
#endif

// MARK: - Gesture Helpers

struct DockPanGesture: Gesture {
    let minimumDistance: CGFloat
    let onStart: () -> Void
    let onUpdate: (CGPoint, CGSize) -> Void
    let onEnd: (CGPoint, CGSize) -> Void
    
    init(
        minimumDistance: CGFloat = 10,
        onStart: @escaping () -> Void = {},
        onUpdate: @escaping (CGPoint, CGSize) -> Void,
        onEnd: @escaping (CGPoint, CGSize) -> Void
    ) {
        self.minimumDistance = minimumDistance
        self.onStart = onStart
        self.onUpdate = onUpdate
        self.onEnd = onEnd
    }
    
    var body: some Gesture {
        DragGesture(minimumDistance: minimumDistance)
            .onChanged { value in
                onUpdate(value.location, value.translation)
            }
            .onEnded { value in
                onEnd(value.location, value.translation)
            }
    }
}

// MARK: - Size Helpers

extension CGSize {
    /// Constrains size within min/max bounds
    func constrained(min minSize: CGSize? = nil, max maxSize: CGSize? = nil) -> CGSize {
        var result = self
        
        if let minSize = minSize {
            result.width = Swift.max(result.width, minSize.width)
            result.height = Swift.max(result.height, minSize.height)
        }
        
        if let maxSize = maxSize {
            result.width = Swift.min(result.width, maxSize.width)
            result.height = Swift.min(result.height, maxSize.height)
        }
        
        return result
    }
}

// MARK: - Conditional Modifier

extension View {
    /// Applies a modifier conditionally
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Applies a modifier if value is non-nil
    @ViewBuilder
    func ifLet<Value, Transform: View>(_ value: Value?, transform: (Self, Value) -> Transform) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension DockLayout {
    /// Prints the current layout structure for debugging
    func debugPrint() {
        print("=== Dock Layout Debug ===")
        print("Left (\(leftWidth)px, collapsed: \(isLeftCollapsed)):")
        debugPrintNode(leftNode, indent: 2)
        print("Right (\(rightWidth)px, collapsed: \(isRightCollapsed)):")
        debugPrintNode(rightNode, indent: 2)
        print("Top (\(topHeight)px, collapsed: \(isTopCollapsed)):")
        debugPrintNode(topNode, indent: 2)
        print("Bottom (\(bottomHeight)px, collapsed: \(isBottomCollapsed)):")
        debugPrintNode(bottomNode, indent: 2)
        print("Center:")
        debugPrintNode(centerNode, indent: 2)
        print("Floating panels: \(floatingPanels.count)")
        print("=========================")
    }
    
    private func debugPrintNode(_ node: DockLayoutNode, indent: Int) {
        let prefix = String(repeating: " ", count: indent)
        switch node {
        case .empty:
            print("\(prefix)- empty")
        case .panel(let group):
            print("\(prefix)- group[\(group.id)]: \(group.panels.map { $0.title }.joined(separator: ", "))")
        case .split(let split):
            print("\(prefix)- split[\(split.orientation), ratio: \(split.splitRatio)]:")
            debugPrintNode(split.first, indent: indent + 2)
            debugPrintNode(split.second, indent: indent + 2)
        }
    }
}
#endif

// MARK: - Accessibility

extension DockPanel {
    var accessibilityLabel: String {
        "\(title) panel"
    }
    
    var accessibilityHint: String {
        switch state {
        case .expanded:
            return "Double tap to collapse"
        case .collapsed:
            return "Double tap to expand"
        case .floating:
            return "Floating panel. Drag to move."
        case .minimized:
            return "Minimized. Double tap to restore."
        case .maximized:
            return "Maximized. Double tap to restore."
        }
    }
}
