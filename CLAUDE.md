# HexaLayered Architecture — Repository Guide

This repository **defines** HexaLayered Architecture. It contains no application code.

| Path | What it is |
|---|---|
| `README.md` | the architecture itself — layers, naming, best practices, FAQ. **The source of truth.** |
| `documents/readmes/tr/README.md` | the Turkish translation; keep in sync with `README.md` |
| `documents/architecture/` | the diagram (`.drawio` source + exported `.png`) |
| `.claude/` | the **SDD kit**: a drop-in toolkit that teaches the architecture to Claude Code and enforces it |
| `docs/specs/` | Spec Driven Development artifacts, when this repo's own work uses them |

## Working on the architecture docs

`README.md` is the source of truth. When it changes:

1. Mirror the change in `documents/readmes/tr/README.md`.
2. Check `.claude/constitution.md` and `.claude/skills/hexalayered-architecture/` — the kit
   restates these rules, and a divergence there is a bug in the kit.

## Working on the SDD kit

The kit is boilerplate: teams copy `.claude/` into their own Spring Boot projects and run
`/hexa:bootstrap`. So changes must stay **project-agnostic** — no assumption about a base
package, a build tool, or a module that only exists here.

`.claude/README.md` explains the kit's structure and how it is installed.

Rules hierarchy inside the kit:

```
README.md  →  .claude/constitution.md  →  skills/  →  commands/, agents/, templates/
(authority)     (testable restatement)    (how-to)     (workflow)
```

If the kit and `README.md` disagree, `README.md` wins.

## Verifying a kit change

```sh
sh -n .claude/scripts/check-architecture.sh
sh -n .claude/scripts/new-feature.sh
python3 -m json.tool .claude/settings.json > /dev/null
sh .claude/scripts/check-architecture.sh --all      # exits 0 here: no src/main/java
```

The checker is designed to **fail open** — in a repository with no Java sources it must exit 0
and say nothing.

## Conventions

- Markdown wraps at ~120 characters, matching the existing files.
- Commit messages in this repository are sentence-style and describe the outcome
  (`Support Section Has Been Added to README.md File`).
- Do not add a build system, dependencies, or application code — this repository is
  documentation plus the kit.
