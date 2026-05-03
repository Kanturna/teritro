# Teritro Status

`STATUS.md` is dynamic project state, not a changelog. History lives in Git.

## Active Phase

Phase 2 - Implementation

## Active Slice

Slice 5 - First Colony & Turn-Rule Prototype v0.1

## Implemented (this slice)

Added the first sparse TerritorySim prototype with one deterministic
auto-expanding test colony, Turn-Rule validation, renderer snapshot handoff,
simulation debug metrics, and reset support.

`Implemented (this slice)` contains only the active slice. When the slice
changes, remove old slice contents instead of growing this file into history.

## Not Implemented

- Enclosure-fill and contested-border semantics.
- Multi-colony spawn, simultaneous expansion, border conflict, and ownership
  conflict resolution.
- AI, units, combat, economy, balancing, and beauty/shader polish.
- Renderer replacement through MultiMesh, TileMapLayer, shaders, or chunks.
- Renderer-specific rules documentation.
- New documentation layout or plan-rules split.
- Hooks, automations, feature branches, pushes, or PRs.

## Out of Scope

- AI, combat, economy, units, and final balancing rules.
- Enclosure-fill and contested-border semantics.
- Multi-colony conflict resolution and simultaneous placement rules.
- New external assets or addons.
- Renderer replacement through MultiMesh, TileMapLayer, shaders, or chunks.
- New documentation layout or plan-rules split.
- Hooks, automations, feature branches, pushes, PRs.

## Validation

Slice 5 changes runtime simulation, rendering integration, scene behavior,
tests, and documentation. Run the headless test suite, `git diff --check`, and
a manual Godot editor check for visible connected expansion, no straight
continuation, HUD metrics, and `R` reset.

## State Rule

`STATUS.md` is the single source of truth for current phase and slice.

If `STATUS.md` and `docs/NEXT_STEPS.md` conflict, treat it as a documentation
bug to report or fix. It is not an authority-order question.
