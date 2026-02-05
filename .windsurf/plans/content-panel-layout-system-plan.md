# Content Panel, Agent Access & Layout System Plan
We will architect a unified content system that keeps in-memory edits authoritative, exposes configurable panels/layouts, and ensures agents and UI panels all stay in sync.

## Pillars
1. **Content Authority**: Central `IDEContentStore` (buffers, dirty tracking, historical snapshot) serves both UI panels and background agents with the same up-to-date text.
2. **Panel Abstraction**: `ContentPanelDescriptor` + `ContentPanel` protocol defines metadata, capabilities, and view builders (editable or read-only) all backed by store bindings.
3. **Layout Profiles**: Persistable "workspace layouts" describing which panels are open, their docking positions, and active files; users switch layouts via the bottom-right desktop switcher.
4. **Agent Integration**: Agents read/write through `IDEContentStore` so changes propagate to panels even when no editor is open; saves flush buffers to disk before builds or external commands.
5. **Indicators & Commands**: File explorer and tabs subscribe to store metadata to show dirty indicators, diff availability, and offer Save/Revert actions.

## Work Breakdown
1. **Content Store Foundation**
   - Implement `IDEContentStore` with APIs `load`, `acquireBuffer`, `update`, `save`, `revert`, `release`.
   - Buffers maintain disk snapshot, in-memory string, dirty flag, last modification source, and Combine publishers.
   - Provide diff helpers and metadata snapshots for UI badges.
2. **Document/Agent Integration**
   - Refactor `IDEProject` `openDocument`/`closeDocument` to acquire/release buffers instead of directly loading/saving files.
   - Update agent tooling (file edit, MCP operations) to route through the store, allowing edits on unopened files.
   - Ensure save pipeline writes store content to disk atomically and updates buffer snapshots.
3. **Content Panel Protocol**
   - Define `ContentPanelContext` (buffer reference, document metadata, panel instance id, layout position).
   - Provide base SwiftUI component handling binding to buffer text, responding to save/revert events, and exposing optional editing affordances.
   - Standardize built-in panels: Code Editor, HTML Preview, Markdown Preview, Diff Viewer, Raw Viewer, etc.
4. **Panel Registry & Context Menu**
   - Replace `IDEEditorRegistry` with `ContentPanelRegistry` mapping file types to available panel descriptors.
   - Explorer context menu: "Open As" submenu listing descriptors, plus quick actions (Open Default, Preview, Diff, Save, Revert).
   - Editors/tabs display panel badge and allow switching across available modes without closing the tab.
5. **Layout Profiles & Switching**
   - Introduce `IDELatticeLayout` model describing panel arrangements (docked regions, split ratios, floating panels).
   - Persist multiple named layouts (e.g., "Coding", "Preview", "Debug"), storing open panels + targeted files.
   - Update the bottom-right "desktop switcher" to swap entire layout profiles rather than collapsing panels.
   - Panels must respond to layout switches by mounting/unmounting gracefully while leaving buffers intact.
6. **State Persistence & Indicators**
   - Store per-file last-used panel descriptor and reopen accordingly.
   - File tree + tabs subscribe to dirty state to render indicators; provide context actions for Save/Revert even if no panel is open.
   - Ensure panel tabs show when multiple instances of the same file are open (e.g., "index.html • Preview").
7. **Testing & Validation**
   - Scenarios: multi-panel per file, layout switching, agent editing closed files, saving & reverting from tree, html preview staying in sync, xcodebuild.

## Open Questions
- Should layout profiles sync per project or globally across projects? 
Answer: Per project
- Do we need plugin hooks to provide custom layout templates or panels?
Answer: not sure, we can it it's not too much trouble, but I don't think we need it for now
- How should binary files be represented (pass-through read-only vs. hex viewer)?
Answer: Well, we also need to be able to edit images and audio files, so I think we should just allow editing/modification of binary files, just for now there's no viewer for them.
