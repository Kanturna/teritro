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
zoom 1.0 stays above 16 ms draw time, if overview/simple LOD loses orientation
or line readability, if ownership colors require per-cell rendering, or if map
radius above 80 becomes a product requirement.

## ADR-008: Sparse Event-Local Simulation Work

Decision: Map size is capacity, not automatic simulation workload.

Reason: Teritro needs room for territories to grow, but larger empty maps must
not make every tick more expensive. Expansion, borders, and later scans should
scale with active colonies, recent placements, active frontier/border perimeter,
or triggered scan area instead of total cell count.

Implementation rule: Simulation stores owned cells sparsely by axial
coordinate. The first expansion prototype validates only the 6 neighbors around
the last placed cell. Empty cells consume no simulation state. Enclosure-fill is
deferred and must be event-triggered and area-bound when planned.

Re-evaluation trigger: Reassess before increasing default map radius above 80,
before adding multi-colony border behavior, before enclosure-fill, or before any
system scans cells beyond a local placement neighborhood.

## ADR-009: Stall-Only Frontier Re-Anchoring

Decision: A colony that cannot expand from its last placed cell uses stall-only
frontier re-anchoring and picks the nearest owned frontier cell to the previous
last placed cell.

Reason: Nearest re-anchoring preserves locality and makes the baseline growth
pattern predictable. A farthest-frontier policy would cover broader area sooner
but creates more fragmented snake patterns. Nearest is the v0.1 game-design
baseline, not a final AI policy.

Implementation rule: Re-anchor is only attempted after normal local placement
fails. The scan checks the colony's own owned cells, not the whole map. A
frontier cell is valid when it has at least one in-bounds unowned neighbor.
Tie-break by hex distance, then axial `q`, then axial `r`. Reset placement
direction before placing from the chosen anchor.

Re-evaluation trigger: Reassess if visual playtests show clumping or weak map
coverage, if multi-colony border conflict introduces anchor bias, before AI
policy training, before a colony exceeds about 3000 owned cells, if one stall
resolution exceeds 5 ms, or if sustained re-anchor frequency exceeds 1/sec.

## ADR-010: Event-Local Enclosure Fill

Decision: Enclosure-fill runs only after a real placement and scans empty
regions adjacent to that placed cell.

Reason: Enclosure is a triggered consequence of a new boundary segment, not a
per-tick map property. Local scans keep map size as capacity instead of
automatic workload.

Implementation rule: Skip enclosure resolution unless the placed cell has at
least two same-colony neighbors. Flood-fill only from unowned in-bounds
neighbors of the placed cell, track step-local visited empty cells, and cap each
step at an adaptive effective limit:
`min(enclosure_scan_cell_limit, max(50, owned_cells / 2))`. Regions touching map
edge, out-of-bounds space, or a non-self colony are treated as open and are not
filled. Auto-filled cells update ownership but do not update active placement
state.

Re-evaluation trigger: Reassess if legitimate enclosed regions exceed the
adaptive safety cap, if `enclosure_ms` exceeds 5 ms, if visual playtests show
missed legitimate enclosures because the adaptive cap is too tight, before
multi-colony spawn, or before nested enclosure behavior becomes a product
requirement.

## ADR-011: Hybrid Renderer For Owned Cells And Debug Overlays

Decision: Owned-cell territory fill renders through one internal
`MultiMeshInstance2D` batch helper, while grid lines, map outline, and debug
axes remain procedural `_draw()` overlays.
This extends ADR-007's procedural renderer decision rather than replacing it.

Reason: Per-cell `_draw()` polygons scale directly with owned-cell count and
caused frame-time drops as territory grew. Grid lines and map outline already
use batched line submission, so moving only owned-cell fill to MultiMesh gives
the needed performance improvement without replacing the whole lab renderer.

Implementation rule: `HexMapRenderer.set_territory_snapshot()` converts
simulation snapshots and render-side colony colors into MultiMesh instances.
The simulation does not know about MultiMesh, colors, camera state, or nodes.
The `OwnedCellsBatch` helper stays internal to `HexMapRenderer` and renders
under `_draw()` overlays for grid, outline, and axes.

Re-evaluation trigger: Reassess if grid/outline/axes require per-cell visual
state, if `owned_batch_rebuild_ms` consistently exceeds 5 ms, if owned cells
exceed about 10000, or if multi-colony rendering needs a different visual
stacking or update strategy.

Slice 8.2 update: `full_grid_candidate_limit` was lowered from `6000` to
`3000` after user measurement showed roughly `5300` Full-Grid candidates and
about `31 FPS` at zoom around `0.87`. Default zoom `1.0` remains below the cap.
Reassess the value if default zoom is accidentally suppressed or if grid-on
views become product-relevant.

## ADR-012: Debug Snapshots As Performance Evidence

Decision: Performance observations should be captured as JSON debug snapshots
when a renderer, simulation, or debug subsystem is evaluated.

Reason: Screenshots and recalled FPS numbers are useful for discussion but not
machine-comparable. A snapshot with overlay, renderer, simulation, and lab
context metrics gives agents a reproducible evidence format for future
performance reviews.

Implementation rule: `DebugOverlay` owns snapshot capture and file writing.
Snapshots collect `get_debug_metrics()` from all registered providers and
serialize Godot values into JSON-safe arrays or primitives. Snapshot files are
runtime artifacts under `user://debug_snapshots`; they are not repo state and
do not change simulation truth.

Re-evaluation trigger: Reassess the schema before multi-colony, AI, units, or
external comparison tooling require structured per-colony, per-agent, or
scenario metadata that the v1 schema cannot represent clearly.
