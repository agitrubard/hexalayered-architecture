---
description: Design the HexaLayered implementation — modules, layers, classes, packages, visibility
argument-hint: [feature directory — defaults to the most recent]
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Skill, Agent
---

# /hexa:plan

Turn the specification into a layer-by-layer design, so that every class's name, package and
visibility is decided **before** a file is created.

You are in **Phase 3** of Spec Driven Development. Load both skills before you start:
`spec-driven-development` and `hexalayered-architecture`. Read
[`.claude/constitution.md`](../../constitution.md).

## Locate the feature

```sh
sh .claude/scripts/new-feature.sh --current
```

Use `$ARGUMENTS` if the user named a directory. Read `spec.md` in full.

## Precondition — refuse to proceed on an unclear spec

```sh
grep -c "NEEDS CLARIFICATION" <SPEC_FILE>
```

If this is not 0, stop and tell the user to run `/hexa:clarify` first. Planning against
unresolved ambiguity produces a design that has to be thrown away.

## Steps

1. **Survey the codebase before designing.**
   - Which modules exist? `ls {SOURCE_ROOT}/**/`
   - What does `common` already provide — base classes, response envelopes, mappers, utils?
   - What conventions are actually in use here (they win over any example in this kit)?
   - Is there already a port or service that does most of this?

   **Reuse beats invention.** An existing port, base class or util that fits is always the
   better answer than a new one.

2. **Decide the module map** (§2 of the template).
   - Extend an existing module, or create a new one? A new module needs a distinct **business
     capability** — not just a new endpoint.
   - List every cross-module dependency and the **public Service or Port** it goes through.
     If the other module exposes nothing suitable, the plan is to *add* a port to it — never
     to reach around it (Article VI).

3. **Design outside-in, one module at a time** (§3).

   Think in this order — what the client needs, then what must be promised to satisfy it:

   ```
   endpoint & response  →  what must the Service promise?
                        →  what must the Port provide?
                        →  what must the Repository query?
   ```

   (Implementation later goes the other way, inside-out. Design outside-in, build inside-out.)

   Fill every table completely. **Access modifier is not optional** — it is Article IV:
   `*Controller`, `*ServiceImpl`, `*Adapter` are package-private; `*Service`, `*Port`,
   `*Repository` are public interfaces.

   Check as you go:
   - No `*Entity` appears in any port or service signature (Article II).
   - Every conversion has a named mapper (Article VII).
   - Every type's package matches its suffix (Article V).

4. **Make the granularity calls explicitly**, with the reason written down (README FAQ
   #13–#15):
   - Split services per action, or one service? *(overlap, size, change rate, consistency)*
   - One adapter per port, or one adapter over several ports? *(same system? same caching?
     same transaction shape?)*

5. **Trace every FR through the layers** (§4). Write the call chain from HTTP down to the
   repository and back. An FR you cannot trace means a missing port or service — find it here,
   on paper, not three hours into implementation.

6. **Complete §6 Constitution Check.** Every row PASS. A row that cannot be PASS is either a
   design flaw to fix now, or a deliberate deviation — in which case write an ADR from
   [`.claude/templates/adr.md`](../../templates/adr.md) into `docs/adr/` and link it.

7. For a feature spanning **more than two modules**, delegate the design to the
   `hexa-architect` agent and integrate its result — that is what it is for.

## Output

- the module map in one line
- a count: N new classes across M modules
- the granularity decisions and their reasons
- the Constitution Check result, and any ADR written
- next step: `/hexa:tasks`

## Rules

- **No code in this phase.** Signatures, tables and call chains only.
- Every type gets a package **and** an access modifier. A blank cell is an unfinished plan.
- Do not introduce a class that has no caller in §4.
- Do not plan a shortcut through a layer "because it is only a read".
- If the spec is ambiguous about something that changes the design, stop and go back to
  `/hexa:clarify` — do not resolve it silently in the plan.
