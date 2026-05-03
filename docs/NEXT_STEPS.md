# Teritro Next Steps

`NEXT_STEPS.md` names the next concrete work blocks. It is not a backlog for
every idea.

## Current Slice

Slice 8 - Batched Territory Rendering & Grid Guard v0.1

## Slice 8 Exit Criteria

- `docs/PLAN_SLICE_8.md` records the accepted reviewed plan.
- Owned cells render through one internal `MultiMeshInstance2D` batch helper.
- Renderer creates no per-cell nodes and does not use per-cell `_draw()`
  polygons for territory fill.
- Renderer metrics expose owned batch instances, rebuild cost, render mode, and
  grid-cap status.
- Synthetic tests cover 500+ owned cells, per-colony colors, batch draw-call
  shape, and grid-cap suppression.
- ADR-011 documents the hybrid renderer relationship to ADR-007.
- `FINDINGS.md` records the next trigger for incremental MultiMesh updates.
- `git diff --check` passes.

## Branching

Use solo-main flow for now: code commits go directly to `main`. Re-evaluate if a
second active developer joins or PR review becomes necessary.

## Proposed Slice 8.2 - Renderer Follow-Up Measurement v0.1

- Manually measure grid off/on performance after MultiMesh batching at about
  500, 1000, and 2000 owned cells.
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
