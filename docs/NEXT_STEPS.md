# Teritro Next Steps

`NEXT_STEPS.md` names the next concrete work blocks. It is not a backlog for
every idea.

## Current Slice

Slice 7.1 - Camera Redraw & Enclosure Cap Performance Patch v0.1

## Slice 7.1 Exit Criteria

- `docs/PLAN_SLICE_7_1.md` records the accepted reviewed plan.
- Camera movement redraws the renderer only when the full cell grid is visible.
- Owned cells are not view-culled in cached non-grid redraw paths.
- Enclosure scans use the adaptive effective cap
  `min(enclosure_scan_cell_limit, max(50, owned_cells / 2))`.
- Enclosure scan cap is exact, not off by one.
- Debug HUD exposes the effective enclosure scan limit.
- Headless tests cover the redraw LOD matrix and adaptive cap behavior.
- `git diff --check` passes.

## Branching

Use solo-main flow for now: code commits go directly to `main`. Re-evaluate if a
second active developer joins or PR review becomes necessary.

## Proposed Slice 8 - Renderer And Enclosure Performance Architecture v0.1

- Decide whether owned-cell rendering moves to MultiMesh, chunks, TileMapLayer,
  or another batched rendering path before territories exceed about 500 cells.
- Decide whether open/aborted enclosure regions need a known-open cache with
  local invalidation.
- Decide whether grid rendering needs a stricter LOD threshold or visible-cell
  cap before zoom-out/grid-on views are product-relevant.
- Re-evaluate stricter enclosure triggers or loop-detection if adaptive caps
  hide legitimate enclosures.
- Keep map radius `120` as a measured stress case only, not a new default.

## Proposed Later Slice - Expansion Behavior Review & Multi-Colony Prep v0.1

- Review Slice 6/7 re-anchor and enclosure metrics plus visual growth patterns.
- Decide whether nearest re-anchor remains the deterministic baseline before
  AI-policy planning.
- Decide final contested enclosure semantics before multi-colony spawn.

## Proposed Later Meta Slice - Tooling and Automation Plan

- Check whether Claude-Code hooks, commit reminders, pre-commit checks, or
  branch strategy rules are technically useful.
