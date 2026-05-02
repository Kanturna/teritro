# Teritro Next Steps

`NEXT_STEPS.md` names the next concrete work blocks. It is not a backlog for
every idea.

## Current Slice

Slice 4 - Renderer Profiling & Debug Foundation v0.1

## Slice 4 Exit Criteria

- DebugOverlay is a scene-local node, not an autoload.
- Renderer exposes phase timings, culling counts, line-point counts, and draw
  history.
- Full-grid drawing avoids per-visible-hex `PackedVector2Array.resize()`.
- Grid line antialiasing is a controllable performance switch.
- HUD detail mode uses `H`; `F3` remains reserved for the debug menu addon.
- Headless hex, lab, and debug metrics tests pass.
- Manual editor checks record zoom 1.0, 0.6, and 0.25 frame/draw behavior.

## Branching

Use solo-main flow for now: code commits go directly to `main`. Re-evaluate if a
second active developer joins or PR review becomes necessary.

## Proposed Slice 5 - First Colony & Turn-Rule Prototype v0.1

- Start only after Slice 4 manual editor metrics are reviewed.
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
