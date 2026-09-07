---
description: Check consistency across spec, plan, tasks and code — reports findings, changes nothing
argument-hint: [feature directory — defaults to the most recent]
allowed-tools: Bash, Read, Glob, Grep, Skill, Agent
---

# /hexa:analyze

Audit the feature end to end: does the code do what the spec asked, the way the plan said?

**This command is read-only.** It reports; it does not fix. Fixing is a separate, deliberate
step the user decides on.

## Locate the feature

```sh
sh .claude/scripts/new-feature.sh --current
```

Use `$ARGUMENTS` if the user named a directory. Read `spec.md`, `plan.md` and `tasks.md`.

## Checks

### 1. Requirement coverage
For every `FR-###`, `BR-###` and `ER-###` in `spec.md`: is there a task, is that task `[x]`,
and does the code it names exist? List anything unmapped.

### 2. Orphans
Any task, class or endpoint that no requirement asked for. Scope creep is as much a defect as
a missing feature — it is code nobody agreed to maintain.

### 3. Design drift
Compare `plan.md` §3 against what is on disk: same class names, same packages, same access
modifiers, same method signatures. Where they differ, say which one is wrong — the code that
drifted, or the plan that was never updated.

### 4. Constitution compliance

```sh
sh .claude/scripts/check-architecture.sh --all
```

That covers Articles I, II, IV, V and VI mechanically. Then check by reading, since the script
cannot:

- **III** — does every service and port have an interface?
- **VII** — is every conversion in a mapper, with no hand-rolled field copying?
- **VIII** — input validation on requests, business rules in services, no domain `try/catch`
  in controllers, `@Transactional` at the right level?
- **IX** — does every controller, service impl and adapter have a test? Does every `BR-###`
  have a test that would fail if the rule were removed?

### 5. Terminology drift
Does `spec.md` §4 Domain Language, `plan.md` and the code use the same word for the same
concept? A concept with two names is a bug waiting to be written.

### 6. Test quality
- Method names follow `given…_when…_then…`.
- Test data comes from builders, not scattered literals.
- Negative paths assert the exception type or HTTP status, and verify the collaborator was
  *not* called.
- No test asserts a mock's own return value.

## Output

A severity table, most severe first:

| # | Severity | Dimension | Finding | Location | Recommended fix |
|---|---|---|---|---|---|
| 1 | HIGH | Constitution II | `TicketEntity` imported in a service impl | `…/TicketReadServiceImpl.java:12` | return `Ticket` from the port; map in the adapter |

- **HIGH** — a constitution violation, a missing requirement, or an untested business rule.
- **MEDIUM** — design drift, a missing test, terminology inconsistency.
- **LOW** — a naming nit, a missing doc comment.

Then a one-paragraph verdict: is this feature done, and if not, what is the shortest path to
done.

## Rules

- Change nothing. No edits, no writes, not even a typo fix.
- Every finding cites `file:line`.
- Do not report a finding you have not verified by reading the file.
- If everything passes, say so plainly and briefly — do not manufacture findings to look
  thorough.
