# Teritro Next Steps

`NEXT_STEPS.md` names the next concrete work blocks. It is not a backlog for
every idea.

## Current Slice

Slice 2 - Vision & ARCHITECTURE Direction v0.1

## Slice 2 Exit Criteria

- `docs/VISION.md`, `docs/ARCHITECTURE.md`, `docs/SIMULATION_CONCEPTS.md`,
  `docs/DECISIONS.md`, and `docs/FINDINGS.md` exist.
- Vision and ARCHITECTURE direction are documented without runtime code.
- The Turn-Rule is described as adjacent placement with no straight continuation.
- No final combat, economy, AI, balancing, or implementation rules are added.
- `AGENTS.md` stays under 80 lines and remains a router.
- Claude Code can review the result with concrete checks.

## Until Slice 3

Commit suggestions are manual at the end of each slice. They are not automatic
hooks yet.

## Proposed Slice 3 - Tooling and Automation Plan v0.1

- Check whether Claude-Code hooks, commit reminders, pre-commit checks, or
  branch strategy rules are technically useful and available.
- Decide branch strategy before the first push.
- Clarify whether `needs_user` is a reframe-only stance or a workflow label.

## Proposed Slice 4 - First Technical Prototype v0.1

- Build the smallest Godot lab that can display a hex map and one test colony.
- Implement only the minimum grid, colony state, and Turn-Rule validation needed
  for a visible prototype.
- Treat no-valid-neighbor behavior as a hard gate before implementation.
