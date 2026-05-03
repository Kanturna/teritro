# Slice 8.3 Plan v2: Chunked Debug Grid Renderer & Terrain Boundary v0.1

## Summary

Slice 8.3 replaces the Full-Grid candidate-cap workaround with a chunked debug
grid line cache. The debug grid must stay useful for orientation and simulation
inspection, but it must not define the later terrain/world renderer.

Versions:

- v1: initial plan for a stable debug-grid visibility policy.
- v2: Claude review addressed measurable goals, zoom 0.7 hard/soft gates,
  submit-cost failure mode, explicit ADR sync, cache rebuild threshold,
  edge-ownership rules, snapshot schema, LOD-boundary tests, reviewer cache
  invalidation check, and `grid_hidden_reason` enum mapping.

## Quality Gates

Functional goal:
- Grid-on camera pan reaches a 60-frame average `draw_ms <= 16 ms` at zoom
  `1.0`, keeps grid visibility position-independent, and replaces per-frame
  line construction with a cache built only when map geometry changes.

In scope:
- Debug-grid performance, position-stable visibility, renderer metrics, tests,
  and documentation that separates debug grid from future terrain rendering.

Out of scope:
- Shader, TileMap, chunked terrain, grass/mountain/river assets, multi-colony,
  AI, combat, economy, gameplay changes, map radius increase, or product terrain
  rendering.

Known failure modes:
- Grid visibility changes based on camera position at the same zoom.
- Camera movement rebuilds cached grid lines.
- Cached chunk edges are duplicated or missing at chunk borders.
- Map boundary edges are skipped because they have no in-map neighbor.
- `grid_cache_rebuild_ms` is too high and makes scene load feel broken.
- Just above `simple_lod_zoom`, Full-Grid submit costs can still exceed budget
  even without per-frame line building.

Acceptance checks:
- `grid_chunk_size = 16`.
- `simple_lod_zoom = 0.65`, `overview_lod_zoom = 0.5`.
- `grid_cache_rebuild_ms <= 250 ms` at radius `80`.
- Grid visibility at zoom `1.0` and `0.7` is independent of camera position.
- Zoom `0.7` keeps grid visibility as a hard requirement; `draw_ms <= 16 ms`
  is a target, and if missed it must be documented as follow-up.
- Zoom `0.65` is simple LOD and hides the cell grid by LOD.
- `grid_hidden_reason` is `global_off`, `zoom_lod`, or `none`.
- Snapshot schema remains version `1`; new grid fields are additive.

Tradeoff boundaries:
- Allowed: cached procedural debug-grid lines and chunked visibility culling.
- Not allowed: reintroducing candidate-cap hiding for same-zoom positions,
  moving simulation truth into rendering, or treating the debug grid as the
  future terrain renderer.

## Key Changes

- Renderer:
  - Remove the old Full-Grid candidate-cap path:
    `full_grid_candidate_limit`, `_estimate_full_grid_candidate_count`,
    `grid_suppressed_by_limit`, and `estimated_full_grid_candidates`.
  - Add a chunked line cache for the full cell grid.
  - Rebuild the cache only when map geometry changes in `_rebuild_map()` or
    `_rebuild_polygon()`, not on camera movement.
  - Draw only visible grid chunks during Full-LOD camera redraw.
  - Use explicit edge ownership:
    - neighbor in map and lexicographically before current cell: skip;
    - neighbor in map and lexicographically after current cell: current cell
      owns the edge;
    - neighbor out of map: current cell owns the boundary edge.
  - Keep map outline, debug axes, and owned-cell MultiMesh paths unchanged.

- Metrics and HUD:
  - Add `grid_render_mode = "chunked_lines"`, `grid_chunk_size`,
    `grid_chunks_total`, `grid_chunks_visible`,
    `grid_cache_line_points_total`, `grid_visible_line_points`,
    `grid_cache_rebuild_ms`, and `grid_hidden_reason`.
  - Replace HUD cap wording with chunk/cache wording.

- Documentation:
  - Save this plan as `docs/PLAN_SLICE_8_3.md`.
  - Update `STATUS.md` and `NEXT_STEPS.md` for Slice 8.3.
  - Add an ADR-007 update note that its renderer re-evaluation trigger fired.
  - Add ADR-013 for the chunked debug-grid line cache.
  - Update findings so future terrain/nature rendering stays on a separate
    batched, chunked, tiled, or shader-based path.

## Test Plan

Headless:
- Run `hex_grid_math_test.gd`, `territory_sim_test.gd`,
  `hex_debug_metrics_test.gd`, and `hex_lab_smoke_test.gd`.
- Extend renderer tests for chunk metrics, cache rebuild threshold,
  position-independent visibility, LOD boundary at `0.65`, and removal of old
  cap keys.
- Confirm camera movement does not change `grid_cache_rebuild_ms`.
- Confirm existing snapshot schema version stays `1` and contains additive grid
  cache metrics.

Manual:
- In Godot editor, radius `80`, grid on:
  - zoom `1.0`, WASD pan: grid visible and 60-frame average `draw_ms <= 16 ms`;
  - zoom `0.7`, WASD pan: grid visibility remains stable; if draw target is
    missed, document follow-up instead of hiding the grid by position;
  - zoom `0.65`: grid hidden by LOD;
  - grid off: territory performance remains stable.
- Press `P` for snapshots at relevant states.

Static:
- `git diff --check`.
- Verify no shader, TileMap, terrain, multi-colony, AI, economy, combat, or
  gameplay-rule changes entered the slice.

## Assumptions

- Slice 8.2 and the vision update are committed.
- Debug-grid chunk caching is a bridge for inspection and orientation, not the
  terrain renderer for grass, mountains, rivers, or future world visuals.
- Snapshot schema version remains `1` because this slice only adds fields.

## First Reviewer Brief

Claude Code should check that the old candidate-cap path is gone, grid
visibility is position-independent, cache rebuilds happen only on map/polygon
changes, edge ownership includes the boundary-edge case, HUD wording uses
chunk/cache language, `grid_cache_rebuild_ms` stays under the planned threshold,
ADR-007 and ADR-013 are synced, and no terrain/gameplay scope entered Slice 8.3.
