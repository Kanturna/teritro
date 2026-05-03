# Teritro Workflow

## Authority

Rule authority: `AGENTS.md > WORKFLOW.md > AGENT_ROLES.md > README.md`.

`AGENTS.md` has domain authority over safety, Git/commit permissions,
validation duties, and review handoff rules. Future architecture docs may own
architecture, layer, or service conflicts, but must not bypass safety, Git, or
review rules. Changing an `AGENTS.md` rule requires its own slice.

Domain guidance authority: `DECISIONS.md > ARCHITECTURE.md >
SIMULATION_CONCEPTS.md > VISION.md > FINDINGS.md`. `STATUS.md` and
`NEXT_STEPS.md` describe current work; they do not rewrite domain decisions.

Phases are broad project sections. Phase changes must be declared in
`STATUS.md` and justified by the slice plan that triggers the change.

Branching defaults to solo-main flow until `DECISIONS.md` or a later workflow
slice changes it.

## Start Protocol

Before non-trivial work:

- Run `git status --short`.
- Read the docs listed in `AGENTS.md`.
- Name the goal, affected file group, main assumption, main risk, and intended
  validation path before editing.

## Slice Discipline

Work in slices that are as large as possible and as small as needed. A slice
should have one coherent purpose, a review path, and a validation path. Do not
split coherent work into artificial micro-slices, and do not bundle unrelated
work to reduce slice count.

Plan-stated defaults, thresholds, limits, and gates are implementation
constraints. Changing them needs explicit user instruction, a revised plan, or a
documented mini-slice; do not silently drift them in code.

## Commit Suggestions

Every completed slice needs a suggested commit. Do not create the commit unless
the user explicitly asks.

Before suggesting a commit, run `git status --short` and inspect the relevant
open diff. The suggested title and body must describe only the currently
uncommitted changes, not earlier plans, already committed work, or remembered
scope. If the tree is clean, say that no commit is currently needed.

Title format:

```text
type(scope): imperative title
```

Types: `arch`, `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`.
Initial scopes: `planning`, `docs`, `workflow`, `agents`, `godot`, `addons`.

Heavy tier (`arch`, `feat`, `refactor`, `perf`) body fields:

```text
WHAT:
WHY:
IMPACT:
VALIDATION:
DOCS:
RISKS:
FOLLOW-UP:
```

Light tier (`fix`, `docs`, `test`, `chore`) requires only:

```text
WHAT:
VALIDATION:
```

Add optional fields only when they materially help future agents.

## Documentation Sync

After every change, check whether `STATUS.md`, `NEXT_STEPS.md`, `WORKFLOW.md`,
or `AGENT_ROLES.md` must change. If docs are not updated after a code change,
explain why no documentation update was needed.

## Review Handoff

End each completion report with one workflow label:

- `lokal experimentell` - local experiment, not ready for review.
- `reviewbar` - ready for another agent to inspect.
- `commitfaehig` - ready for the user to request a commit.
- `pushfaehig` - ready for the user to request a push.

These labels are workflow labels, not canonical domain status values. When
requesting review, ask concrete questions; do not write only "please review".

## External Evaluation Intake

Treat external reviews as structured findings. For each concrete finding,
choose one action: `accept`, `reject with reason`, `defer with reason`, or
`document`. Slice 1 uses this light form; priority-heavy P0/P1/P2 handling can
be added later if regular cross-reviews justify it.

Low-risk qualitative findings should be accepted by default when they stay
inside the current slice scope, add no new dependency, do not change unresolved
architecture or gameplay decisions, are quick to validate, and reduce drift,
ambiguity, duplication, or future cleanup cost. If such a finding is not
implemented, state the deferral reason explicitly.

## Reframe Rule

If an agent sees that a request is wrongly framed, too broad, too narrow, or not
verifiable, stop with stance `needs_user`. Provide a concrete reframe proposal
with Goal, Anchor Question, and Constraints. `needs_user` is a reframe-only
stance, separate from review handoff labels.

## Response Discipline

Quality does not come from length. Initial plans and reviews may be detailed.
Fix loops, final summaries, and commit suggestions should stay compact.

Do not invent test results, file contents, repo facts, or validation outcomes.
If something was not read or not run, mark it as unread or not run and name the
open gate.

## Plan Document Format

Plan documents are read-only artifacts under `docs/`. If a plan is reviewed and
iterated, keep a version history with the concrete trigger for each version.

Required sections: Summary, Key Changes, Test Plan, Assumptions, First Reviewer
Brief. Optional sections: Subphases, ADR Updates, Architecture Lookahead, Open
Questions / Decisions Pending User.

The First Reviewer Brief must name concrete review tasks. Generic "please
review" is not enough.
