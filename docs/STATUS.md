# Teritro Status

`STATUS.md` is dynamic project state, not a changelog. History lives in Git.

## Active Phase

Phase 2 - Implementation

## Active Slice

Slice 8.3 - Chunked Debug Grid Renderer & Terrain Boundary v0.1

## Implemented (this slice)

Replaced the Full-Grid candidate-cap workaround with a chunked debug-grid line
cache. The grid now builds line geometry when map geometry changes, draws
visible chunks during Full-LOD camera movement, and reports chunk/cache metrics
instead of candidate-cap metrics.

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
- TileMapLayer, shader, terrain renderer, or beauty-layer work.
- Known-open enclosure cache, stricter enclosure trigger, or production terrain
  rendering.
- Shader-, TileMap-, chunk-, or terrain-visual renderer work.
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
- Grid shader, beauty-layer, TileMapLayer, terrain visuals, or production
  terrain renderer work.
- Known-open enclosure cache or stricter enclosure trigger.
- New external assets or addons.
- New documentation layout or plan-rules split.
- Hooks, automations, feature branches, pushes, PRs.

## Validation

Slice 8.3 changes debug-grid caching, HUD metrics, renderer tests, and
documentation. Run the headless test suite, `git diff --check`, and a manual
Godot editor check that grid-on pan stays stable at zoom `1.0`, grid visibility
is position-independent at zoom `0.7`, zoom `0.65` hides the grid by LOD, and
grid-off territory performance remains stable.

## State Rule

`STATUS.md` is the single source of truth for current phase and slice.

If `STATUS.md` and `docs/NEXT_STEPS.md` conflict, treat it as a documentation
bug to report or fix. It is not an authority-order question.
