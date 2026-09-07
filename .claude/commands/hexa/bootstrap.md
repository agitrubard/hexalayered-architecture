---
description: Adapt this SDD kit to the project it was copied into — run once, first
argument-hint: [base package, e.g. com.acme.orders]
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Skill
---

# /hexa:bootstrap

One-time setup after copying `.claude/` into a project. Replaces the kit's reference values
with this project's real ones, so every later command generates code that actually fits here.

## Steps

1. **Detect what you can, before asking anything.**

   ```sh
   ls pom.xml build.gradle build.gradle.kts settings.gradle 2>/dev/null
   find src/main/java -maxdepth 4 -type d 2>/dev/null | head -20
   ls src/main/resources/application*.yml src/main/resources/application*.properties 2>/dev/null
   ```

   - **Base package** — the deepest directory under `src/main/java` shared by everything, or
     `$ARGUMENTS` if given.
   - **Build tool** — `pom.xml` → Maven (`./mvnw test`); `build.gradle*` → Gradle
     (`./gradlew test`).
   - **Existing modules** — the directories directly under the base package.
   - **Database** — from the datasource config.

2. **Ask only what you could not detect**, with `AskUserQuestion`. If everything was detected,
   confirm it in one summary and proceed — do not interrogate the user about facts already on
   disk.

   Worth asking when unclear:
   - base package, if the tree is ambiguous or empty
   - the test command, if it is not the wrapper default
   - whether a lint/format check should run as part of verification
   - whether MapStruct and Lombok are available (they shape every generated mapper and model)

3. **Update `.claude/constitution.md` §Project Variables** with the real values:
   `BASE_PACKAGE`, `SOURCE_ROOT`, `TEST_ROOT`, `BUILD_TOOL`, `TEST_COMMAND`,
   `SINGLE_TEST_COMMAND`, `LINT_COMMAND`.

4. **Replace the reference package** across the kit. The kit ships with
   `dev.agitrubard.hexalayered` in its examples; make the examples match this project:

   ```sh
   grep -rl 'dev\.agitrubard\.hexalayered' .claude/ | while IFS= read -r f; do
       sed -i.bak 's/dev\.agitrubard\.hexalayered/<BASE_PACKAGE>/g' "$f" && rm -f "$f.bak"
   done
   ```

   Show the user the file list before running it.

5. **Adjust the settings.** In `.claude/settings.json`, align `permissions.allow` with the
   real build tool — drop the Gradle entries on a Maven project and vice versa. Leave the
   `PostToolUse` hook in place; mention that it can be removed if the team prefers
   advisory-only checks.

6. **Install the root `CLAUDE.md`** from
   [`.claude/templates/CLAUDE.md`](../../templates/CLAUDE.md), filling `{{PROJECT_NAME}}`,
   `{{BASE_PACKAGE}}`, `{{BUILD_TOOL}}`, `{{TEST_COMMAND}}` and `{{MODULES}}`.

   If a `CLAUDE.md` already exists, **append** the HexaLayered section to it rather than
   overwriting — never discard a project's existing memory file.

7. **Set up the artifact directories.**

   ```sh
   mkdir -p docs/specs docs/adr
   ```

8. **Verify.**

   ```sh
   sh .claude/scripts/check-architecture.sh --all
   sh .claude/scripts/new-feature.sh --current 2>/dev/null || echo "no features yet — expected"
   ```

   On an existing codebase the checker may report real violations. That is a finding, not a
   bootstrap failure — report it and offer `/hexa:review` for the full picture.

## Output

- the detected/confirmed values, as a table
- which files were rewritten
- the checker result on the existing code — quote it honestly, including violations
- next step:
  - empty project → `/hexa:module common`, then `/hexa:module <first capability>`
  - existing project → `/hexa:review` to see where it stands, or `/hexa:specify` to start a
    feature

## Rules

- Never overwrite an existing `CLAUDE.md` — append.
- Never rewrite the user's application code during bootstrap. This command touches
  `.claude/`, `CLAUDE.md` and directory creation only.
- If the base package cannot be determined and the user does not know, stop and ask rather
  than guessing — every generated file afterwards depends on it.
