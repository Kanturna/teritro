# Teritro Next Steps

`NEXT_STEPS.md` names the next concrete work blocks. It is not a backlog for
every idea.

## Current Slice

Slice 8.3.1 - Debug Grid Toggle Authority & AA Stability v0.1

## Slice 8.3.1 Exit Criteria

- `docs/PLAN_SLICE_8_3_1.md` records the accepted reviewed plan.
- `G on` shows the debug grid at zoom `1.0`, `0.7`, `0.65`, `0.6`, and `0.25`.
- `G off` hides the debug grid at the same zooms.
- Existing LOD branches remain, but LOD no longer decides grid visibility.
- `needs_camera_redraw()` is true whenever the grid is visible.
- `grid_line_antialiased` defaults to `true`; Auto-AA remains available as an
  opt-in path when manual antialiasing is disabled.
- `grid_chunk_size` defaults to `16`.
- `simple_lod_zoom` is `0.65`; `overview_lod_zoom` remains `0.5`.
- `grid_hidden_reason` reports `global_off` or `none` in normal behavior.
- Headless tests cover grid on/off behavior across all five zooms, AA stability
  across camera positions, chunk metrics, cache rebuild threshold, and snapshot
  additive fields.
- ADR-013 documents that debug-grid visibility follows `grid_visible`, not LOD.
- `git diff --check` passes.

## Branching

Use solo-main flow for now: code commits go directly to `main`. Re-evaluate if a
second active developer joins or PR review becomes necessary.

## Proposed Slice 8.4 - Renderer Follow-Up Measurement v0.1

- Manually measure grid off/on performance after chunked debug-grid caching at
  zoom `1.0`, `0.7`, `0.65`, `0.6`, and `0.25` using JSON snapshots.
- Decide whether far-zoom grid-on views need shader/TileMap/chunked-mesh work
  if submit cost is uncomfortable despite being user-controlled by `G`.
- Keep future terrain/nature visuals separate from the debug grid and plan them
  as a batched, chunked, tiled, or shader-based renderer path when product
  terrain starts.
- Decide whether open/aborted enclosure regions need a known-open cache with
  local invalidation if `enclosure_ms` still exceeds 5 ms in practical runs.
- Re-evaluate stricter enclosure triggers or loop-detection if adaptive caps
  hide legitimate enclosures.
- Evaluate incremental MultiMesh updates before owned cells exceed about 10000
  or `owned_batch_rebuild_ms` consistently exceeds 5 ms.
- Keep map radius `120` as a measured stress case only, not a new default.

## Proposed Later Slice - Expansion Behavior Review & Multi-Colony Prep v0.1

- Review Slice 6/7 re-anchor and enclosure metrics plus visual growth patterns.
- Decide whether nearest re-anchor remains the deterministic baseline before
  AI-policy planning.
- Decide final contested enclosure semantics before multi-colony spawn.

## Proposed Later Meta Slice - Tooling and Automation Plan

- Check whether Claude-Code hooks, commit reminders, pre-commit checks, or
  branch strategy rules are technically useful.
