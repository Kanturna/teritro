# Teritro Status

`STATUS.md` is dynamic project state, not a changelog. History lives in Git.

## Active Phase

Phase 2 - Implementation

## Active Slice

Slice 4 - Renderer Profiling & Debug Foundation v0.1

## Implemented (this slice)

Added a scene-local DebugOverlay provider contract, renderer phase metrics,
60-frame HUD history, axis/HUD toggles, and local `_draw()` optimizations for
the procedural hex renderer. No colony, ownership, expansion, or simulation
rules beyond generic hex math.

`Implemented (this slice)` contains only the active slice. When the slice
changes, remove old slice contents instead of growing this file into history.

## Not Implemented

- Colony spawn, ownership, expansion, Turn-Rule validation, and enclosure-fill.
- AI, units, combat, economy, balancing, and beauty/shader polish.
- Renderer replacement through MultiMesh, TileMapLayer, shaders, or chunks.
- Hooks, automations, feature branches, pushes, or PRs.

## Out of Scope

- Colony, territory ownership, AI, combat, economy, and final balancing rules.
- Enclosure-fill and contested-border semantics.
- New external assets or addons.
- Renderer replacement through MultiMesh, TileMapLayer, shaders, or chunks.
- Hooks, automations, feature branches, pushes, PRs.

## Validation

Godot/headless checks are required for Slice 4 because runtime files changed.
Manual visual/performance checks in the Godot editor remain a review gate.

## State Rule

`STATUS.md` is the single source of truth for current phase and slice.

If `STATUS.md` and `docs/NEXT_STEPS.md` conflict, treat it as a documentation
bug to report or fix. It is not an authority-order question.
