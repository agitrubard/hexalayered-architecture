# Quality Gates

A gate is a checklist that must fully pass before the next phase starts. A failed gate is
never a reason to lower the gate — it is a reason to go back one phase.

---

## Gate 1 — Specify → Clarify

**Completeness**
- [ ] §1 Problem states who feels the pain and what it costs.
- [ ] §2 Goal describes an observable end state, not an implementation.
- [ ] §3 Out of Scope is **not empty**.
- [ ] §4 Domain Language defines every term the spec uses in a special sense.
- [ ] §5 Domain Concepts lists every thing the feature touches, with its lifecycle.
- [ ] Every scenario has ≥1 Given/When/Then acceptance criterion.
- [ ] Every FR has an id and a priority.
- [ ] §8 Business Rules and §9 Error Cases are filled, or explicitly marked "none".
- [ ] §10 names the authorization rule — *who* may do this.

**Purity — the spec describes WHAT, not HOW**
- [ ] No class or interface name.
- [ ] No package name.
- [ ] No annotation (`@RestController`, `@Entity`, …).
- [ ] No table or column name.
- [ ] No framework or library name.
- [ ] No HTTP method or path.

*Quick check:* `grep -nE '@[A-Z]|Controller|Service|Repository|Entity|Port|Adapter|\bpackage\b|POST |GET ' spec.md`
should return nothing but prose.

**Testability**
- [ ] Every FR could be verified by someone who cannot read the code.
- [ ] No requirement contains "fast", "user-friendly", "robust", "appropriate", "etc."
      without a number or a definition.

---

## Gate 2 — Clarify → Plan

- [ ] Zero `[NEEDS CLARIFICATION]` markers remain (`grep -c` returns 0).
- [ ] Every answer is logged in §12 with date, question, answer, and the requirement it
      changed.
- [ ] No answer was invented — each came from the user or from an explicit, stated
      project convention.
- [ ] Requirements changed by an answer were actually rewritten, not just annotated.

---

## Gate 3 — Plan → Tasks

**Design completeness**
- [ ] §2 Module Map names every module involved and says new or existing.
- [ ] Every cross-module dependency goes through a **public Service or Port** and is
      justified.
- [ ] §3 lists every type with: package, access modifier, and its input/output types.
- [ ] Ports speak the domain — no `*Entity` in any port signature.
- [ ] Both granularity decisions (service split, adapter split) are stated **with a reason**.
- [ ] Exceptions are listed with their base class and HTTP status.
- [ ] §5 covers schema changes and the migration file.

**Traceability**
- [ ] Every FR from `spec.md` appears in §4 Data Flow.
- [ ] Every business rule names the layer that enforces it.
- [ ] No type in §3 lacks a caller in §4 — an unreachable class is a design leftover.

**Constitution Check — all must be PASS or ADR-backed**
- [ ] I — no layer skipped, no upward dependency.
- [ ] II — no `*Entity` above `port.adapter` / `model.mapper`.
- [ ] III — every Service and Port has an interface.
- [ ] IV — `*Controller`, `*ServiceImpl`, `*Adapter` package-private; contracts public.
- [ ] V — every type matches the naming table.
- [ ] VI — cross-module access only through public Service/Port.
- [ ] VII — a mapper exists for every conversion.
- [ ] VIII — input validation on requests, business rules in services.
- [ ] IX — a test is planned for every controller, service impl and adapter.

- [ ] Every deviation has an ADR in `docs/adr/` linked from §6.

---

## Gate 4 — Tasks → Implement

- [ ] Every task names an **exact file path**.
- [ ] Every task references the requirement it serves.
- [ ] Order is inside-out; no task depends on a later task.
- [ ] Tests precede implementations for adapters, service impls and controllers.
- [ ] `[P]` appears only where no file is shared with another unfinished task.
- [ ] The Traceability table covers every FR, BR and ER.
- [ ] No task exists that no requirement asked for.
- [ ] Closure tasks are present: architecture check, full test run, `/hexa:analyze`.

---

## Gate 5 — Implement → Done

**After every phase of `tasks.md`, not only at the end:**
- [ ] `sh .claude/scripts/check-architecture.sh --all` exits 0.
- [ ] Everything compiles.
- [ ] All existing tests pass.

**At the end:**
- [ ] Every task is `[x]`.
- [ ] Every acceptance criterion in `spec.md` has a test that exercises it.
- [ ] Every business rule has a test that fails if the rule is removed.
- [ ] Every error case asserts its exception type or HTTP status.
- [ ] The code matches `plan.md` §3 — same names, same packages, same visibility.
- [ ] Deviations from the plan were written back into `plan.md`, with the reason.
- [ ] No `TODO`, no commented-out code, no debug logging left behind.
- [ ] The migration script runs on a clean database.

---

## Red flags — stop and go back a phase

| Symptom | What it actually means | Go back to |
|---|---|---|
| "Which package does this go in?" during implementation | the plan is incomplete | plan |
| A class appears that is in no task | the plan or the tasks are incomplete | plan |
| A requirement has no test | the tasks missed it | tasks |
| The checker fails repeatedly on the same article | the design violates the constitution | plan |
| A term means two different things in two files | §4 Domain Language was skipped | specify |
| "We will figure it out while coding" | an unresolved clarification | clarify |
| A task cannot be done without doing a later task first | the ordering is wrong | tasks |
