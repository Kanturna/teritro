# Teritro Findings

Use findings for review notes, risks, and future decision triggers. This is not
a loose backlog.

## Open Findings

- Before implementing expansion, specify how the Turn-Rule handles blocked,
  owned, map-edge, and no-valid-neighbor cases.
- Before tuning placement, decide whether the Turn-Rule forbids only straight
  continuation or also immediate reverse. Default v0.1 forbids only straight
  continuation.
- Before implementing enclosure-fill, define contested enclosure semantics for
  multiple colonies.
- Before AI integration, decide whether agents submit intentions or use another
  controlled API.
- Before unit combat, define border ownership and movement permissions.
- Before large maps or many units, profile grid storage, flood-fill, border
  cache, and pathfinding.
- Before map radius exceeds 80 or zoom-out becomes a product requirement,
  validate renderer frame-time and visible-cell culling on target hardware.
- Before visual polish, evaluate whether procedural vectors, TileMapLayer,
  MultiMesh, shaders, or another renderer should own the beauty layer.
- Before committing visual sign-off for Slice 3, manually check the lab scene
  for crisp zoom, camera controls, readable HUD, and frame-time gates.

## Resolved Findings

### 2026-05-03 - Slice 2 review

- Avoided carrying previous project naming or rejected gap-based placement
  language into Teritro docs.

### 2026-05-03 - Slice 3 foundation

- Chose initial map radius `80` and visual hex radius `18 px`.
- Declared `needs_user` as a reframe-only stance, separate from review labels.
- Chose solo-main flow for early solo development, with collaboration triggers
  for re-evaluation.
