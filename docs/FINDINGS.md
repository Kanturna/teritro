# Teritro Findings

Use findings for review notes, risks, and future decision triggers. This is not
a loose backlog.

## Open Findings

- Before `docs/WORKFLOW.md` grows clearly beyond about 250 lines, evaluate
  whether plan-related rules should move into their own document.
- Before implementing multi-colony spawn, decide final contested enclosure
  semantics. Slice 7 v0.1 treats regions touching non-self colonies as open and
  no-fill; multi-colony must choose a final policy such as nearest-claim,
  both-claim, no-fill, or weighted resolution.
- Before AI integration, decide whether agents submit intentions or use another
  controlled API.
- Before unit combat, define border ownership and movement permissions.
- Before large maps or many units, profile grid storage, flood-fill, border
  cache, and pathfinding.
- Before map radius exceeds 80 or zoom-out becomes a product requirement,
  validate renderer frame-time and visible-cell culling on target hardware.
- Before visual polish, evaluate whether procedural vectors, TileMapLayer,
  MultiMesh, shaders, or another renderer should own the beauty layer.
- Before adding any scan, AI, unit, economy, or renderer subsystem, define the
  debug metrics and test parameters that reveal its bottlenecks.
- Before a colony's `owned_cells` exceeds about 3000, a single
  `stall_resolution_ms` exceeds 5 ms, or re-anchor frequency stays above 1/sec,
  switch from on-demand frontier scanning to incremental frontier-set
  maintenance per colony.
- Before AI policy lands, refactor `step_colony()` into a validated action
  surface such as `get_legal_actions()` plus `apply_action()` so agents choose
  intentions without gaining simulation authority.
- Before owned-cell sets exceed about 10000 cells or
  `owned_batch_rebuild_ms` consistently exceeds 5 ms, evaluate incremental
  MultiMesh updates that apply only changed cells instead of rebuilding the
  entire batch.
- Before grid-on zoom-out views become product-relevant, decide whether the
  debug grid should move from chunked cached lines to shader, TileMapLayer,
  chunked mesh, or another non-`_draw()` render path.
- Before terrain/nature visuals begin, plan a production renderer path that is
  separate from the debug grid and can support grass, mountains, rivers, and
  other world visuals through batched, chunked, tiled, or shader-based drawing.
- If `grid_cache_rebuild_ms` exceeds 250 ms at radius 80, or grid-on zoom `1.0`
  exceeds a 16 ms 60-frame average draw target after Slice 8.3, re-evaluate the
  debug-grid renderer before adding more visual load.
- Before implementing multi-colony ticks, make changed-cell metrics accumulate
  multiple placements per tick instead of representing only one placement.
- Before allowing nested enclosure patterns as a product requirement, decide
  whether inner holes are filled in the same step, left as designed empty
  regions, or resolved by a later recursive/event pass.

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
- Restored the planned LOD thresholds after full-grid rendering at minimum zoom
  regressed draw time.
- Kept the map outline visible when the cell grid is hidden by LOD or toggled
  off, so the lab still has orientation on a white background.
- Deduplicated shared full-grid edges so interior hex lines render with more
  even weight and fewer line points.
- Added adaptive grid antialiasing under a line-point limit to reduce frayed
  edge artifacts without reintroducing low-zoom draw cost.
- Closed the Slice 4 visual pre-gate for Slice 5: existing headless lab checks
  pass, recent editor review accepted the black-on-white grid direction, and
  further renderer changes stay behind explicit visual-polish findings.

### 2026-05-03 - Slice 4 review

- Plan-stated LOD thresholds and antialiasing defaults drifted during
  implementation, causing severe low-zoom FPS regression.
- Slice 3 and Slice 4 plans did not name the renderer's quality dimensions,
  likely failure modes, acceptance checks, or tradeoff boundaries up front.
  Several artifacts surfaced only through post-implementation observation.
- A plan attempt also contained unverified repo-state assumptions, showing that
  plan claims need current source verification.
- Lesson captured as `Plan Value Binding` and `Quality Gates For System
  Slices` in `docs/WORKFLOW.md`. Future non-trivial system slices follow both.

### 2026-05-03 - Slice 4.5 review

- Quality Gates were required in plans, but completion reports did not yet
  require explicit quality-gate status.
- Non-trivial system slices needed a clearer plan requirement and heuristic.
- External review findings needed a visible completion-report disposition trail.
- Lesson captured in `AGENTS.md` completion-report requirements and
  `docs/WORKFLOW.md` review/intake rules.

### 2026-05-03 - Slice 5 Turn-Rule decisions

- Turn-Rule v0.1 means adjacent placement from the last placed cell plus no
  repeated placement direction.
- No-valid-neighbor behavior is `Stall`: the colony pauses, keeps its
  last-placed cell, and can be restarted through reset.
