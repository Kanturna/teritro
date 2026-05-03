# Slice 8.3.1 Plan v2: Debug Grid Toggle Authority & AA Stability

## Summary

Slice 8.3.1 is a small renderer/UX follow-up to Slice 8.3.

UseCase: The neutral grid is a measurement and construction tool for later
world design. The user uses it to read hex distances, territory paths, and
future terrain layout. Therefore `G` is the user-facing visibility authority:
`G on` shows the grid, `G off` hides it.

Current breakage: LOD auto-hide overrides `G` at zoomed-out views, and Auto-AA
can flip by visible chunk/line counts. Chosen architecture: grid visibility
follows only `grid_visible`; far-zoom FPS cost is a conscious user tradeoff.
Deferred architecture: shader, TileMap, or mesh grid remains FINDINGS-triggered
if grid-on far zoom becomes product-relevant or permanently too expensive.

Versionshistorie:
- v1: initial plan after user testing and Claude evaluation of grid LOD-hide
  and AA flipping.
- v2: added UseCase block, LOD-branch decision, AA-threshold disposition, and
  consistent zoom test matrix.

## Quality Gates

Functional goal:
- `G on` shows the debug grid at zoom `1.0`, `0.7`, `0.65`, `0.6`, and `0.25`.
- `G off` hides the grid everywhere.
- Grid lines stay visually stable across camera positions at the same zoom.
- Slice 8.3 chunked-cache behavior remains; no return to per-frame line-build.

In scope:
- Debug-grid visibility policy.
- Stable default antialiasing for chunked grid lines.
- Cleanup of active `zoom_lod` hidden-reason behavior.
- HUD/debug metrics honesty.
- Tests and docs for the new policy.

Out of scope:
- Shader, TileMap, mesh, or terrain renderer.
- Production terrain visuals, grass, mountains, rivers.
- Simulation, colony rules, enclosure, AI, economy, combat.
- Map-radius changes.

Known failure modes:
- LOD still hides grid despite `G on`.
- `needs_camera_redraw()` stays false at low zoom while grid is visible.
- AA status flips by visible chunks or camera position.
- Grid-on far zoom becomes expensive and is mistaken as solved performance.
- Snapshot/HUD still reports `hidden by LOD` although grid is user-controlled.

Acceptance checks:
- With `grid_visible = true`, `will_draw_cell_grid()` is true at zoom `1.0`,
  `0.7`, `0.65`, `0.6`, and `0.25`.
- With `grid_visible = false`, `will_draw_cell_grid()` is false at the same
  zooms.
- `needs_camera_redraw()` is true whenever `grid_visible = true`.
- `grid_hidden_reason` is only `none` or `global_off` in normal behavior.
- Position-independence covers all five zooms.
- At fixed zoom `1.0` and `0.7`, `grid_line_effective_antialiased` is identical
  across at least five camera positions.
- `grid_line_antialiased` default is `true`.
- Manual far-zoom `G on` shows grid; any FPS drop is documented as
  user-controlled cost, not hidden by LOD.

Tradeoff boundaries:
- Allowed: Grid-on at far zoom may cost FPS; user controls it with `G`.
- Not allowed: automatic LOD hiding that overrides `G`.
- Not allowed: simulation/gameplay changes or renderer architecture replacement.

## Key Changes

- Renderer policy:
  - `will_draw_cell_grid()` returns true whenever `grid_visible` is true.
  - Keep existing LOD branches for future styling differentiation; do not
    consolidate them in this slice.
  - `_draw()` draws overview/simple/full map styling, then draws grid chunks
    whenever `grid_visible` is true.
  - `needs_camera_redraw()` follows visible grid state.
  - Remove `zoom_lod` as an active hidden reason.

- AA stability:
  - Set `grid_line_antialiased` default to `true`.
  - Keep `grid_line_auto_antialias` and `grid_antialias_line_point_limit` as
    opt-in configuration for future experiments.
  - With default pinned AA, the position-sensitive line-count threshold is
    inert.

- Documentation:
  - Save this plan as `docs/PLAN_SLICE_8_3_1.md`.
  - Update `STATUS.md` and `NEXT_STEPS.md`.
  - Update ADR-013: grid visibility follows `grid_visible`, not LOD.
  - Update `FINDINGS.md`: resolve LOD-hide and AA-flip decisions, keep
    far-zoom grid performance as a future renderer trigger if needed.

## Test Plan

Headless:
- Existing tests continue to pass:
  - `hex_grid_math_test.gd`
  - `territory_sim_test.gd`
  - `hex_debug_metrics_test.gd`
  - `hex_lab_smoke_test.gd`
- Update renderer tests:
  - Camera redraw matrix expects redraw true for all five zooms when grid is on.
  - Visibility matrix expects grid on/off behavior at all five zooms.
  - Position-independence covers all five zooms.
  - AA stability checks fixed zoom `1.0` and `0.7` across at least five camera
    positions.
  - Assert `grid_line_antialiased == true`.
  - Metrics/HUD no longer expect `zoom_lod` as normal hidden reason.

Manual:
- Godot editor, Radius 80:
  - Toggle `G` at zoom `1.0`, `0.7`, `0.6`, `0.33`, and `0.25`.
  - Confirm grid remains visible when on and hidden when off.
  - Pan camera at zoom `0.67`/`0.76`; line thickness should remain stable.
  - Verify manual override still works if `grid_line_antialiased` is false.
  - Record `P` snapshots for one near zoom and one far zoom with grid on.
  - If far-zoom grid-on FPS is low, document as user-controlled cost and future
    renderer trigger.

Static:
- `git diff --check`.
- Confirm no sim/gameplay/terrain renderer changes entered this slice.

## Assumptions

- Slice 8.3 is the accepted baseline.
- `G` is the user-facing source of truth for debug-grid visibility.
- `grid_line_antialiased = true` is the v0.1 visual-stability default.
- Existing LOD branches stay in place for future styling/performance
  differentiation.
- Far-zoom grid performance is not hidden by workaround; if unacceptable, it
  triggers a future real grid-renderer slice.

## First Reviewer Brief

Claude Code should check:

- Is `G on` zoom-/LOD-independent?
- Do LOD branches remain without deciding grid visibility?
- Does `_draw()` draw grid chunks in simple/overview without bypassing the cache?
- Is `needs_camera_redraw()` consistent with visible grid?
- Is `zoom_lod` no longer produced as a normal grid-hide reason?
- Is AA stable and no longer dependent on visible chunk/line-point count by
  default?
- Does the manual override `grid_line_antialiased = false` still work?
- Are tests for `1.0`, `0.7`, `0.65`, `0.6`, and `0.25` updated?
- Are shader/TileMap/terrain/simulation out of scope?
- Is far-zoom grid-on performance documented honestly as user-controlled cost or
  future finding?
