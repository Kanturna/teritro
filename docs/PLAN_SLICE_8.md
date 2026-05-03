# Slice 8 Plan v1.1: Batched Territory Rendering & Grid Guard

## Summary

Slice 8 is the second renderer-first performance slice after 7.1. Owned-cell
rendering moves from per-cell `_draw()` polygons to a single internal
`MultiMeshInstance2D` batch helper. The debug grid also gets a hard full-grid
candidate cap so low-zoom full-grid views cannot rebuild excessive line sets.

Version history:

- v1: initial renderer-first performance plan.
- v1.1: added Claude P2 refinements: Hybrid Renderer ADR, multi-color batch
  test, and rebuild-performance trigger.

External review disposition:

- `accept`: owned-cell rendering moves to a batched renderer adapter.
- `accept`: ADR-011 documents the hybrid renderer relationship to ADR-007.
- `accept`: synthetic multi-color test guards per-colony batch colors.
- `accept`: `owned_batch_rebuild_ms` and `10000` owned-cell trigger are
  documented for future incremental updates.
- `defer`: known-open enclosure cache, stricter enclosure trigger, grid shader
  or beauty layer, TileMap/chunk renderer, and gameplay changes.

## Quality Gates

Functional goal:

- Territory fills remain visually equivalent but are no longer submitted as one
  `_draw()` polygon per owned cell.
- Full-LOD cell grid rendering is suppressed when the estimated candidate area
  exceeds `full_grid_candidate_limit`.

In scope:

- Performance, visual continuity, renderer debug metrics, layer separation, and
  headless test coverage.
- Existing simulation snapshots and color maps remain the renderer input.

Out of scope:

- Enclosure known-open cache.
- Grid shader, beauty layer, TileMapLayer, chunk renderer, or map-radius
  increase.
- Multi-colony gameplay, AI, economy, combat, or rule changes.

Known failure modes:

- Batch renders above grid/outline instead of underneath.
- Per-colony color or alpha data is lost.
- Snapshot updates create one node or one `_draw()` call per owned cell.
- Grid cap hides the grid at normal default zoom.
- Metrics claim batch rendering while old per-cell drawing remains active.

Acceptance checks:

- Renderer creates one owned-cell batch helper and no nodes per cell.
- Synthetic 500+ owned-cell snapshot reports `owned_batch_instances ==
  owned_cells_total`.
- `_draw()` draw-call estimate does not scale with owned-cell count.
- Two colony IDs with different colors keep different batch instance colors.
- Default zoom `1.0` remains under the grid candidate cap.
- A low test cap suppresses full-grid rendering and reports that suppression.
- Existing sim, enclosure, debug metrics, and lab smoke tests stay green.

Tradeoff boundaries:

- Allowed: one internal `MultiMeshInstance2D` adapter inside `HexMapRenderer`.
- Allowed: suppressing the debug grid when the candidate cap fires.
- Not allowed: moving simulation truth into rendering, changing gameplay
  policy, or implementing deferred renderer/enclosure architecture in Slice 8.

## Key Changes

- Renderer:
  - Add one internal `OwnedCellsBatch` `MultiMeshInstance2D`.
  - Build the hex fill mesh once from the existing hex polygon.
  - Rebuild MultiMesh instances from `cell_owners` and `colony_id -> color`
    inside `set_territory_snapshot()`.
  - Keep `_draw()` for map outline, debug axes, and grid lines only.
  - Add `full_grid_candidate_limit = 6000` and suppress full-grid rendering
    when the estimated candidate area exceeds it.
- Metrics/HUD:
  - Add `owned_render_mode`, `owned_batch_instances`,
    `owned_batch_rebuild_ms`, `owned_batch_draw_calls`,
    `full_grid_candidate_limit`, and `grid_suppressed_by_limit`.
- Documentation:
  - Add ADR-011 for the hybrid renderer.
  - Resolve the owned-cell rendering trigger and add an incremental update
    trigger before `10000` owned cells or sustained rebuilds above `5 ms`.

## Test Plan

Headless:

- `hex_grid_math_test.gd`
- `territory_sim_test.gd`
- `hex_debug_metrics_test.gd`
- `hex_lab_smoke_test.gd`
- `git diff --check`

Manual:

- Godot editor, Radius 80, 500+ owned cells, grid off: pan/zoom stays stable
  and territory remains visible.
- Grid on at zoom `1.0`: grid remains visible and territory stays underneath.
- Zoom out: grid is hidden by LOD or cap while map outline stays visible.
- HUD detail mode shows batch instances, rebuild cost, and grid-cap status.

## Assumptions

- Slice 7.1 is the clean baseline.
- Godot 4.6 `MultiMeshInstance2D` is available as the internal renderer
  adapter.
- `full_grid_candidate_limit = 6000` keeps default zoom detailed while
  protecting lower full-LOD zooms.
- Known-open enclosure caching is only planned if `enclosure_ms > 5 ms`
  continues to appear in practical playtests.

## First Reviewer Brief

Claude Code should check:

- Does owned-cell rendering use the batch helper instead of per-cell `_draw()`?
- Does simulation truth stay outside the renderer?
- Is territory visually below grid/outline?
- Does node count stay constant as owned-cell count grows?
- Does `_draw()` draw-call estimate stay independent from owned-cell count?
- Are per-colony colors preserved in the batch path?
- Does the grid cap only fire for large full-grid candidate areas?
- Are known-open cache, stricter trigger, multi-colony, and gameplay changes
  kept out of scope?
- Are ADR, Findings, Status, and Next Steps synchronized?
