# SDD Workflow — Phase Contracts

Each phase: what it reads, what it produces, how it behaves, and what makes it done.

---

## Phase 0 — Bootstrap *(once per project)*

**Command** `/hexa:bootstrap`

Adapts the kit to the project it was copied into: base package, build tool, test commands,
database. Rewrites the placeholders in `.claude/constitution.md` §Project Variables.

**Done when** `.claude/constitution.md` names the project's real base package and real test
command, and `sh .claude/scripts/check-architecture.sh --all` runs without error.

---

## Phase 1 — Specify

**Command** `/hexa:specify <intent>`
**Reads** the user's intent; existing modules, to place the feature in the domain
**Writes** `docs/specs/NNN-slug/spec.md` (+ empty `plan.md`, `tasks.md`)

**Behaviour**

1. Run `sh .claude/scripts/new-feature.sh "<intent>"` to allocate the number and directory.
2. Fill the template from the intent. Write in the **user's vocabulary**, not the codebase's.
3. Every requirement gets an id (`FR-001`) and is phrased so a non-developer could test it.
4. Every business rule gets `BR-###`; every error case `ER-###`.
5. Fill §4 Domain Language before anything else — the terms chosen here become the class names
   two phases later, so a sloppy noun becomes a sloppy package.
6. Anything not stated by the user and not obvious becomes
   `[NEEDS CLARIFICATION: <specific question>]`. **Do not guess and do not silently default.**
7. §3 Out of Scope is mandatory and must not be empty.

**Forbidden in this phase:** class names, package names, annotations, framework names, table
names, HTTP verbs, library choices.

**Done when** the spec's own Exit Gate checklist passes.

---

## Phase 2 — Clarify

**Command** `/hexa:clarify`
**Reads** `spec.md`
**Writes** `spec.md` (§7–§11 updated, §12 Clarifications appended)

**Behaviour**

1. Collect every `[NEEDS CLARIFICATION]` marker, plus ambiguities found by re-reading:
   undefined terms, requirements with no acceptance criterion, missing error behaviour, absent
   authorization rules, unstated volume expectations.
2. Rank by **impact on the design** — a question that changes which ports exist outranks a
   question about a label.
3. Ask the user the top questions (at most five per round) with `AskUserQuestion`, offering
   concrete options with trade-offs rather than open prompts.
4. Apply each answer to the affected requirement **and** log it in §12 with the date, the
   question, the answer, and which requirement it changed.
5. Remove the resolved marker.
6. Repeat until no markers remain.

**Done when** `grep -c "NEEDS CLARIFICATION" spec.md` is 0 and §12 records every decision.

---

## Phase 3 — Plan

**Command** `/hexa:plan`
**Reads** `spec.md`, the existing codebase, `.claude/constitution.md`, the
`hexalayered-architecture` skill
**Writes** `docs/specs/NNN-slug/plan.md`

**Behaviour**

1. **Refuse to start** if `spec.md` still has open clarifications.
2. Survey the codebase: which modules exist, what `common` already provides, what conventions
   are in use. Reuse before inventing — an existing port or base class beats a new one.
3. Decide the **module map**: new module, or extend an existing one? A new module needs a
   distinct business capability, not just a new endpoint.
4. Fill §3 Layer Design completely — every type, its package, its access modifier, its input
   and output types. Work **outside-in** when designing (what does the client need? → what
   must the service promise? → what must the port provide?), even though implementation later
   goes inside-out.
5. Make the granularity decisions explicitly (README FAQ #13–#15) and record the reason:
   - split services by action, or one service?
   - one adapter per port, or one adapter over several ports?
6. Trace **every** FR through the layers in §4 Data Flow. An FR that cannot be traced means a
   missing port or service — find it now, on paper.
7. Complete §6 Constitution Check. Any non-PASS row is either fixed in the design or recorded
   as an ADR.
8. Do not write code in this phase. Signatures and tables only.

**Done when** every FR appears in §4, every type has a package and an access modifier, and §6
is all PASS or ADR-backed.

---

## Phase 4 — Tasks

**Command** `/hexa:tasks`
**Reads** `spec.md`, `plan.md`
**Writes** `docs/specs/NNN-slug/tasks.md`

**Behaviour**

1. Turn every type in `plan.md` §3 into a task with its **exact file path**.
2. Order **inside-out** — the dependency direction:
   `enums → domain → entity → mappers → repository → ports → adapter → exceptions →
   service interfaces → service impls → request/response → controller → e2e`.
3. Put the test **before** the implementation for each behavioural unit (adapter, service
   impl, controller). For pure data holders, put the builder first.
4. Mark `[P]` only when a task shares no file with any other unfinished task.
5. Reference the requirement each task serves.
6. Fill the Traceability table: every FR/BR/ER maps to at least one task, and every task maps
   to at least one requirement. A task serving nothing is scope creep; a requirement serving
   nothing is a hole.
7. End with the closure tasks: architecture check, full test run, `/hexa:analyze`.

**Done when** every FR is covered, every task names a path, and the order never places a type
before something it depends on.

---

## Phase 5 — Implement

**Command** `/hexa:implement [task-id]`
**Reads** `tasks.md`, `plan.md`, `spec.md`
**Writes** source code; updates `tasks.md` checkboxes

**Behaviour**

1. Work in task order. Do not jump ahead — a controller written before its service is a
   controller written against a guess.
2. Mark `[~]` when starting, `[x]` when done.
3. After **each phase** of `tasks.md`:
   - `sh .claude/scripts/check-architecture.sh --all` → must exit 0
   - compile / run the tests that exist so far → must be green
   Fix before moving on. A violation carried forward is a violation multiplied.
4. Follow `plan.md` exactly. If the plan turns out to be wrong, **stop, fix the plan, then
   continue** — do not quietly diverge, because the plan is what the next reader will trust.
5. Write the code the layer calls for: package-private implementations, mappers for every
   conversion, module exceptions, `given/when/then` tests with builders.
6. Report at the end: tasks completed, deviations from the plan (and why), what remains.

**Done when** every task is `[x]`, the checker exits 0, and the suite is green.

---

## Phase 6 — Analyze

**Command** `/hexa:analyze`
**Reads** all artifacts and the code
**Writes** a report — **changes nothing**

**Checks**

| Dimension | Question |
|---|---|
| Coverage | Does every FR/BR/ER have a task, and does that task's code exist? |
| Orphans | Is there a task, or a class, that no requirement asked for? |
| Drift | Does the code match `plan.md` §3 — same names, same packages, same visibility? |
| Constitution | Does `check-architecture.sh --all` pass? Do Articles III/VII/VIII/IX hold? |
| Terminology | Do `spec.md`, `plan.md` and the code use the same word for the same concept? |
| Tests | Does every controller, service impl and adapter have a test? Every BR a failing case? |

**Output** a severity table (HIGH / MEDIUM / LOW) with file references and a recommended fix
for each finding. Fixes nothing — that is a separate, deliberate step.

---

## Ongoing — Review

**Command** `/hexa:review [path]`

Not part of the loop; run it any time against existing code, including code written before the
kit arrived. Reports violations grouped by constitution article, each with the corrected form.
