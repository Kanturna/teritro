# Teritro Next Steps

`NEXT_STEPS.md` names the next concrete work blocks. It is not a backlog for
every idea.

## Current Slice

Slice 3 - Grid, Camera & Visual Prototype Foundation v0.1

## Slice 3 Exit Criteria

- Phase 2 is declared in `docs/STATUS.md`.
- Axial hex math supports directions, neighbors, distance, radius counts, rings,
  and pointy-top world conversion.
- A Godot lab scene displays a radius-80 procedural hex map.
- Camera supports WASD/arrows, Shift fast pan, middle-mouse drag, smooth wheel
  zoom, and `C` reset.
- Renderer uses viewport culling, no node per hex, and avoids per-frame
  PackedArray allocation in `_draw()`.
- HUD reports radius, total cells, visible cells, zoom, FPS, and frame time.
- Headless hex-math tests pass.

## Branching

Use solo-main flow for now: code commits go directly to `main`. Re-evaluate if a
second active developer joins or PR review becomes necessary.

## Proposed Slice 4 - Renderer Performance & Debug Foundation v0.1

- Profile the current `_draw()` renderer at zoom 0.25, 0.5, 1.0, and during
  camera movement.
- Decide whether the short-term renderer remains procedural `_draw()` or moves
  to cached chunks, shader grid, TileMapLayer, MultiMesh, or another visual-only
  renderer.
- Define a reusable debug metrics contract for expensive systems before adding
  colony expansion, scans, AI, units, or combat.
- Keep grid visibility as a debug/view option, not simulation truth.

## Proposed Slice 5 - First Colony & Turn-Rule Prototype v0.1

- Add one visible test colony and starter cell.
- Add minimal colony state and ownership, still separated from rendering.
- Implement Turn-Rule validation only after no-valid-neighbor behavior is
  decided.
- Define debug metrics for colony count, valid candidates, rejected candidates,
  and placement validation cost before expanding the prototype.
- Keep grid visibility as a debug/view option, not simulation truth.

## Proposed Later Meta Slice - Tooling and Automation Plan

- Check whether Claude-Code hooks, commit reminders, pre-commit checks, or
  branch strategy rules are technically useful.
