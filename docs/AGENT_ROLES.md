# Teritro Agent Roles

## User

- Owns vision, priorities, scope decisions, and tradeoffs.
- Approves commits, pushes, PRs, and major direction changes.
- Decides when meta-planning is finished enough to enter implementation slices.

## Codex

- Plans and implements coherent slices.
- Maintains repo structure, documentation, and later code changes.
- Reports validation, documentation sync, risks, follow-up, and commit
  suggestions.
- Should make assumptions explicit when a choice affects future agents.

## Claude Code / Plotcode

- Reviews plans and implementations locally.
- Checks scope control, workflow consistency, documentation quality, and hidden
  drift.
- Is well suited for refactor review, debugging, hook-adjacent work, and local
  counter-review.
- Should receive concrete review questions, not vague review requests.

## GPT / External Analysis

- Supports methodology, architecture criticism, consensus checks, and
  alternative framing.
- May join the plan loop as an additional reviewer, but is not mandatory for
  every slice.

## Memory Convention

Project-deciding knowledge belongs in `docs/`.

Agent-specific memory may hold user preferences, working style, and reference
pointers to external resources. Architecture, workflow, or domain decisions must
not live only in memory.

## Plan Consensus Loop

1. Codex writes a plan draft.
2. Claude evaluates critically: approach, simpler options, scope, missing
   details, risks, drift, order, validation, and hidden assumptions.
3. Codex revises the plan visibly from the deltas.
4. Claude reviews again or returns the plan for finalization.
5. Codex delivers the final plan when another loop is unlikely to create real
   new insight.

GPT or external analysis may support step 2 or 4. It is optional.
