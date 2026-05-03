# Teritro Next Steps

`NEXT_STEPS.md` names the next concrete work blocks. It is not a backlog for
every idea.

## Current Slice

Slice 8.2 - Debug Snapshot & Grid-Cap Calibration v0.1

## Slice 8.2 Exit Criteria

- `docs/PLAN_SLICE_8_2.md` records the accepted reviewed plan.
- `P` captures a JSON snapshot under `user://debug_snapshots`.
- Snapshot data includes overlay, renderer, simulation, and lab context metrics.
- Snapshot save/read JSON roundtrip and live-provider content are tested.
- `full_grid_candidate_limit` defaults to `3000`.
- Default zoom `1.0` still draws the grid.
- Full-LOD candidate areas over the cap hide the debug grid honestly in HUD and
  metrics.
- ADR-011/ADR-012 document the cap change and snapshot evidence format.
- `git diff --check` passes.

## Branching

Use solo-main flow for now: code commits go directly to `main`. Re-evaluate if a
second active developer joins or PR review becomes necessary.

## Proposed Slice 8.3 - Renderer Follow-Up Measurement v0.1

- Manually measure grid off/on performance after MultiMesh batching at about
  500, 1000, and 2000 owned cells using JSON snapshots.
- Decide whether grid rendering needs a stricter LOD threshold, visible-cell
  cap tuning, shader, TileMapLayer, or chunk renderer before grid-on zoom-out
  views are product-relevant.
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
