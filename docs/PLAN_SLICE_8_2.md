# Slice 8.2 Plan v1.1: Debug Snapshot & Grid-Cap Calibration v0.1

## Summary

Slice 8.2 adds a performance snapshot workflow and calibrates the debug grid
candidate cap. User testing showed owned-cell rendering is stable after Slice 8
with grid off, while grid-on Full-LOD camera movement still drops heavily around
`5300` candidates, `20778` lines, and roughly `31 FPS`.

Versions:

- v1: initial plan after user measurement and repo grounding.
- v1.1: Claude P2s added: document the `6000 -> 3000` cap change, test JSON
  roundtrip, and validate snapshots use current provider data.

## Quality Gates

- `P` captures a JSON performance snapshot under `user://debug_snapshots` and
  shows HUD feedback.
- Snapshots contain schema version, label, timestamp, overlay metrics, all
  provider metrics, and lab context.
- Snapshot data roundtrips through JSON without losing key values.
- A snapshot after a real sim step reflects live simulation metrics.
- Full grid remains visible at default zoom `1.0`.
- Full grid is suppressed when the Full-LOD candidate estimate exceeds the new
  `3000` cap.
- DebugOverlay observes metrics only; it does not mutate simulation truth.

## Key Changes

- Add `DebugOverlay.capture_snapshot()` and `save_snapshot()` with stable JSON
  conversion for Godot values (`Vector2`/`Vector2i` as `[x, y]`, `Color` as
  `[r, g, b, a]`).
- Add `P` snapshot hotkey in HexLab, with HUD success/failure feedback.
- Lower `HexMapRenderer.full_grid_candidate_limit` from `6000` to `3000`.
- Update ADR-011 with the cap-change rationale and add ADR-012 for debug
  snapshots as the performance evidence format.
- Update status, next steps, and findings for Slice 8.2.

## Test Plan

- Run existing headless tests: `hex_grid_math_test.gd`,
  `territory_sim_test.gd`, `hex_debug_metrics_test.gd`,
  `hex_lab_smoke_test.gd`.
- Extend debug metrics tests to cover snapshot capture, save, JSON roundtrip,
  provider content, and grid cap suppression above `3000`.
- Extend smoke test to cover `P` snapshot hotkey and HUD confirmation.
- Run `git diff --check`.
- Manual Godot check: grid off remains stable, default zoom grid remains
  visible, and the previous problem zoom is hidden by cap.

## Assumptions

- Snapshot files are runtime artifacts under `user://`, not repo files.
- Slice 8.2 is measurement plus conservative grid protection, not a renderer
  rewrite.
- Terrain/nature visuals remain separate from the debug grid and will use
  batched, chunked, tiled, or shader paths later.

## First Reviewer Brief

Claude Code should check that snapshots are JSON-safe, saved outside the repo,
use real provider data, preserve key values after roundtrip, and do not mutate
simulation truth. Also check that the `3000` grid cap keeps default zoom visible
while suppressing large Full-LOD candidate views, and that docs consistently
separate debug-grid performance from future terrain rendering.
