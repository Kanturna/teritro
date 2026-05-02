# Teritro Findings

Use findings for review notes, risks, and future decision triggers. This is not
a loose backlog.

## Open Findings

- Before the first prototype, choose exact initial map radius and visual hex
  size.
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
- Before Slice 3, clarify whether `needs_user` is a reframe-only stance or a
  workflow label.

## Resolved Findings

### 2026-05-03 - Slice 2 review

- Avoided carrying previous project naming or rejected gap-based placement
  language into Teritro docs.
