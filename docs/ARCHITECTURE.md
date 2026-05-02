# Teritro Architecture

This document defines architecture direction, not implementation.

## Layer Direction

```text
scenes / ui
debug
rendering
runtime
ai
sim
core
```

## Layer Responsibilities

- `core`: axial hex coordinates, directions, distances, neighbors, grid math,
  and generic graph/grid helpers.
- `sim`: ownership, colony state, expansion, enclosure, borders, energy, and
  later conflict rules.
- `ai`: later colony policies that propose actions; no Slice 2 decision locks
  the API shape.
- `runtime`: read-only snapshots and view models for rendering and debug.
- `rendering`: draws snapshots and owns presentation, not simulation truth.
- `debug`: observes and controls through explicit allowed APIs or adapters.
- `scenes`: Godot composition, input, camera, and lab/test surfaces.
- `resources`: tuning configs, colony definitions, and map definitions.

## Simulation Truth vs Visual Truth

Simulation truth includes hex cells, ownership, colony state, energy, placement
history, expansion legality, and enclosure results.

Visual truth includes colors, lines, animation, labels, overlays, camera state,
and presentation mode. Visual systems do not own or mutate simulation truth.

## Layer Sharpening

- Hex distance, neighbor lists, and direction vectors belong in `core`.
- Turn-Rule validation belongs in `sim` because it interprets placement history
  and colony state.
- Enclosure-fill belongs in `sim` because it interprets ownership and territory.
- Generic flood-fill helpers may live in `core` only if they contain no
  ownership, colony, or territory vocabulary.
- Existing addons are tooling or presentation candidates and should be reached
  through adapters before project code depends on them broadly.

## Debuggability Contract

Performance-sensitive systems must expose enough runtime metrics to identify
bottlenecks before they become hidden architecture problems.

At minimum, each such system should define:

- the main tunable test parameters
- the primary workload count, such as visible cells, active agents, or scan size
- the measured frame or tick cost when practical
- the fallback trigger for reducing quality, scale, or update frequency

Debug output may live in HUDs, debug overlays, probes, or tests, but it must not
own or mutate simulation truth.
