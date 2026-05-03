# Slice 7 Plan v1.1: Event-Local Enclosure Fill Prototype v0.1

## Summary

Slice 7 adds the first one-colony enclosure-fill prototype. After a real
placement, the simulation checks only empty neighbor regions around the newly
placed cell. A region is filled only when it is fully enclosed by the same
colony, does not touch the map edge, and does not touch another colony.

Versions:

- v1: initial plan for event-local enclosure fill.
- v1.1: added step-local region tracking, contested v0.1 no-fill semantics,
  and an automated static no-global-scan guard.

## Quality Gates

Functional goal: closed empty regions become owned automatically; open regions
remain empty. Fill runs after real placements, including placements after
re-anchor.

In scope: one-colony correctness, event-local performance, enclosure metrics,
sim/render separation, and visible owned-cell fill through existing snapshots.

Out of scope: final multi-colony contested resolution, AI, energy, economy,
combat, units, renderer rewrite, persistent enclosure caches, and map-radius
increase.

Known failure modes: global flood-fill, repeated traversal of the same empty
region, false fill of open regions, treating the map edge as a wall, mutating
Turn-Rule state through auto-fill, hidden metrics, or counting fills as active
placements.

Acceptance checks: tests cover one-cell and multi-cell fills, open and contested
no-fill, scan cap aborts, no flood-fill during ordinary line growth, no
`coords_in_radius` usage in sim, and unchanged placement semantics.

Tradeoff boundaries: local flood-fill from empty neighbors is allowed with
`enclosure_scan_cell_limit = 3000`. Per-tick scans, full-map scans, contested
ownership rules, and renderer-owned fill logic are not allowed.

## Key Changes

- Trigger enclosure resolution after active placements only.
- Short-circuit unless the placed cell has at least two same-colony neighbors.
- Track empty cells visited across all region scans in the same step to skip
  duplicate traversal.
- Treat regions that touch the map edge, out-of-bounds space, or another colony
  as open/no-fill in v0.1.
- Auto-filled cells update ownership but do not change `last_placed_cell`,
  `last_placement_direction`, or `placements_total`.
- Add enclosure debug metrics and show them in detailed HUD mode.

## Test Plan

- Run all existing headless tests.
- Extend `territory_sim_test.gd` with closed-region, open-region, contested,
  cap-abort, no-scan, and placement-semantics checks.
- Extend debug metrics and scene smoke tests for enclosure metric keys and
  renderer snapshot updates.
- Add a headless static guard that reads `src/sim/territory_sim.gd` and rejects
  `coords_in_radius`.
- Run `git diff --check`.

## Assumptions

- Map edge is open, not an enclosing wall.
- Same-colony ownership encloses territory in v0.1.
- Any non-self colony contact makes the region open/no-fill.
- Final contested multi-colony semantics are deferred.
- Flood-fill uses deterministic direction order `0..5`.
- Legitimate regions above 3000 cells or enclosure cost above 5 ms trigger
  re-evaluation.

## First Reviewer Brief

Review whether enclosure-fill stays placement-triggered and event-local, avoids
global scans, skips duplicate region traversal, leaves open/edge/contested
regions unfilled, keeps auto-fill out of Turn-Rule and active placement counts,
exposes honest metrics, and keeps final multi-colony semantics out of scope.
