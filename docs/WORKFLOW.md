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

## UseCase Pre-Clarification

Before drafting a plan for a symptom (FPS drop, visible bug, felt performance
issue, awkward UX), name the underlying use case explicitly:

- Which concrete user activity or workflow produces the symptom?
- What breaks for the user if the symptom remains, and what breaks if the
  symptom is hidden by a workaround instead of fixed at the source?
- Which architectural options exist, and on what grounds is each accepted or
  deferred?

Quality Gates and acceptance checks then commit to the use case, not only to
the symptom. A workaround is acceptable only when the architectural option
has been evaluated and explicitly deferred with a concrete re-evaluation
trigger. A fired ADR re-evaluation trigger is itself a strong signal that the
workaround tier is exhausted and the architectural option is now due.

## Plan Value Binding

Parameter values stated in a plan are binding for the implementation of that
slice. This includes defaults, thresholds, gates, limits, sample sizes, timing
budgets, quality dimensions, and tradeoff boundaries.

Plan claims about repo state must also be verified before they are used. This
includes existing files, existing sections, previous content, current behavior,
and current diffs. If a claim was not verified, mark it explicitly as an
assumption.

If a plan value or repo-state claim turns out to be wrong during
implementation, do not change it silently. Revise the plan, add an ADR, or ask
for an explicit user decision.

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
When the slice has Quality Gates, the review request should reference the
plan's acceptance checks directly. Reviewers verify these checks first, then
raise additional concerns.

## Post-Implementation Evaluation Check

After implementing code, decide whether another agent should evaluate the
result. Use an evaluation prompt when the change is bug-prone, touches runtime
behavior, performance, rendering, simulation rules, persistent state,
cross-layer contracts, tests, or user-facing output.

If evaluation is useful, include a concrete evaluation prompt in the completion
report. It should name the goal, changed files or subsystems, quality gates,
validation already run, known risks, and exact questions for the reviewer. If
evaluation is not useful, state why briefly.

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

When external reviews were used, the completion report must list each finding's
disposition: `accept`, `reject`, `defer`, or `document`.

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

Plan documents are read-only artifacts, typically under `docs/`. Plans may live
externally or in the repo; if a plan is reviewed, iterated, or reused across
sessions, keep a versioned copy under `docs/` with the concrete trigger for
each version.

Required sections: Summary, Key Changes, Test Plan, Assumptions, First Reviewer
Brief. Optional sections: Subphases, ADR Updates, Architecture Lookahead, Open
Questions / Decisions Pending User.

The First Reviewer Brief must name concrete review tasks. Generic "please
review" is not enough.

## Quality Gates For System Slices

Before implementing a non-trivial system slice, create a plan document that
defines the system's relevant quality dimensions, likely failure modes,
acceptance checks, and tradeoff boundaries. Do this even when the slice appears
technically simple; the plan does not have to be a repo file unless it is
reviewed, iterated, or reused across sessions.

A slice is non-trivial when it touches one or more of: new subsystems, runtime
behavior, user-facing output, persistent state, performance characteristics, or
cross-layer interfaces. When in doubt, treat it as non-trivial.

The plan must name:

- Functional goal: what must work.
- Quality dimensions in scope: qualities the slice commits to. Common examples
  are performance, correctness, debuggability, visual clarity, UX, determinism,
  maintainability, extensibility, testability, and observability.
- Quality dimensions out of scope: qualities intentionally deferred.
- Known failure modes: predictable problems for this kind of system.
- Acceptance checks: concrete observable conditions, manual or automated.
- Tradeoff boundaries: which qualities may be sacrificed, and which may not.

If a quality issue appears during implementation, fix it inside the slice when
it is low-risk and coherent. Otherwise record it as a finding with a trigger
before dependent work continues. Quality dimensions and tradeoff boundaries
follow Plan Value Binding; they are binding, not advisory.
