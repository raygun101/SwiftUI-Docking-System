# iOS Docking Panel System

A professional, IDE-quality docking panel system for iOS applications. This system provides flexible, configurable layouts with support for tabbed panels, split views, floating windows, and comprehensive theming.

## Features

- **Flexible Docking Positions**: Left, Right, Top, Bottom, Center, and Floating panels
- **Tabbed Panels**: Multiple panels can be grouped with tab navigation
- **Split Views**: Nested horizontal and vertical splits with resizable dividers
- **Drag & Drop**: Panels can be dragged between positions
- **Floating Windows**: Panels can be detached and floated
- **Collapsible Regions**: Side panels can collapse to icons
- **Resizable Panels**: All panel boundaries are resizable
- **Theming System**: Comprehensive styling with multiple built-in themes
- **State Management**: Full state management with observable objects

## Architecture

```
DockingSystem/
├── Core/
│   ├── DockTypes.swift        # Core types and enums
│   ├── DockPanel.swift        # Panel and PanelGroup models
│   ├── DockLayout.swift       # Layout tree structure
│   └── DockState.swift        # Central state management
├── Layout/
│   ├── DockContainer.swift    # Main container view
│   ├── DockRegionView.swift   # Region rendering
│   ├── DockSplitView.swift    # Split view implementation
│   ├── DockResizeHandle.swift # Resize handles
│   ├── FloatingPanelView.swift # Floating window support
│   └── DockDragDropManager.swift # Drag & drop mechanics
├── Styling/
│   ├── DockTheme.swift        # Theme protocol and implementations
│   └── DockStyles.swift       # Component style protocols
└── DockingSystem.swift        # Public API entry point
```

## Quick Start

### Basic Usage

```swift
import SwiftUI

struct MyApp: View {
    var body: some View {
        let layout = DockLayout()
            .configureLeft {
                DockPanel(id: "explorer", title: "Explorer", icon: "folder") {
                    FileExplorerView()
                }
            }
            .configureCenter {
                DockPanel(id: "editor", title: "Editor", icon: "doc.text") {
                    EditorView()
                }
            }
            .configureBottom(height: 200) {
                DockPanel(id: "console", title: "Console", icon: "terminal") {
                    ConsoleView()
                }
            }
        
        DockingSystem(layout: layout, theme: XcodeDockTheme())
    }
}
```

### Using the Layout Builder

```swift
let layout = DockLayoutBuilder()
    .left([explorerPanel, searchPanel], width: 260)
    .right([inspectorPanel], width: 280)
    .bottom([consolePanel, problemsPanel], height: 200)
    .center([editorPanel])
    .build()
```

### Creating Panels

```swift
let panel = DockPanel(
    id: "my-panel",
    title: "My Panel",
    icon: "star.fill",
    position: .left,
    visibility: .standard,
    constraints: DockSizeConstraint(minWidth: 200, maxWidth: 400)
) {
    MyPanelContent()
}
```

### Panel Visibility Options

```swift
// Standard panel with all controls
.visibility: .standard

// Minimal panel (header and drag only)
.visibility: .minimal

// Custom visibility
.visibility: [.showHeader, .showCloseButton, .allowDrag, .allowResize]
```

## Theming

### Built-in Themes

- `DefaultDockTheme()` - System-adaptive theme
- `DarkDockTheme()` - Dark mode optimized
- `XcodeDockTheme()` - Xcode-inspired styling
- `VSCodeDockTheme()` - VS Code-inspired styling

### Custom Themes

```swift
struct MyCustomTheme: DockThemeProtocol {
    var colors = DockColorScheme(
        background: Color.black,
        panelBackground: Color(white: 0.1),
        accent: Color.purple
        // ... customize all colors
    )
    
    var typography = DockTypography(
        headerFont: .system(size: 14, weight: .bold)
    )
    
    var spacing = DockSpacing(
        headerPadding: 12,
        resizeHandleSize: 8
    )
    
    var borders = DockBorders()
    var shadows = DockShadows()
    var animations = DockAnimations()
    var cornerRadii = DockCornerRadii()
}
```

### Applying Themes

```swift
DockingSystem(layout: layout, theme: MyCustomTheme())

// Or use the modifier
DockContainer(state: state)
    .dockTheme(MyCustomTheme())
```

## State Management

### Accessing State

```swift
@StateObject var dockState = DockState(layout: myLayout)

// Later in your view
DockingSystem(state: dockState, theme: theme)

// Programmatic control
dockState.activatePanel(panel)
dockState.closePanel(panel)
dockState.floatPanel(panel)
dockState.dockPanel(panel, to: .right)
```

### Layout Manipulation

```swift
// Toggle panel collapse
dockState.layout.toggleCollapse(for: .left)

// Resize panels
dockState.layout.leftWidth = 300
dockState.layout.bottomHeight = 250

// Check state
if dockState.layout.isLeftCollapsed {
    // Handle collapsed state
}
```

## Panel Actions

```swift
// Collapse/Expand
panel.collapse()
panel.expand()
panel.toggle()

// Float
panel.float(at: CGRect(x: 100, y: 100, width: 300, height: 400))

// Dock
panel.dock(to: .right)

// Minimize/Maximize
panel.minimize()
panel.maximize()
```

## Advanced Features

### Split Views

```swift
let layout = DockLayoutBuilder()
    .leftSplit(
        [explorerPanel],
        [outlinePanel],
        ratio: 0.6,
        width: 280
    )
    .build()
```

### Nested Splits

```swift
let innerSplit = DockSplitNode(
    orientation: .vertical,
    first: .panel(topGroup),
    second: .panel(bottomGroup),
    splitRatio: 0.5
)

let outerSplit = DockSplitNode(
    orientation: .horizontal,
    first: .panel(leftGroup),
    second: .split(innerSplit),
    splitRatio: 0.3
)

layout.centerNode = .split(outerSplit)
```

### Floating Panels

```swift
// Create floating panel programmatically
let floatingGroup = DockPanelGroup(
    panels: [myPanel],
    position: .floating,
    size: CGSize(width: 400, height: 300)
)
myPanel.floatingFrame = CGRect(x: 100, y: 100, width: 400, height: 300)
dockState.layout.floatingPanels.append(floatingGroup)
```

## Best Practices

1. **Unique Panel IDs**: Always use unique IDs for panels
2. **Reasonable Constraints**: Set min/max sizes to prevent layout issues
3. **State Observation**: Use `@StateObject` for the DockState at your root view
4. **Theme Consistency**: Apply themes at the top level
5. **Lazy Content**: Use lazy loading for panel content when appropriate

## Requirements

- iOS 16.0+
- SwiftUI
- Xcode 15+

## License

MIT License
