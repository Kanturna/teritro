# Teritro Status

`STATUS.md` is dynamic project state, not a changelog. History lives in Git.

## Active Phase

Phase 2 - Implementation

## Active Slice

Slice 8 - Batched Territory Rendering & Grid Guard v0.1

## Implemented (this slice)

Moved owned-cell rendering from per-cell `_draw()` polygons to a single
`MultiMeshInstance2D` batch helper inside `HexMapRenderer`. Added a full-grid
candidate cap so large full-grid debug views are suppressed before excessive
line-building work starts.

`Implemented (this slice)` contains only the active slice. When the slice
changes, remove old slice contents instead of growing this file into history.

## Not Implemented

- Final multi-colony contested enclosure semantics.
- Multi-colony spawn, simultaneous expansion, border conflict, and ownership
  conflict resolution.
- AI, units, combat, economy, balancing, and beauty/shader polish.
- AI-facing `get_legal_actions()` / `apply_action()` surface.
- Incremental frontier-set maintenance.
- Persistent enclosure caches or nested-enclosure policy.
- TileMapLayer, shader, chunk renderer, or beauty-layer work.
- Known-open enclosure cache, stricter enclosure trigger, or full grid LOD
  refactor beyond the Slice 8 candidate cap.
- Renderer-specific rules documentation.
- New documentation layout or plan-rules split.
- Hooks, automations, feature branches, pushes, or PRs.

## Out of Scope

- AI, combat, economy, units, and final balancing rules.
- Final multi-colony contested enclosure semantics.
- Multi-colony conflict resolution and simultaneous placement rules.
- AI action APIs and policy decisions.
- Persistent frontier sets or map-radius stress work.
- Persistent enclosure caches or nested-enclosure behavior.
- Grid shader, beauty-layer, TileMapLayer, or chunk renderer work.
- Known-open enclosure cache, stricter enclosure trigger, or grid LOD policy
  beyond the Slice 8 candidate cap.
- New external assets or addons.
- New documentation layout or plan-rules split.
- Hooks, automations, feature branches, pushes, PRs.

## Validation

Slice 8 changes renderer batching, grid-cap behavior, HUD-visible renderer
metrics, tests, and documentation. Run the headless test suite,
`git diff --check`, and a manual Godot editor check that territory remains
visible under the grid and grid-off pan/zoom stays stable with 500+ owned cells.

## State Rule

`STATUS.md` is the single source of truth for current phase and slice.

If `STATUS.md` and `docs/NEXT_STEPS.md` conflict, treat it as a documentation
bug to report or fix. It is not an authority-order question.
