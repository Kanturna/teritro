# Teritro Next Steps

`NEXT_STEPS.md` names the next concrete work blocks. It is not a backlog for
every idea.

## Current Slice

Slice 5 - First Colony & Turn-Rule Prototype v0.1

## Slice 5 Exit Criteria

- `docs/PLAN_SLICE_5.md` records the accepted reviewed plan.
- Slice 4 visual sign-off is recorded before sim implementation.
- One visible test colony spawns at the starter cell.
- Auto-step expands every `0.25s` and remains deterministic.
- Turn-Rule is adjacent placement plus no repeated direction.
- No-valid-neighbor behavior is `Stall`; `R` resets the sim.
- Simulation storage is sparse and validates at most 6 local neighbors per step.
- Renderer consumes owned-cell snapshots and keeps color in render/scene state.
- Debug HUD exposes simulation metrics for owned cells, candidates, rejections,
  neighbor checks, validation cost, and stalled colonies.
- Headless tests cover sim rules, scene integration, renderer/debug metrics, and
  existing hex math.
- `git diff --check` passes.

## Branching

Use solo-main flow for now: code commits go directly to `main`. Re-evaluate if a
second active developer joins or PR review becomes necessary.

## Proposed Slice 6 - Expansion Stress & Enclosure Planning v0.1

- Review Slice 5 metrics and decide whether the current deterministic policy is
  enough for a stress slice.
- Consider map radius `120` only as a measured stress case, not a default.
- Plan enclosure-fill as event-triggered and area-bound, not per tick.
- Decide whether to add frontier sets before multi-colony behavior.

## Proposed Later Meta Slice - Tooling and Automation Plan

- Check whether Claude-Code hooks, commit reminders, pre-commit checks, or
  branch strategy rules are technically useful.
