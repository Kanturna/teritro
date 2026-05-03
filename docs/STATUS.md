# Teritro Status

`STATUS.md` is dynamic project state, not a changelog. History lives in Git.

## Active Phase

Phase 2 - Implementation

## Active Slice

Slice 6 - Stall Resolution via Frontier Re-Anchoring v0.1

## Implemented (this slice)

Added stall-only frontier re-anchoring for the first colony prototype. When a
local dead end is reached, the simulation scans only owned cells, chooses the
nearest frontier anchor deterministically, resets placement direction, and
continues in the same sim step. Added re-anchor debug metrics, tests, and
documentation.

`Implemented (this slice)` contains only the active slice. When the slice
changes, remove old slice contents instead of growing this file into history.

## Not Implemented

- Enclosure-fill and contested-border semantics.
- Multi-colony spawn, simultaneous expansion, border conflict, and ownership
  conflict resolution.
- AI, units, combat, economy, balancing, and beauty/shader polish.
- AI-facing `get_legal_actions()` / `apply_action()` surface.
- Incremental frontier-set maintenance.
- Renderer replacement through MultiMesh, TileMapLayer, shaders, or chunks.
- Renderer-specific rules documentation.
- New documentation layout or plan-rules split.
- Hooks, automations, feature branches, pushes, or PRs.

## Out of Scope

- AI, combat, economy, units, and final balancing rules.
- Enclosure-fill and contested-border semantics.
- Multi-colony conflict resolution and simultaneous placement rules.
- AI action APIs and policy decisions.
- Persistent frontier sets or map-radius stress work.
- New external assets or addons.
- Renderer replacement through MultiMesh, TileMapLayer, shaders, or chunks.
- New documentation layout or plan-rules split.
- Hooks, automations, feature branches, pushes, PRs.

## Validation

Slice 6 changes runtime simulation behavior, HUD-visible debug metrics, tests,
and documentation. Run the headless test suite, `git diff --check`, and a
manual Godot editor check that the colony continues after local dead ends, HUD
re-anchor metrics update, and `R` reset still works.

## State Rule

`STATUS.md` is the single source of truth for current phase and slice.

If `STATUS.md` and `docs/NEXT_STEPS.md` conflict, treat it as a documentation
bug to report or fix. It is not an authority-order question.
