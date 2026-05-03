# Teritro Next Steps

`NEXT_STEPS.md` names the next concrete work blocks. It is not a backlog for
every idea.

## Current Slice

Slice 8.3 - Chunked Debug Grid Renderer & Terrain Boundary v0.1

## Slice 8.3 Exit Criteria

- `docs/PLAN_SLICE_8_3.md` records the accepted reviewed plan.
- The old Full-Grid candidate-cap path is removed from renderer code and tests.
- Full-grid line geometry is cached in chunks and rebuilt only when map
  geometry changes.
- `grid_chunk_size` defaults to `16`.
- `simple_lod_zoom` is `0.65`; `overview_lod_zoom` remains `0.5`.
- `grid_hidden_reason` reports `global_off`, `zoom_lod`, or `none`.
- Headless tests cover chunk metrics, LOD boundary, position-independent grid
  visibility, cache rebuild threshold, and snapshot additive fields.
- ADR-007 documents that its renderer trigger fired; ADR-013 documents the
  chunked debug-grid cache.
- `git diff --check` passes.

## Branching

Use solo-main flow for now: code commits go directly to `main`. Re-evaluate if a
second active developer joins or PR review becomes necessary.

## Proposed Slice 8.4 - Renderer Follow-Up Measurement v0.1

- Manually measure grid off/on performance after chunked debug-grid caching at
  zoom `1.0`, `0.7`, and `0.65` using JSON snapshots.
- Decide whether grid-on zoom `0.7` needs shader/TileMap/chunked-mesh work if
  submit cost still exceeds the soft `16 ms` target.
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
