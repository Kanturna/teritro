# Slice 5 Plan v1.1: First Colony & Turn-Rule Prototype v0.1

## Summary

Slice 5 adds the first simulation prototype: one deterministic test colony
spawns on a starter cell, expands automatically every `0.25s`, and obeys the
Turn-Rule. A new placement must be adjacent to the last placed cell and must
not continue in the same direction as the previous placement.

Map radius stays `80`. Out of scope: AI, energy, enclosure-fill, conflicts,
economy, units, renderer replacement, and map-radius increase.

Versions:

- v1: Initial Slice 5 plan after Slice 4.6 methodology and Turn-Rule
  clarification.
- v1.1: Claude P2s accepted: colony color stays out of sim state, `R` reset is
  added, `last_placement_direction` replaces `previous_placed_cell`, and Slice
  4 visual sign-off is handled before sim work.

## Quality Gates

Functional goal:

- One visible test colony appears in the Hex Lab.
- Auto-step expands the colony every `0.25s`.
- Each placement is adjacent to the last placed cell.
- The next direction never repeats the previous direction.
- `R` resets the sim deterministically.

Quality dimensions in scope:

- Correctness: ownership, map bounds, and Turn-Rule legality.
- Determinism: same start state, same placement sequence.
- Debuggability: metrics for candidates, rejections, checks, cost, and stalls.
- Performance shape: work scales with active placement, not total map size.
- Layer separation: sim owns truth; renderer consumes snapshots.
- Visual clarity: owned cells are visible under the existing grid.

Quality dimensions out of scope:

- Enclosure-fill, border conflicts, multi-colony conflict resolution, AI
  policy, energy, combat, economy, save/load, and visual polish beyond a basic
  owned-cell fill.

Known failure modes:

- Accidentally reintroducing distance-2 or gap placement.
- Scanning the whole map during a sim step.
- Letting renderer or scene code mutate simulation truth.
- Storing visual color in colony sim state.
- Stall producing loops or unstable follow-up steps.
- Non-reproducible auto-step or reset behavior.
- Debug metrics not matching the sim step.

Acceptance checks:

- Headless tests cover adjacency, straight rejection, occupied and out-of-bounds
  rejection, stall, reset, and deterministic sequence.
- Scene smoke test loads the lab with sim and renderer snapshot.
- Manual editor check shows connected snake-line growth and no straight repeat.
- HUD exposes colony count, owned cells, placements, candidates, rejections,
  neighbor checks, validation cost, and stalled colonies.
- Each placement step checks at most 6 neighbors and never scans the whole map.
- Sim code has no Godot node dependency and no render/color state.

Tradeoff boundaries:

- Allowed: simple deterministic test policy, basic cell fill, one colony.
- Not allowed: global map scans in ticks, renderer authority over sim state,
  visual truth in sim state, Turn-Rule drift, or unmeasured placement cost.

## Key Changes

- Add `TerritorySim` as a `RefCounted` sim model with sparse `cell_owners`,
  colony state by ID, `last_placement_direction`, and debug metrics.
- Integrate the sim into Hex Lab with auto-step, `R` reset, DebugOverlay
  provider registration, and snapshot handoff to the renderer.
- Let the renderer draw owned-cell snapshots using a render-side
  `colony_id -> color` map below grid lines.
- Update docs for active Slice 5, sparse/event-local simulation, resolved
  Turn-Rule decisions, and deferred enclosure-fill.

## Test Plan

- Run existing headless tests:
  - `hex_grid_math_test.gd`
  - `hex_lab_smoke_test.gd`
  - `hex_debug_metrics_test.gd`
- Add and run `territory_sim_test.gd` for starter ownership, adjacency,
  straight rejection, occupied/out-of-bounds rejection, stall, reset,
  determinism, and max-6-neighbor checks.
- Run `git diff --check`.
- Manually verify in Godot editor: visible starter, connected auto-expansion,
  no straight repeat, HUD sim metrics, `R` reset, and unchanged `G`/`X`/`H`
  controls.

## Assumptions

- Auto-step is the chosen Slice 5 driver.
- No-valid-neighbor behavior is `Stall`.
- Turn-Rule v0.1 forbids only straight continuation; immediate reverse is
  already blocked by occupied-cell validation.
- Map radius remains `80`.
- Enclosure-fill is deferred but must remain possible through future loops and
  closed shapes.

## First Reviewer Brief

Review whether the Turn-Rule is exactly adjacent plus not-same-direction, sim
steps validate at most 6 local neighbors, sim storage is sparse, sim state has
no color or node dependency, stall/reset/determinism are tested, Slice 4 visual
sign-off was handled before sim implementation, and no AI, energy, combat,
economy, enclosure-fill, or multi-colony conflict logic entered this slice.
