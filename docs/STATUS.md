# Teritro Status

`STATUS.md` is dynamic project state, not a changelog. History lives in Git.

## Active Phase

Phase 2 - Implementation

## Active Slice

Slice 4.5 - System Quality Gates & Plan Value Binding v0.1

## Implemented (this slice)

Added workflow rules for Plan Value Binding and Quality Gates For System
Slices. Documented the Slice 4 renderer-review lesson without changing runtime
or simulation files.

`Implemented (this slice)` contains only the active slice. When the slice
changes, remove old slice contents instead of growing this file into history.

## Not Implemented

- Colony spawn, ownership, expansion, Turn-Rule validation, and enclosure-fill.
- AI, units, combat, economy, balancing, and beauty/shader polish.
- Renderer replacement through MultiMesh, TileMapLayer, shaders, or chunks.
- Renderer-specific rules documentation.
- Hooks, automations, feature branches, pushes, or PRs.

## Out of Scope

- Colony, territory ownership, AI, combat, economy, and final balancing rules.
- Enclosure-fill and contested-border semantics.
- New external assets or addons.
- Renderer replacement through MultiMesh, TileMapLayer, shaders, or chunks.
- Runtime, scene, rendering, simulation, or test-code changes.
- Hooks, automations, feature branches, pushes, PRs.

## Validation

Slice 4.5 is documentation-only. `git diff --check` and manual Markdown review
are required; no Godot run is needed.

## State Rule

`STATUS.md` is the single source of truth for current phase and slice.

If `STATUS.md` and `docs/NEXT_STEPS.md` conflict, treat it as a documentation
bug to report or fix. It is not an authority-order question.
