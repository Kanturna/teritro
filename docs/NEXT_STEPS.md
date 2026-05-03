# Teritro Next Steps

`NEXT_STEPS.md` names the next concrete work blocks. It is not a backlog for
every idea.

## Current Slice

Slice 6 - Stall Resolution via Frontier Re-Anchoring v0.1

## Slice 6 Exit Criteria

- `docs/PLAN_SLICE_6.md` records the accepted reviewed plan.
- Re-anchor is attempted only after local placement from `last_placed_cell`
  fails.
- Re-anchor scans the colony's own `owned_cells`, not the whole map.
- Anchor choice is deterministic: nearest hex distance, then `q`, then `r`.
- Placement direction resets before placing from the chosen anchor.
- Permanent stall remains only when no owned frontier cell has an in-bounds
  unowned neighbor.
- Debug HUD exposes re-anchor attempts, successes, scan counts, neighbor checks,
  anchor distance, and stall-resolution time.
- Headless tests cover re-anchor success, no re-anchor without stall, permanent
  stall, tie-breaks, deterministic sequences, and scan bounds.
- `git diff --check` passes.

## Branching

Use solo-main flow for now: code commits go directly to `main`. Re-evaluate if a
second active developer joins or PR review becomes necessary.

## Proposed Slice 7 - Expansion Behavior Review & Enclosure Planning v0.1

- Review Slice 6 re-anchor metrics and visual growth patterns for clumping or
  weak map coverage.
- Decide whether nearest re-anchor remains the deterministic baseline before
  AI-policy planning.
- Consider map radius `120` only as a measured stress case, not a default.
- Plan enclosure-fill as event-triggered and area-bound, not per tick.
- Decide whether incremental frontier sets are needed before multi-colony
  behavior.

## Proposed Later Meta Slice - Tooling and Automation Plan

- Check whether Claude-Code hooks, commit reminders, pre-commit checks, or
  branch strategy rules are technically useful.
