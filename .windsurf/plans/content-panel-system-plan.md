# Unified Content Panel & Editing System Plan
We will introduce a shared "content panel" abstraction that manages in-memory document state so editors and viewers all render the same live content, expose consistent UI affordances, and support multiple simultaneous displays per file.

## Objectives
1. **Content Authority**: Create a content management service (e.g., `IDEContentStore`) that tracks file versions (disk + in-memory changes), diffs, dirty flags, and exposes async APIs for readers/writers (editors, previews, agents).
2. **Panel Abstraction**: Define a `ContentPanel` protocol/base view that subscribes to the content store, exposes metadata (mode id, icon, capabilities), and can represent either editable or read-only experiences.
3. **Multi-Panel Support**: Allow multiple panels (even of same type) per document, keeping scroll/selection state panel-local but binding all to shared content.
4. **Extensible Display Modes**: Register panel types per file type (code editor, HTML preview, Markdown preview, diff view) so explorer context menus and tab UI can instantiate the desired mode.
5. **State Persistence & Indicators**: Persist per-document panel selections, show dirty indicators in tabs/file tree, and expose save/revert actions (including old-version references for diffing).
6. **Agent Compatibility**: Ensure background agents can edit content through the store without requiring UI panels to be open, and push updates to any listening panels when changes occur.

## Proposed Workstream
1. **Content Store Layer**
   - Implement `IDEContentStore` managing `ContentBuffer` objects keyed by file URL.
   - Track disk snapshot, in-memory edits, dirty flag, last editor, and provide publishers for content/metadata changes.
   - Offer APIs: `load(url)`, `update(url, mutation)`, `save(url)`, `revert(url)`, plus diff helpers returning old/new text.
2. **Document/State Integration**
   - Update `IDEProject`/`IDEDocument` model to delegate content to the store (documents primarily reference metadata and panel state).
   - Ensure closing an editor does not drop the buffer; buffers live until explicitly released/saved.
3. **Content Panel Protocol**
   - Define `ContentPanelDescriptor` (id, name, icon, isEditable) and `ContentPanel` view protocol receiving a `ContentBuffer` binding plus panel-specific state.
   - Provide base SwiftUI struct handling subscriptions, save indicators, and context menu hooks.
4. **Mode Registration & Discovery**
   - Replace/extend `IDEEditorRegistry` with a registry where file types declare available panel descriptors + factories (code editor, HTML preview, etc.).
   - Explorer context menus and tab toolbars query this registry to show "Open As" / "Switch View" options.
5. **Explorer & Tab UX Updates**
   - Context menu: show submenu of available panels; selecting one opens/activates that panel for the file.
   - Tabs: display dirty dot, panel name badge, and offer quick toggle if multiple panels of same file are open.
   - File tree: show modified indicator + actions (Save, Revert) wired to `IDEContentStore`.
6. **Preview Panel Alignment**
   - Refactor `IDEPreviewPanel` to be just another content panel (HTML preview descriptor) so it shares the same refresh/zoom UI but relies on store updates.
7. **Agent & Background Operations**
   - Adapt agent file-edit tooling to call into `IDEContentStore` (not direct file writes) for seamless sync with open panels.
   - Ensure save pipeline flushes in-memory edits to disk before external commands (e.g., build) rely on files.
8. **Testing & Validation**
   - Scenarios: multiple panels per file; editing with preview open; agent editing closed file; save/revert; dirty indicators in tree/tabs; xcodebuild.

## Outstanding Questions
- Persistence scope for panel selections (per session vs. project config)?
- Should content store support binary assets or remain text-first initially?
- Any required APIs for external plugins to register new panel types at runtime?
