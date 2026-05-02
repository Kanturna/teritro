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
