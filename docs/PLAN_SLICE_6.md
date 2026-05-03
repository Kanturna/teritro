# Slice 6 Plan v1.1: Stall Resolution via Frontier Re-Anchoring v0.1

## Summary

Slice 6 replaces permanent stall from Slice 5 with deterministic frontier
re-anchoring. If the colony cannot place from its last placed cell, it scans
only its own owned cells, chooses the nearest frontier cell with a free
neighbor, resets placement direction, and continues in the same sim step.

Versions:

- v1: initial plan for stall-only frontier re-anchoring.
- v1.1: added nearest-anchor ADR reasoning, concrete performance
  re-evaluation thresholds, no-reanchor-without-stall test, and future AI API
  refactor finding.

## Quality Gates

Functional goal: A colony keeps expanding after a local dead end as long as
some owned frontier cell has an in-bounds unowned neighbor. If no such frontier
cell exists, the colony stays stalled.

In scope: stall detection, event-local owned-cell frontier scan, deterministic
nearest-anchor choice, direction reset before the post-anchor placement, and
debug metrics for re-anchor work.

Out of scope: AI policy, enclosure-fill, multi-colony behavior, border
conflicts, energy, economy, units, pathfinding, map-radius increase, persistent
frontier sets, and renderer replacement.

Known failure modes: global map scans, re-anchor outside stall recovery,
nondeterministic anchor choice, stale direction blocking the first post-anchor
placement, incorrect permanent stall, and misleading debug metrics.

Acceptance checks: Headless tests cover normal Turn-Rule behavior, re-anchor
after stall, no re-anchor without stall, deterministic anchor tie-breaking,
permanent stall, deterministic sequences, and bounded scan counts.

Tradeoff boundaries: On-demand scanning over owned cells is allowed only for
stall events in the one-colony prototype. Global scans, AI surface changes,
enclosure logic, and renderer authority are not allowed in this slice.

## Key Changes

- Extend `TerritorySim.step_colony()` to try normal local placement first, then
  attempt one atomic re-anchor only if local placement fails.
- Choose the re-anchor cell by smallest hex distance to the previous
  `last_placed_cell`, then `q`, then `r`.
- Treat a frontier candidate as valid when it has any in-bounds unowned
  neighbor. Direction-continuity is ignored during the scan because the
  placement direction resets on anchor.
- Add simulation debug metrics for re-anchor attempts, successes, scanned
  owned cells, frontier neighbor checks, last anchor distance, stall resolution
  cost, and permanent stalls.
- Document nearest stall-only re-anchoring as an ADR and add future findings for
  frontier-set and AI action-surface refactors.

## Test Plan

- Run existing headless tests.
- Extend `territory_sim_test.gd` with re-anchor success, permanent stall,
  no-reanchor-without-stall, deterministic sequence, tie-break, and scan-bound
  cases.
- Extend debug metrics checks to include the new simulation metric keys.
- Run `git diff --check`.
- Manually verify in Godot that the colony continues after a local dead end,
  HUD metrics update, and `R` reset still works.

## Assumptions

- Re-anchor is an internal baseline simulation rule, not an agent action.
- Recovery is atomic in one sim step.
- On-demand owned-cell scanning is acceptable until metrics show otherwise.
- The AI-facing `get_legal_actions()` / `apply_action()` API is deferred until
  before AI policy work.

## First Reviewer Brief

Review whether re-anchor remains stall-only, avoids global scans, chooses
anchors deterministically, resets direction correctly, exposes honest metrics,
tests no-reanchor-without-stall, and keeps AI, enclosure, multi-colony, and
renderer-rewrite work out of scope.
