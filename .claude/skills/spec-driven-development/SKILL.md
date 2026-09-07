---
name: spec-driven-development
description: The Spec Driven Development workflow for HexaLayered projects — turning an intent into spec.md, then plan.md, then tasks.md, then code, with a quality gate between each phase. Use when starting a new feature or module, when asked to write or review a specification, plan or task list, when running any /hexa: command, when unsure which SDD phase the work is in, or when deciding whether a feature is specified well enough to implement.
---

# Spec Driven Development

Write down *what* before *how*, and *how* before *code*. In a HexaLayered project this matters
more than usual: the decision about which module, which ports and which services a feature
needs is made once — and if it is made while typing, files land in the wrong packages and the
architecture erodes from the first commit.

Architecture rules: [`.claude/constitution.md`](../../constitution.md) and the
[`hexalayered-architecture`](../hexalayered-architecture/SKILL.md) skill.

---

## The loop

```
  intent
    │
    ▼
 /hexa:specify   →  docs/specs/NNN-slug/spec.md    WHAT & WHY   (no code vocabulary)
    │
    ▼
 /hexa:clarify   →  spec.md updated                ambiguities resolved & logged
    │
    ▼
 /hexa:plan      →  plan.md                        HOW: modules, layers, classes, packages
    │                                              + Constitution Check gate
    ▼
 /hexa:tasks     →  tasks.md                       ordered inside-out, test-first, file-precise
    │
    ▼
 /hexa:implement →  source code                    one layer at a time, verified after each
    │
    ▼
 /hexa:analyze   →  consistency report             spec ↔ plan ↔ tasks ↔ code
```

Artifacts live in `docs/specs/<NNN-feature-slug>/`. They are reviewed like code, because they
are the record of why the code looks the way it does.

---

## What belongs in which artifact

The single most common failure is leaking *how* into the spec. Use this table.

| | `spec.md` | `plan.md` | `tasks.md` |
|---|---|---|---|
| Business problem, user scenarios | ✅ | | |
| Acceptance criteria (Given/When/Then) | ✅ | | |
| Functional requirements `FR-###` | ✅ | referenced | referenced |
| Business rules `BR-###`, error cases `ER-###` | ✅ | referenced | referenced |
| Domain concepts & vocabulary | ✅ | | |
| Class names, packages, access modifiers | ❌ | ✅ | ✅ |
| Which module, which ports, which services | ❌ | ✅ | |
| Endpoint paths, request/response shapes | ❌ | ✅ | |
| Database tables, columns, migrations | ❌ | ✅ | ✅ |
| Exact file paths to create | ❌ | | ✅ |
| Order of work, parallelism | ❌ | | ✅ |

If `spec.md` contains the word `@RestController`, a package name, or a table name, it is not a
spec yet — that content belongs in `plan.md`.

---

## Gates

Each phase has an exit gate. Do not start the next phase while the current gate is open — see
[`references/quality-gates.md`](references/quality-gates.md) for the full checklists.

| Phase | Cannot proceed until |
|---|---|
| specify | every FR is testable, Out of Scope is non-empty, no implementation vocabulary |
| clarify | zero `[NEEDS CLARIFICATION]` markers remain |
| plan | every type has a package **and** an access modifier; Constitution Check all PASS |
| tasks | every FR maps to ≥1 task; every task names a file path; order is inside-out |
| implement | the checker exits 0 and the tests are green after **each** phase, not just at the end |

A gate that is failed is not a reason to lower the gate. It is a reason to go back one phase.

---

## Scaling to the work

Not everything needs the full loop.

| Change | Do this |
|---|---|
| Typo, log line, comment | just do it |
| Add a field to an existing request + response | skip to implementation; obey Articles I–IX |
| New endpoint on an existing module | `/hexa:plan` → `/hexa:tasks` → `/hexa:implement` |
| New capability, new ports/services | the full loop |
| New module | `/hexa:specify` … `/hexa:module` … `/hexa:implement` |
| New project | `/hexa:bootstrap` → `/hexa:module common` → `/hexa:module <first>` |

The rule that never scales down: **no code is written before it is known which package it goes
in.**

---

## Working with the artifacts

- **Amending a spec mid-implementation** is normal — requirements change. Update `spec.md`,
  then re-run `/hexa:plan` for the affected part, then `/hexa:tasks`. Do not patch code and
  leave the spec describing a system that no longer exists.
- **A task that turns out to be wrong** is a signal the plan was wrong. Fix `plan.md`, then the
  task, then the code — in that order.
- **A deliberate deviation from the constitution** is recorded as an ADR
  ([`.claude/templates/adr.md`](../../templates/adr.md)) and linked from `plan.md` §6. An
  undocumented deviation is a violation, not a decision.

---

## More detail

| | |
|---|---|
| Phase-by-phase contract, inputs and outputs | [`references/workflow.md`](references/workflow.md) |
| The full gate checklists | [`references/quality-gates.md`](references/quality-gates.md) |
| Artifact templates | [`.claude/templates/`](../../templates/) |
