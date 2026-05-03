# Teritro Status

`STATUS.md` is dynamic project state, not a changelog. History lives in Git.

## Active Phase

Phase 2 - Implementation

## Active Slice

Slice 8.3.1 - Debug Grid Toggle Authority & AA Stability v0.1

## Implemented (this slice)

Made `G` the user-facing authority for debug-grid visibility. The grid now
stays visible across LOD levels when enabled, remains hidden everywhere when
disabled, and uses pinned antialiasing by default to avoid camera-position
dependent line-weight changes.

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

Slice 8.3.1 changes debug-grid visibility policy, antialiasing defaults, HUD
status, renderer tests, and documentation. Run the headless test suite,
`git diff --check`, and a manual Godot editor check that `G on` shows the grid
at zoom `1.0`, `0.7`, `0.65`, `0.6`, and `0.25`, `G off` hides it everywhere,
line weight remains stable while panning, and far-zoom grid-on cost is
documented honestly.

## State Rule

`STATUS.md` is the single source of truth for current phase and slice.

If `STATUS.md` and `docs/NEXT_STEPS.md` conflict, treat it as a documentation
bug to report or fix. It is not an authority-order question.
