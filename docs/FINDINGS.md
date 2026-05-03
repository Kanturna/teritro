# Teritro Findings

Use findings for review notes, risks, and future decision triggers. This is not
a loose backlog.

## Open Findings

- Before implementing expansion, specify how the Turn-Rule handles blocked,
  owned, map-edge, and no-valid-neighbor cases.
- Before tuning placement, decide whether the Turn-Rule forbids only straight
  continuation or also immediate reverse. Default v0.1 forbids only straight
  continuation.
- Before implementing enclosure-fill, define contested enclosure semantics for
  multiple colonies.
- Before AI integration, decide whether agents submit intentions or use another
  controlled API.
- Before unit combat, define border ownership and movement permissions.
- Before large maps or many units, profile grid storage, flood-fill, border
  cache, and pathfinding.
- Before map radius exceeds 80 or zoom-out becomes a product requirement,
  validate renderer frame-time and visible-cell culling on target hardware.
- Before visual polish, evaluate whether procedural vectors, TileMapLayer,
  MultiMesh, shaders, or another renderer should own the beauty layer.
- Before closing renderer sign-off for Slice 4, manually record lab scene
  metrics and line readability at zoom 1.0, 0.6, and 0.25 in the Godot editor.
- Before adding any scan, AI, unit, economy, or renderer subsystem, define the
  debug metrics and test parameters that reveal its bottlenecks.
- Before the first colony prototype, decide from Slice 4 measurements whether
  the current `_draw()` grid renderer is acceptable or whether MultiMesh,
  shader grid, TileMapLayer, chunks, or another visual-only renderer must come
  first.

## Resolved Findings

### 2026-05-03 - Slice 2 review

- Avoided carrying previous project naming or rejected gap-based placement
  language into Teritro docs.

### 2026-05-03 - Slice 3 foundation

- Chose initial map radius `80` and visual hex radius `18 px`.
- Declared `needs_user` as a reframe-only stance, separate from review labels.
- Chose solo-main flow for early solo development, with collaboration triggers
  for re-evaluation.
- Added renderer LOD and HUD metrics after min-zoom rendering exposed a
  bottleneck risk.
- Added `G` as a grid visibility toggle so debug and later visual modes can
  hide the cell grid when it becomes noise.
- Hid debug axes by default and muted the first dark-grid style before the lab
  switched to a black-on-white grid.

### 2026-05-03 - Slice 4 renderer profiling

- Added a scene-local DebugOverlay provider contract and renderer phase metrics.
- Removed per-visible-hex `PackedVector2Array.resize()` from the full-grid draw
  path.
- Made grid-line antialiasing and screen-stable line width performance/quality
  switches.
- Added HUD detail, debug-axis, culling, line-point, and 60-frame draw/frame
  metrics for manual renderer review.
- Kept the full cell grid visible through the current minimum zoom to avoid a
  blank white overview.
- Kept the map outline visible when the cell grid is toggled off, so the lab
  still has orientation on a white background.
