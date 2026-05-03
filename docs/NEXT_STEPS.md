# Teritro Next Steps

`NEXT_STEPS.md` names the next concrete work blocks. It is not a backlog for
every idea.

## Current Slice

Slice 4.5 - System Quality Gates & Plan Value Binding v0.1

## Slice 4.5 Exit Criteria

- `WORKFLOW.md` defines Plan Value Binding as a new section.
- Plan Value Binding covers plan values, quality/tradeoff boundaries, and
  verified repo-state claims.
- `WORKFLOW.md` defines Quality Gates For System Slices with functional goal,
  in-scope and out-of-scope quality dimensions, known failure modes, acceptance
  checks, and tradeoff boundaries.
- `FINDINGS.md` records the Slice 4 review lesson without blame language.
- `AGENTS.md` remains unchanged.
- No `docs/RENDERING_RULES.md` or runtime files are added.
- `git diff --check` passes.

## Branching

Use solo-main flow for now: code commits go directly to `main`. Re-evaluate if a
second active developer joins or PR review becomes necessary.

## Proposed Slice 5 - First Colony & Turn-Rule Prototype v0.1

- Start only after Slice 4.5 is complete and Slice 4 manual editor metrics are
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
