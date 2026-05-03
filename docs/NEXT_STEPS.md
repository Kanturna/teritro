# Teritro Next Steps

`NEXT_STEPS.md` names the next concrete work blocks. It is not a backlog for
every idea.

## Current Slice

Slice 4.6 - Completion Report Quality Anchors v0.1

## Slice 4.6 Exit Criteria

- `AGENTS.md` completion reports include quality-gate status when applicable.
- `AGENTS.md` completion reports include external review dispositions when
  applicable.
- `WORKFLOW.md` requires non-trivial system slices to have a plan document with
  Quality Gates before implementation, without forcing plans into `docs/`.
- `WORKFLOW.md` defines the non-trivial system-slice heuristic.
- `WORKFLOW.md` review handoff references plan acceptance checks when Quality
  Gates exist.
- `FINDINGS.md` records the Slice 4.5 review lesson and the `WORKFLOW.md`
  growth trigger.
- No runtime files or new documentation layout are added.
- `git diff --check` passes.

## Branching

Use solo-main flow for now: code commits go directly to `main`. Re-evaluate if a
second active developer joins or PR review becomes necessary.

## Proposed Slice 5 - First Colony & Turn-Rule Prototype v0.1

- Start only after Slice 4.6 is complete and Slice 4 manual editor metrics are
  reviewed.
- Add one visible test colony and starter cell.
- Add minimal colony state and ownership, still separated from rendering.
- Implement Turn-Rule validation only after no-valid-neighbor behavior is
  decided.
- Include Quality Gates For System Slices in the Slice 5 plan.
- Define debug metrics for colony count, valid candidates, rejected candidates,
  and placement validation cost before expanding the prototype.
- Keep grid visibility as a debug/view option, not simulation truth.

## Proposed Later Meta Slice - Tooling and Automation Plan

- Check whether Claude-Code hooks, commit reminders, pre-commit checks, or
  branch strategy rules are technically useful.
