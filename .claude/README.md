# HexaLayered SDD Kit

A drop-in `.claude/` directory that teaches Claude Code the
[HexaLayered Architecture](../README.md), drives **Spec Driven Development**, and
mechanically enforces the architecture as files are written.

Copy it into any Spring Boot project that should follow HexaLayered, run `/hexa:bootstrap`
once, and the architecture is wired in from the first commit.

---

## Install into a project

```sh
# from the root of your project
cp -r /path/to/hexalayered-architecture/.claude .
```

Then, in Claude Code:

```
/hexa:bootstrap
```

It detects your base package, build tool and test command, rewrites the kit's reference values
to match, creates `docs/specs/` and `docs/adr/`, and sets up a root `CLAUDE.md` (appending to
an existing one rather than overwriting it).

Restart Claude Code afterwards so the skills, commands and agents are picked up.

---

## What is in here

```
.claude/
├── constitution.md          the ten articles — the rules everything is checked against
├── settings.json            the enforcement hook + a read-only permission allowlist
│
├── commands/hexa/           the /hexa: workflow
├── agents/                  four subagents (analyst, architect, implementer, reviewer)
├── skills/                  the knowledge base, progressively disclosed
├── templates/               spec, plan, tasks, module blueprint, ADR
└── scripts/                 new-feature.sh, check-architecture.sh
```

---

## The workflow

```
/hexa:bootstrap     once, after copying the kit in
/hexa:module        scaffold a new module, all layers

/hexa:specify   →   docs/specs/NNN-slug/spec.md    WHAT & WHY
/hexa:clarify   →   spec.md                        ambiguities resolved and logged
/hexa:plan      →   plan.md                        HOW: modules, layers, classes, packages
/hexa:tasks     →   tasks.md                       ordered inside-out, test-first
/hexa:implement →   code                           one layer at a time, verified after each
/hexa:analyze   →   report                         spec ↔ plan ↔ tasks ↔ code

/hexa:review        audit any existing code against the constitution
```

**New project, from zero:**

```
/hexa:bootstrap
/hexa:module common
/hexa:module ticket
/hexa:specify agents can close a ticket with a reason
/hexa:clarify
/hexa:plan
/hexa:tasks
/hexa:implement
```

**Existing project:** `/hexa:bootstrap` → `/hexa:review` to see where it stands, then use the
loop for new features.

---

## Enforcement

`.claude/settings.json` registers a `PostToolUse` hook. After every `Write`, `Edit` or
`MultiEdit`, `scripts/check-architecture.sh` runs against the changed file. On a violation it
exits `2`, and the report goes straight back to Claude to be fixed — the mistake never reaches
review.

What it checks mechanically:

| Article | Check |
|---|---|
| I | repositories and implementations are not reached past their layer; no upward imports |
| II | `*Entity` does not appear above `port.adapter` / `model.mapper` |
| IV | `*Controller` / `*ServiceImpl` / `*Adapter` package-private; `*Port` / `*Service` / `*Repository` public interfaces |
| V | every class sits in the package its suffix demands, and its package statement matches its path |
| VI | no module reaches into another module's internals |

Articles III, VII, VIII, IX and X are judgement calls — `/hexa:review` and the
`hexa-architecture-reviewer` agent cover those.

Run it yourself any time:

```sh
sh .claude/scripts/check-architecture.sh --all
sh .claude/scripts/check-architecture.sh src/main/java/com/acme/ticket/service/impl/TicketCreateServiceImpl.java
```

It **fails open**: no `src/main/java`, or an unparseable file, means exit 0. It never blocks a
non-Java project.

### Turning enforcement down

Prefer advisory-only? Delete the `hooks` block from `.claude/settings.json`. The script stays
usable on demand and `/hexa:review` still works.

---

## Customising

| Want to change | Edit |
|---|---|
| the rules themselves | `constitution.md` — the single source; everything else defers to it |
| project package, build tool, test command | `constitution.md` §Project Variables (or re-run `/hexa:bootstrap`) |
| where specs live | `HEXA_SPECS_DIR` env var, or `scripts/new-feature.sh` |
| what the checker enforces | `scripts/check-architecture.sh` — one `case` block per rule |
| the artifact shapes | `templates/*.md` |
| command behaviour | `commands/hexa/*.md` |

If your project deviates from an article deliberately, record it as an ADR in `docs/adr/`
using `templates/adr.md` — an undocumented deviation is a violation, not a decision.

---

## Requirements

- Claude Code with project `.claude/` support
- POSIX `sh`, `grep`, `sed`, `find` (the scripts have no other dependencies)
- Spring Boot / Java for the architecture checks; the SDD workflow itself is
  language-agnostic

---

## Grounding

The rules come from [`README.md`](../README.md) of this repository — layers, naming
conventions, best practices and the FAQ — cross-checked against the reference implementation
the README cites, [afet-yonetim-sistemi/ays-be](https://github.com/afet-yonetim-sistemi/ays-be).
Where this kit and `README.md` disagree, `README.md` wins and the kit is the bug.
