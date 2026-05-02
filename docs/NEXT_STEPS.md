# Teritro Next Steps

`NEXT_STEPS.md` names the next concrete work blocks. It is not a backlog for
every idea.

## Current Slice

Slice 1 - Project Operating Contract v0.1

## Slice 1 Exit Criteria

- `AGENTS.md` exists and stays under 80 lines.
- `docs/STATUS.md`, `docs/WORKFLOW.md`, `docs/AGENT_ROLES.md`, and
  `docs/NEXT_STEPS.md` exist.
- `docs/WORKFLOW.md` stays under roughly 150 lines.
- No simulation, Territory, or Godot architecture decisions are introduced.
- Commit suggestion format is defined.
- Agent roles and Plan Consensus Loop are defined.
- Claude Code can review the result with concrete checks.

## Until Slice 3

Commit suggestions are manual at the end of each slice. They are not automatic
hooks yet.

## Proposed Slice 2 - Meta Documentation Map v0.1

- Decide which future docs are needed before implementation, such as
  `VISION.md`, `ARCHITECTURE.md`, `ARCHITECTURE_RULES.md`, `SIM_RULES.md`,
  `DECISIONS.md`, and `FINDINGS.md`.
- Later `DECISIONS.md` should use an ADR schema: Decision / Reason /
  Implementation rule / Re-evaluation trigger.
- Later `FINDINGS.md` should describe open findings as triggers, such as
  "Before X, evaluate Y", and separate open findings from resolved findings.
- Keep workflow consensus separate from future domain status terms. If a domain
  status is needed later, do not casually reuse `consensus`.

## Proposed Slice 3 - Tooling and Automation Plan v0.1

- Check whether Claude-Code hooks, commit reminders, pre-commit checks, or
  branch strategy rules are technically useful and available.
- Decide branch strategy before the first push.
