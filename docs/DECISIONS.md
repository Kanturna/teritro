# Teritro Decisions

Decisions use this schema:

- Decision
- Reason
- Implementation rule
- Re-evaluation trigger

## ADR-001: Axial Hex Coordinates

Decision: Teritro uses axial hex coordinates for simulation cells.

Reason: Hex neighbors support organic territorial growth without diagonal
ambiguity, and axial coordinates keep distance and neighbor logic compact.

Implementation rule: Simulation stores and reasons about cells by axial
coordinates. Rendering converts coordinates to screen positions.

Re-evaluation trigger: Before large maps or many moving entities, profile grid
storage, pathfinding, flood-fill, and border-cache behavior.

## ADR-002: Simulation Truth And Visual Truth Stay Separated

Decision: Simulation truth and visual truth stay separated by layer.

Reason: Territory ownership, legality, and future AI/debug behavior must not
depend on visual nodes, colors, camera state, or presentation mode.

Implementation rule: Rendering consumes snapshots or view models. Rendering,
debug, and scenes do not directly own or mutate simulation truth.

Re-evaluation trigger: Before adding a new renderer, debug control, or scene
driver that needs write access to simulation state.

## ADR-003: Existing Addons Are Tooling Or Presentation Candidates

Decision: The existing debug and antialiased-line addons are candidates for
tooling and presentation only.

Reason: Addons can speed up debugging and visual clarity, but must not become
simulation authority.

Implementation rule: Project-facing use of addons should go through adapters
once runtime code depends on them.

Re-evaluation trigger: Before adding another external addon or binding
simulation behavior to an addon API.

## ADR-004: First Prototype Uses A Custom Procedural Hex Renderer

Decision: Slice 3 uses a custom procedural vector renderer for the first hexmap
lab instead of TileMapLayer or an external hex addon.

Reason: Vector rendering keeps early zooming crisp, and custom code keeps the
hex simulation math independent from Godot tile APIs while the core model is
still forming.

Implementation rule: Simulation and core math store axial coordinates, not tile
indices. Renderer choice remains replaceable; TileMapLayer is not excluded from
future rendering work.

Re-evaluation trigger: Reassess if map radius exceeds 200, default-zoom
frame-time exceeds 16 ms, min-zoom frame-time exceeds 33 ms, or a later beauty
layer needs a different renderer.

## ADR-005: Solo-Main Flow Until Collaboration Requires Branching

Decision: Teritro uses direct commits on `main` for solo development.

Reason: The project currently has one active developer and frequent small
slices. Feature branches would add process overhead before they provide value.

Implementation rule: Commit reviewed slices directly to `main`. Do not push or
open PRs unless the user explicitly asks.

Re-evaluation trigger: Reassess when a second active developer joins, when PR
review becomes useful, or before any release workflow needs protected branches.

## ADR-006: Performance-Sensitive Systems Expose Debug Metrics

Decision: Systems that can become performance bottlenecks must expose debug
metrics and tuning parameters as part of their first useful implementation.

Reason: Teritro is expected to grow toward large maps, many colonies, scans,
agents, and later units. Hidden costs would make regressions difficult to trace.

Implementation rule: Each performance-sensitive system should report workload
counts and measured cost when practical. Debug displays, probes, or tests may
read these metrics, but they must not own simulation truth.

Re-evaluation trigger: Before adding a system that scans many cells, updates
many agents, renders many elements, or runs every frame/tick without exposing a
debug path.

## ADR-007: Keep Procedural Renderer Short-Term With Metrics

Decision: Slice 4 keeps the procedural hex renderer as the short-term renderer
while adding phase metrics, local draw-path fixes, and a scene-local debug
overlay.

Reason: The current renderer is simple, replaceable, and sufficient for
profiling the first map view. Replacing it before measuring would add
architecture risk without proving which cost dominates.

Implementation rule: Rendering may keep using `_draw()` for the lab scene, but
must expose culling counts, line-point counts, phase timings, and frame-history
metrics. DebugOverlay reads metrics through registered providers and does not
own simulation truth.

Re-evaluation trigger: Reassess the renderer before colony work if full-grid
zoom 1.0 or 0.25 stays above 16 ms draw time, if line readability fails at
normal zoom levels, if ownership colors require per-cell rendering, or if map
radius above 80 becomes a product requirement.
