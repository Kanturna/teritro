# Teritro Next Steps

`NEXT_STEPS.md` names the next concrete work blocks. It is not a backlog for
every idea.

## Current Slice

Slice 7 - Event-Local Enclosure Fill Prototype v0.1

## Slice 7 Exit Criteria

- `docs/PLAN_SLICE_7.md` records the accepted reviewed plan.
- Enclosure-fill is triggered only after real placements.
- Enclosure scans only empty neighbor regions around the placed cell.
- Ordinary line growth short-circuits without flood-fill.
- Open, map-edge-connected, out-of-bounds, and contested regions remain
  unfilled.
- Auto-filled cells do not change `last_placed_cell`, placement direction, or
  active `placements_total`.
- Debug HUD exposes enclosure region count, visited cells, filled cells, aborts,
  and timing.
- Headless tests cover one-cell and multi-cell fills, open no-fill, contested
  no-fill, scan cap, static no-global-scan guard, and placement semantics.
- `git diff --check` passes.

## Branching

Use solo-main flow for now: code commits go directly to `main`. Re-evaluate if a
second active developer joins or PR review becomes necessary.

## Proposed Slice 8 - Expansion Behavior Review & Multi-Colony Prep v0.1

- Review Slice 6/7 re-anchor and enclosure metrics plus visual growth patterns
  for clumping, weak map coverage, or too-aggressive fill.
- Decide whether nearest re-anchor remains the deterministic baseline before
  AI-policy planning.
- Consider map radius `120` only as a measured stress case, not a default.
- Decide final contested enclosure semantics before multi-colony spawn.
- Decide whether incremental frontier sets or enclosure caches are needed before
  multi-colony behavior.

## Proposed Later Meta Slice - Tooling and Automation Plan

- Check whether Claude-Code hooks, commit reminders, pre-commit checks, or
  branch strategy rules are technically useful.
