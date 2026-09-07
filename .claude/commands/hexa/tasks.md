---
description: Break the plan into an ordered, file-precise, test-first task list
argument-hint: [feature directory — defaults to the most recent]
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Skill
---

# /hexa:tasks

Turn the plan into an executable task list — ordered so that nothing is ever built before what
it depends on.

You are in **Phase 4** of Spec Driven Development.

## Locate the feature

```sh
sh .claude/scripts/new-feature.sh --current
```

Use `$ARGUMENTS` if the user named a directory. Read `spec.md` and `plan.md` in full.

## Precondition

`plan.md` §6 Constitution Check must be all PASS (or ADR-backed), and every type in §3 must
have a package and an access modifier. If not, stop and send the user back to `/hexa:plan`.

## Steps

1. **One task per type** in `plan.md` §3, each with its **exact file path**. A task without a
   path is not a task.

2. **Order inside-out.** This is the direction the dependencies point, so it is the only order
   in which each task can actually be finished:

   ```
   1  enums                 model/enums/
   2  domain model          model/
   3  entity                model/entity/
   4  mappers               model/mapper/
   5  repository            repository/
   6  port interfaces       port/
   7  adapter               port/adapter/
   8  exceptions            exception/
   9  service interfaces    service/
   10 service impls         service/impl/
   11 request / response    model/request/, model/response/
   12 controller            controller/
   13 end-to-end test
   14 migration, docs
   ```

3. **Test before implementation** for every behavioural unit — adapter, service impl,
   controller. The test is where the shape of the class gets decided. For pure data holders,
   the test **builder** comes first instead.

4. **Mark `[P]`** only when a task shares no file with any other unfinished task. Two tasks in
   the same file are never both `[P]`.

5. **Reference the requirement** each task serves (`FR-001`, `BR-002`, `ER-001`).

6. **Fill the Traceability table.** Every FR, BR and ER maps to ≥1 task; every task maps to
   ≥1 requirement. A task serving no requirement is scope creep — delete it. A requirement
   with no task is a hole — fill it.

7. **End with the closure tasks:**
   - `sh .claude/scripts/check-architecture.sh --all` exits 0
   - the full test suite is green
   - `/hexa:analyze` reports no HIGH findings

8. Keep tasks **small enough to verify**: one file, or one file plus its test. "Implement the
   ticket module" is not a task.

## Output

- total task count, and the count per phase
- how many are `[P]`
- any requirement that could not be mapped to a task (this is a blocker, say so plainly)
- next step: `/hexa:implement`

## Rules

- Every task: exact file path + the requirement it serves.
- Never place a task before something it depends on. The order **is** the contract.
- Do not invent work the plan does not call for.
- Do not merge "write the test" and "write the class" into one task — the test comes first and
  is checked off first.
