# Teritro Status

`STATUS.md` is dynamic project state, not a changelog. History lives in Git.

## Active Phase

Phase 2 - Implementation

## Active Slice

Slice 7 - Event-Local Enclosure Fill Prototype v0.1

## Implemented (this slice)

Added event-local enclosure-fill for the first one-colony prototype. After a
real placement, the simulation can fill fully enclosed empty regions adjacent to
that placed cell while leaving open, edge-connected, or contested regions
unfilled. Added enclosure debug metrics, tests, and documentation.

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
- Renderer replacement through MultiMesh, TileMapLayer, shaders, or chunks.
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
- New external assets or addons.
- Renderer replacement through MultiMesh, TileMapLayer, shaders, or chunks.
- New documentation layout or plan-rules split.
- Hooks, automations, feature branches, pushes, PRs.

## Validation

Slice 7 changes runtime simulation behavior, HUD-visible debug metrics, tests,
and documentation. Run the headless test suite, `git diff --check`, and a
manual Godot editor check that closed regions fill, open regions stay empty,
HUD enclosure metrics update, and `R` reset still works.

## State Rule

`STATUS.md` is the single source of truth for current phase and slice.

If `STATUS.md` and `docs/NEXT_STEPS.md` conflict, treat it as a documentation
bug to report or fix. It is not an authority-order question.