- Immediate reverse is not a separate Turn-Rule ban in v0.1 because the
  previous cell is already occupied.
- The current `_draw()` renderer remains acceptable for the first one-colony
  prototype because owned cells are sparse snapshots and the sim step does not
  scan the whole map.
- Manual Slice 5 visual review confirmed visible connected growth, reset
  behavior, and HUD visibility. The permanent local-stall behavior became the
  Slice 6 stall-resolution target.

### 2026-05-03 - Slice 6 Stall-Resolution decisions

- Replacing permanent `Stall` is a game-design decision, not a bug fix.
- Stall recovery is internal and stall-only in v0.1; it is not a general agent
  action yet.
- Re-anchor chooses the nearest owned frontier cell to the previous
  `last_placed_cell`, with `q` then `r` tie-breaks.
- Re-anchor resets placement direction and then places atomically in the same
  sim step.
- On-demand frontier scanning over owned cells is accepted for the one-colony
  prototype; concrete thresholds now trigger future incremental frontier-set
  work.

### 2026-05-03 - Slice 7 Enclosure-Fill decisions

- Enclosure-fill is event-local: it runs only after real placements and only
  scans empty regions adjacent to the placed cell.
- A placed cell needs at least two same-colony neighbors before enclosure scan
  can run.
- Map edge and out-of-bounds contact make a region open, not enclosed.
- v0.1 contested behavior is conservative: any non-self colony contact makes
  the region open/no-fill.
- Auto-filled cells change ownership but do not change `last_placed_cell`,
  `last_placement_direction`, or active `placements_total`.

### 2026-05-03 - Slice 7.1 performance review

- User testing showed two immediate bottlenecks after Slice 7: camera movement
  redrew owned cells every frame, and open enclosure regions could hit the old
  3000-cell cap with about 20 ms spikes.
- Slice 7.1 keeps the short-term procedural renderer but stops owned cells from
  forcing camera redraw when the full cell grid is hidden.
- Enclosure scans now use an adaptive effective cap. MultiMesh rendering,
  known-open enclosure caches, stricter closure triggers, and grid LOD work are
  deferred to a dedicated performance architecture slice.

### 2026-05-03 - Slice 8 renderer batching

- Owned-cell rendering moved from per-cell `_draw()` polygons to one internal
  `MultiMeshInstance2D` batch helper.
- Grid, map outline, and debug axes remain procedural overlays; this makes the
  renderer hybrid instead of a full renderer replacement.
- Full-grid debug rendering now has a candidate cap so large low-zoom full-grid
  views are suppressed before excessive line building starts.
- Known-open enclosure caches, stricter enclosure triggers, and larger grid
  renderer changes remain follow-up decisions.

### 2026-05-03 - Slice 8.2 debug snapshot and grid-cap calibration

- User testing confirmed owned-cell rendering no longer meaningfully drives FPS
  drops when the grid is off, even as territory grows.
- Grid-on Full-LOD movement remains the main renderer cost; a measured case
  around `5300` candidates and `20778` line points dropped to about `31 FPS`.
- The Full-Grid candidate cap was lowered from `6000` to `3000` so the debug
  grid hides before that known expensive view.
- Debug snapshots under `user://debug_snapshots` are now the preferred evidence
  format for future performance review.
- Terrain and natural-world visuals remain separate from the debug grid and
  should use batched, chunked, tiled, or shader-based render paths later.

### 2026-05-03 - Slice 8.3 plan review process lesson

- Slice 8.2 lowered the debug-grid candidate cap to address an FPS-drop
  symptom without naming the underlying use case: the neutral grid is a
  measurement tool the user relies on during world construction.
- The cap workaround hid the grid at the user's working zoom range, breaking
  the feature in its primary use case, and had to be removed in Slice 8.3 in
  favor of a chunked grid-line cache that addresses the structural cause:
  per-frame line building over visible cells.
- ADR-007's full-grid `>16 ms` re-evaluation trigger had already fired at
  Slice 8.2 measurement time, but was answered with a tighter cap rather than
  the architectural reassessment it asked for.
- Lesson captured as `UseCase Pre-Clarification` in `docs/WORKFLOW.md`.
  Symptom-first plans must name the user activity, breakage modes, and
  architectural options before Quality Gates are drafted, and a fired ADR
  re-evaluation trigger now explicitly signals that the workaround tier is
  exhausted.

### 2026-05-03 - Slice 8.3 chunked debug-grid decision

- The Slice 8.2 candidate-cap workaround is superseded by a chunked debug-grid
  line cache. Grid visibility should not vary by camera position at the same
  zoom.
- The debug grid remains an inspection/orientation layer. Future grass,
  mountain, river, and terrain visuals must use a separate production-oriented
  rendering path.
- If the chunked grid still misses the soft zoom `0.7` frame-time target, the
  next renderer decision should be shader/TileMap/chunked-mesh evaluation, not
  another visibility workaround.
