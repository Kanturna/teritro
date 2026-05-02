# Teritro Status

`STATUS.md` is dynamic project state, not a changelog. History lives in Git.

## Active Phase

Phase 1 - Meta Planning

## Active Slice

Slice 2 - Vision & ARCHITECTURE Direction v0.1

## Implemented (this slice)

Vision, architecture direction, simulation concepts, decisions, and findings
documents created. No gameplay, simulation, runtime, or Godot code changes.

`Implemented (this slice)` contains only the active slice. When the slice
changes, remove old slice contents instead of growing this file into history.

## Not Implemented

- Grid, colony, expansion, enclosure, AI, combat, economy, and rendering code.
- Hooks, branch strategy, scenes, resources, or runtime validation.
- Final balancing or implementation-level simulation rules.

## Out of Scope

- Godot runtime files, scenes, resources, and addons
- Final combat, economy, AI, and balancing rules
- Grid, colony, enclosure, rendering, and unit implementation
- Godot scene or script structure
- Hooks, branch strategy, pushes, PRs

## Validation

Markdown/manual documentation review only. No Godot run is needed because Slice
2 does not change runtime files.

## State Rule

`STATUS.md` is the single source of truth for current phase and slice.

If `STATUS.md` and `docs/NEXT_STEPS.md` conflict, treat it as a documentation
bug to report or fix. It is not an authority-order question.
