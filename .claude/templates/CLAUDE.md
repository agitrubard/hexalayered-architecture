# {{PROJECT_NAME}}

<!--
  Installed by /hexa:bootstrap from .claude/templates/CLAUDE.md
  Keep this file thin. The rules live in .claude/ — this only points at them.
-->

This project follows **HexaLayered Architecture** (Hexagonal + Layered) and **Spec Driven
Development**. Both are defined in `.claude/`.

@.claude/constitution.md

## Before writing any Java

Load the `hexalayered-architecture` skill. The five rules that prevent most mistakes:

1. **Entities never go above the adapter.** Above it, the currency is the domain model.
2. **Every layer crossing goes through an interface** — even with one implementation.
3. **Implementations are package-private** (`*Controller`, `*ServiceImpl`, `*Adapter`);
   contracts are public (`*Service`, `*Port`, `*Repository`).
4. **Names are mechanical.** The suffix determines the package, and vice versa.
5. **Modules are vertical slices.** Module A touches module B only through B's public Service
   or Port interfaces.

Flow: `Controller → Service → ServiceImpl → Port → Adapter → Repository`. No layer is skipped,
in either direction.

## Before starting a feature

Load the `spec-driven-development` skill.

```
/hexa:specify → /hexa:clarify → /hexa:plan → /hexa:tasks → /hexa:implement → /hexa:analyze
```

Artifacts land in `docs/specs/<NNN-slug>/`. Small changes may skip to implementation — but
never skip the architecture rules.

## Commands

| | |
|---|---|
| `/hexa:module <name>` | scaffold a new module, all layers |
| `/hexa:review [path]` | audit code against the constitution |
| `/hexa:analyze` | check spec ↔ plan ↔ tasks ↔ code consistency |

## Verification

```sh
sh .claude/scripts/check-architecture.sh --all     # must exit 0
{{TEST_COMMAND}}
```

The architecture check also runs automatically after every file write, via the `PostToolUse`
hook in `.claude/settings.json`.

## Project facts

| | |
|---|---|
| Base package | `{{BASE_PACKAGE}}` |
| Build tool | `{{BUILD_TOOL}}` |
| Test command | `{{TEST_COMMAND}}` |
| Modules | `{{MODULES}}` |

<!-- Add project-specific conventions below. They take precedence over the kit's examples. -->
