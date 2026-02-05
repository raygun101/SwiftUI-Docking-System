# IDE File Display & Preview Refactor Plan
A refactor will introduce an extensible file display framework so project explorer context menus can switch between editors (code, HTML preview, etc.) while ensuring preview panels stay in sync.

## Current Architecture Snapshot
- `IDEEditorRegistry` statically maps file types to editor/preview SwiftUI wrappers, limiting extensibility.
- `IDEPreviewPanel` independently derives previewable documents and always uses the specialized preview view.
- `IDEProjectExplorerPanel` context menu only toggles open/preview actions, lacking a display-mode selector.

## Goals
1. Provide a unified abstraction for "display modes" (editor vs. multiple preview styles) that can be registered per file type.
2. Allow context-menu actions on file nodes to select a display mode (default editor, HTML preview, future custom modes).
3. Keep IDE state (selected document, preview URL, active display mode) synchronized so panels render the chosen experience.

## Proposed Steps
1. **Define Display Mode Model**: Create a protocol/struct describing a display mode (id, name, icon, `ViewBuilder` factory, capability flags). Extend `IDEEditorRegistry` (or new `IDEViewRegistry`) to register/editor+preview modes per file type.
2. **Extend IDE State**: Add state for the active display mode per open document (e.g., `IDEDocumentDisplayPreference`) plus helpers to query available modes.
3. **Update Project Explorer Context Menu**: Replace the current static "Open / Open Preview" actions with a submenu listing available display modes; selecting one sets the document active and updates the preferred mode.
4. **Refactor Editor/Preview Panels**: Consolidate rendering so whichever panel is active reads the selected mode and instantiates the corresponding view (code editor, HTML preview, etc.). Ensure fallbacks exist when a mode becomes unavailable.
5. **HTML Preview Enhancements**: As part of the new mode system, polish the HTML preview panel (refresh controls, zoom) and ensure it can be invoked either from its dedicated panel or via the new display-mode selection.
6. **Extensibility Hooks**: Document and expose APIs for registering new display modes so future components (e.g., design surface, terminal) can plug in without touching core panels.
7. **Testing & Validation**: Exercise scenarios—switching between editor/preview from context menu, maintaining state on file reopen, ensuring `xcodebuild` succeeds.

## Open Questions for Confirmation
- Should display mode preference persist per file, per file type, or only per session?
- Do we need keyboard shortcuts or toolbar buttons to switch modes in addition to the context menu?
- Any additional preview types (Markdown live preview, component gallery) to account for now?
