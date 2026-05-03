# Teritro Agent Rules

This file is the automatic entry point for agents. Keep it short. Detailed
workflow rules live in `docs/WORKFLOW.md`; current project state lives in
`docs/STATUS.md`.

## Read First

Before non-trivial work, read:

1. `docs/STATUS.md`
2. `docs/NEXT_STEPS.md`
3. `docs/WORKFLOW.md`
4. `docs/AGENT_ROLES.md` when coordinating agents, handoffs, or reviews

Read context docs only when relevant:

- `docs/VISION.md` for product direction, design pillars, or long-term scope.
- `docs/ARCHITECTURE.md` for layers, ownership, services, or adapters.
- `docs/SIMULATION_CONCEPTS.md` for simulation vocabulary or concept changes.
- `docs/DECISIONS.md` before changing documented decisions.
- `docs/FINDINGS.md` when handling known risks, reviews, or open triggers.

## Core Rules

- Respect the active phase and active slice in `docs/STATUS.md`.
- Do not propose or implement out-of-phase work unless the user asks for it.
- Work in coherent slices: reviewable, bounded, and validated together.
- Do not commit, push, or open PRs unless the user explicitly asks.
- After each completed slice, provide a completion report and suggested commit.
- Base suggested commits on the current open `git status`/diff, not memory.
- Never invent test results, file contents, repo facts, or validation outcomes.

## Completion Report

Every completed slice must include:

- Summary
- Changed files
- Validation
- Quality gate status, when applicable
- Documentation sync
- Risks / follow-up
- External review dispositions, when applicable
- Review handoff stance
- Suggested commit title matching the current open diff
- Suggested commit body matching the current open diff

## Router Rule

`AGENTS.md` keeps authority over safety, Git/commit permissions, validation
duties, and review handoff rules.

If these instructions conflict with detailed workflow docs, follow
`docs/WORKFLOW.md` only where it is more specific and does not weaken safety,
Git/commit permissions, validation duties, or review handoff rules.
