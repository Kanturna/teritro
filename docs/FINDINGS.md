# Teritro Findings

Use findings for review notes, risks, and future decision triggers. This is not
a loose backlog.

## Open Findings

- Before `docs/WORKFLOW.md` grows clearly beyond about 250 lines, evaluate
  whether plan-related rules should move into their own document.
- Before implementing enclosure-fill, define contested enclosure semantics for
  multiple colonies and keep the algorithm event-triggered and area-bound, not
  per tick.
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
- Before Slice 6 planning, complete the Slice 5 manual visual sign-off: confirm
  connected snake-line growth, no straight continuation, visible HUD metrics,
  `R` reset, and full territory visibility after zoom changes in the Godot
  editor.
- Before replacing `Stall`, design a deterministic Stall-Resolution mechanism:
  scan the colony's own frontier, choose the nearest owned cell with at least
  one valid placement neighbor, and reactivate from there. Decide distance
  metric, tie-breaking, and frontier-set storage in the same slice.
- Before owned-cell sets exceed about 5000 cells or multi-colony rendering
  lands, refactor owned-cell rendering to iterate visible owned cells instead
  of every owned cell.
- Before implementing multi-colony ticks, make changed-cell metrics accumulate
  multiple placements per tick instead of representing only one placement.

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
