# Teritro Status

`STATUS.md` is dynamic project state, not a changelog. History lives in Git.

## Active Phase

Phase 1 - Meta Planning

## Active Slice

Slice 1 - Project Operating Contract v0.1

## Implemented (this slice)

Documentation contract created. No gameplay, simulation, runtime, or Godot code
changes.

`Implemented (this slice)` contains only the active slice. When the slice
changes, remove old slice contents instead of growing this file into history.

## Not Implemented

See `Out of Scope`.

## Out of Scope

- Territory rules
- Grid, cells, colonies, energy, rendering, balancing
- Simulation architecture
- Godot scene or script structure
- Hooks, branch strategy, pushes, PRs

## Validation

Markdown/manual documentation review only. No Godot run is needed because this
slice does not change runtime files.

## State Rule

`STATUS.md` is the single source of truth for current phase and slice.

If `STATUS.md` and `docs/NEXT_STEPS.md` conflict, treat it as a documentation
bug to report or fix. It is not an authority-order question.
