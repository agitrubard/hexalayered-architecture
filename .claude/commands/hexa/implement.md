---
description: Execute the task list layer by layer, verifying after each phase
argument-hint: [task id, phase name, or feature directory — defaults to the next unfinished task]
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Skill, Agent
---

# /hexa:implement

Build the feature by working `tasks.md` in order, verifying after every phase.

You are in **Phase 5** of Spec Driven Development. Load the `hexalayered-architecture` skill
before writing any code.

## Locate the feature

```sh
sh .claude/scripts/new-feature.sh --current
```

Use `$ARGUMENTS` if the user named a task id, a phase, or a directory. Read `tasks.md`,
`plan.md` and — for the acceptance criteria — `spec.md`.

## Steps

1. **Find the next unfinished task.** Work in order. Do not jump ahead: a controller written
   before its service is a controller written against a guess.

2. **For each task:**
   - Mark it `[~]` in `tasks.md`.
   - Read the corresponding row in `plan.md` §3 — the package and access modifier are already
     decided there. Follow them exactly.
   - Write the file at the path the task names.
   - Mark it `[x]`.

3. **After each phase** of `tasks.md` — not only at the end:

   ```sh
   sh .claude/scripts/check-architecture.sh --all     # must exit 0
   {TEST_COMMAND}                                     # must be green
   ```

   Fix before moving on. A violation carried into the next phase is a violation multiplied
   across every class built on top of it.

4. **When the plan turns out to be wrong** — a missing port, a signature that cannot work —
   **stop. Fix `plan.md` first**, then the task, then write the code. Do not diverge silently:
   the plan is what the next reader will trust, and a plan that lies is worse than no plan.

5. **Write the code the layer calls for:**
   - `*Controller`, `*ServiceImpl`, `*Adapter` → package-private
   - `*Service`, `*Port`, `*Repository` → `public interface`
   - a mapper for every conversion; never hand-rolled field copying
   - business rules in the service or the domain model; input validation on the request
   - module exceptions extending the shared abstract types
   - tests named `given…_when…_then…`, data from `*Builder` classes

6. **Update the Progress table** in `tasks.md` as phases complete.

## Output

- tasks completed this run
- the result of the architecture check and the test run — **quote the actual output**; if
  something failed, say so with the failure
- any deviation from `plan.md`, and whether `plan.md` was updated
- what remains, and the next command

## Rules

- Never skip a layer, not even for a "trivial" read.
- Never mark a task `[x]` without its file existing and compiling.
- Never disable, skip or weaken a test to get to green.
- Never leave `TODO`, commented-out code, or debug logging behind.
- If the checker fails on the same article twice, the **design** is wrong, not the code —
  go back to `/hexa:plan`.
- Report failures honestly. A red test reported as green costs far more than the delay.
