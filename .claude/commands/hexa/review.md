---
description: Audit existing code against the HexaLayered constitution and report violations
argument-hint: [path, module name, or nothing for the current diff]
allowed-tools: Bash, Read, Glob, Grep, Skill, Agent
---

# /hexa:review

Audit code against [`.claude/constitution.md`](../../constitution.md).

**Read-only.** Report violations with their fixes; do not apply them unless the user asks in a
follow-up.

## Scope

- `$ARGUMENTS` is a path or module name → review that.
- `$ARGUMENTS` is empty → review the current diff:

  ```sh
  git diff --name-only HEAD
  git diff --name-only --cached
  ```

  If the working tree is clean, review the most recent commit's files. Say which scope you
  chose.

## Steps

1. **Run the mechanical checks first.**

   ```sh
   sh .claude/scripts/check-architecture.sh --all      # or: <paths...>
   ```

   This covers Articles I, II, IV, V and VI. Take its output as findings, verified.

2. **Read the code for what the script cannot see.** Load the `hexalayered-architecture` skill
   and use [`references/anti-patterns.md`](../../skills/hexalayered-architecture/references/anti-patterns.md)
   as the checklist:

   | Article | Look for |
   |---|---|
   | I | a layer skipped; an upward dependency; a controller with a port field |
   | II | an entity or a `Page<*Entity>` returned above the adapter |
   | III | a `@Service` class with no interface; a port with no interface |
   | IV | a public `*Impl`, `*Adapter` or `*Controller`; a non-public `*Port`/`*Service` |
   | V | `Manager`/`Helper`/`Processor`; a verb that is not the bare form; a class in the wrong package |
   | VI | an import of another module's `repository`, `entity`, `service.impl` or `port.adapter` |
   | VII | hand-rolled field copying; mapping logic inside a service or controller |
   | VIII | business rules in a controller; a validator that needs a database; `@Transactional` on a controller; a `try/catch` around a domain exception |
   | IX | a service impl, adapter or controller with no test; a test named `test1`; a business rule with no failing case |

   Also look for the anemic-model smell: a service that reads a field, decides, and writes the
   field back — behaviour that belongs on the domain model.

3. **Verify before reporting.** Open the file and confirm each finding. A false positive costs
   more trust than a missed nit.

4. For a large review (a whole module or more), delegate to the `hexa-architecture-reviewer`
   agent and integrate its findings.

## Output

Group by article, most severe first:

```markdown
## Article II — Entity Containment · 2 violations

### 1. `TicketEntity` returned from a service
`src/main/java/.../ticket/service/impl/TicketReadServiceImpl.java:34`

    public TicketEntity findById(Long id) { ... }

**Why it matters.** A schema change now propagates into the service, the controller and the
API response.

**Fix.** Have `TicketReadPort` return `Optional<Ticket>`, map entity → domain inside
`TicketAdapter`, and return `Ticket` here.
```

End with a summary table:

| Article | Violations | Severity |
|---|---|---|
| II — Entity Containment | 2 | HIGH |
| IX — Test Contract | 5 | MEDIUM |

Then: the single highest-leverage fix, and whether the user wants them applied.

## Rules

- Cite `file:line` for every finding.
- Never report a finding you have not read the file to confirm.
- Distinguish a **violation** (breaks an article) from a **suggestion** (would be nicer).
- If the code is clean, say so in one line. Do not manufacture findings.
- A documented ADR deviation is not a violation — check `docs/adr/` before flagging one.
