# Slice 7.1 Plan v1.1: Camera Redraw & Enclosure Cap Performance Patch

## Summary

Slice 7.1 is a focused performance patch after Slice 7. It addresses two
measured bottlenecks: camera movement must not redraw all owned cells every
frame, and failed enclosure scans must not block on large open regions up to
the old `3000`-cell cap.

Version history:

- v1: initial plan after Codex/Claude performance analysis.
- v1.1: added Claude P2 test refinements: exact effective-cap assertion and
  complete `needs_camera_redraw()` LOD matrix.

External review disposition:

- `accept`: camera-movement redraw fix.
- `accept`: adaptive enclosure cap with ADR update.
- `accept`: lower owned-cell rendering finding threshold.
- `defer`: MultiMesh, known-open cache, stricter trigger, and grid LOD refactor
  to a later performance slice.
- `document`: grid performance is not solved by Slice 7.1.

## Quality Gates

Functional goal:

- Camera pan/zoom with hidden grid stays stable as territory grows.
- Failed open-region enclosure checks no longer produce the observed 20 ms
  spikes around 500 owned cells.

In scope:

- Performance, visual continuity, debuggability, Plan Value Binding, tests.
- No Turn-Rule, re-anchor, or enclosure-semantics changes.

Out of scope:

- MultiMesh, TileMap, shader, or chunk renderer.
- Known-open cache or persistent frontier/enclosure sets.
- Stricter `>=3` enclosure trigger.
- Grid renderer refactor or new grid LOD policy.

Known failure modes:

- Territory is clipped during pan/zoom.
- Effective cap stops at `cap + 1` instead of exactly `cap`.
- A lowered cap silently misses legitimate larger enclosures.
- Tests still expect owned cells to force camera redraw.
- Grid FPS is described as solved even though grid work is deferred.

Acceptance checks:

- `needs_camera_redraw()` is true only when the cell grid is visible in full
  LOD.
- overview/simple/full x `grid_visible` true/false is tested.
- Owned cells are not view-culled in cached non-grid redraw paths.
- Effective enclosure scan limit is `min(enclosure_scan_cell_limit,
  max(50, owned_cells / 2))`.
- An open region larger than the effective limit visits exactly that limit,
  not `limit + 1`.
- Manual editor check confirms no territory clipping during grid-off pan/zoom.

Tradeoff boundaries:

- Allowed: draw all owned cells into the cached CanvasItem display list when
  the cell grid is not visible.
- Allowed: abort large uncertain fills conservatively in v0.1.
- Not allowed: global map scans, renderer simulation authority, gameplay rule
  changes, or silent plan-value drift.

## Key Changes

- Renderer: `needs_camera_redraw()` depends only on visible full-grid drawing;
  owned-cell drawing uses no view cull outside the full-grid path.
- Simulation: enclosure scans use an adaptive effective cap and expose it as a
  debug metric.
- Documentation: update ADR-010, `FINDINGS.md`, `STATUS.md`, and
  `NEXT_STEPS.md` for Slice 7.1 and deferred Slice 8 performance work.

## Test Plan

Headless:

- `hex_grid_math_test.gd`
- `territory_sim_test.gd`
- `hex_debug_metrics_test.gd`
- `hex_lab_smoke_test.gd`
- `git diff --check`

Manual:

- Godot editor, Radius 80, grid off, about 500+ owned cells: pan and zoom
  without territory clipping and with improved frame stability.
- Observe enclosure-abort metrics; `enclosure_ms` should be well below the
  previous 20 ms spike.
- Grid-on full-LOD performance is documented as deferred, not solved.

## Assumptions

- Slice 7 is the clean baseline.
- The user wants a focused immediate performance win, not the larger renderer
  architecture change.
- Grid performance remains a real finding for the next performance slice.
- The adaptive cap may be conservative in v0.1.

## First Reviewer Brief

Claude Code should check:

- Does `needs_camera_redraw()` only return true for visible full-grid drawing?
- Does pan/zoom avoid territory clipping?
- Does the LOD matrix test cover all six combinations?
- Does the enclosure scan stop exactly at the effective cap?
- Are ADR-010 and Findings updated consistently?
- Are MultiMesh, known-open cache, stricter trigger, and grid LOD explicitly
  deferred rather than partially implemented?
