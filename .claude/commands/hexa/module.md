---
description: Scaffold a complete new HexaLayered module — every layer, correctly packaged
argument-hint: <module name, e.g. ticket> [primary domain noun, e.g. Ticket]
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Skill, AskUserQuestion
---

# /hexa:module

Create a new feature module with every layer in place: **$ARGUMENTS**

Load the `hexalayered-architecture` skill and read
[`.claude/templates/module-blueprint.md`](../../templates/module-blueprint.md).

## Preconditions

- `$ARGUMENTS` names the module. If empty, ask for the module name and the primary domain noun.
- The module must be a **business capability** (`ticket`, `institution`, `notification`), not
  a technical grouping (`dto`, `util`, `core`, `api`). If the name is technical, say so and
  propose a capability-shaped alternative before creating anything.

## Steps

1. **Establish the parameters.**
   - `[module]` — the lowercase package segment, from `$ARGUMENTS`
   - `[Domain]` — the PascalCase noun (given, or derived from the module name)
   - `{BASE_PACKAGE}` — read from `.claude/constitution.md` §Project Variables; confirm it
     matches what is actually on disk under `{SOURCE_ROOT}`

2. **Check whether `common` exists.** If `{BASE_PACKAGE}.common` is absent, this is a new
   project: create `common` first (the layout is at the bottom of the blueprint) —
   `BaseDomainModel`, `BaseEntity`, `BaseMapper`, `SuccessResponse`, `ErrorResponse`, the
   abstract exceptions and `GlobalExceptionHandler`. Every module depends on these.

3. **Decide granularity before generating** (README FAQ #13–#15). Ask the user if it is not
   obvious from the domain:
   - one service per action (`[Domain]CreateService`, `[Domain]ReadService`, …), or a single
     `[Domain]Service`?
   - one adapter over several ports, or one adapter per port?

   Default for a fresh module: **one adapter implementing Read + Save ports**, and
   **services split per action**. Both are easy to collapse later; both are painful to split
   later.

4. **Create the package tree and the files**, inside-out, following the blueprint checklist:

   ```
   enums → domain model → entity → mappers → repository
        → ports → adapter → exceptions → services → request/response → controller
   ```

   Every file is real, compiling code — not an empty placeholder. A domain model with its
   fields, an entity with its columns, a repository extending `JpaRepository`, a controller
   with at least one endpoint. Where the user has not specified fields, generate a minimal,
   obviously-provisional set (`id`, `name`/`title`, `status`, audit) and say so in your report.

5. **Mirror the test tree**: builders for the domain model, entity and requests; a test class
   for the controller, each service impl and the adapter.

6. **Verify.**

   ```sh
   sh .claude/scripts/check-architecture.sh --all   # must exit 0
   {TEST_COMMAND}
   ```

## Output

- the file tree created, and the file count
- the granularity decisions taken, and why
- anything provisional the user must fill in (fields, endpoints, table columns)
- the architecture check result — quote it
- next step: `/hexa:specify` for the first real feature in this module

## Rules

- Every layer present. A module missing its port layer is not a HexaLayered module.
- `*Controller`, `*ServiceImpl`, `*Adapter` package-private; `*Service`, `*Port`,
  `*Repository` public interfaces.
- No `*Entity` above `port.adapter` / `model.mapper`.
- Mappers for every conversion, with the MapStruct `initialize()` pattern.
- Do not create a module that duplicates a capability an existing module already owns — say so
  and propose extending that module instead.
