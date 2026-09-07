---
description: Turn an intent into a feature specification (WHAT & WHY) under docs/specs/
argument-hint: <what the feature should do, in plain language>
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Skill
---

# /hexa:specify

Create the feature specification for: **$ARGUMENTS**

You are in **Phase 1** of Spec Driven Development. Load the
`spec-driven-development` skill before you start.

## Preconditions

- `$ARGUMENTS` is non-empty. If it is, ask what the feature should do and stop.

## Steps

1. **Allocate the workspace**

   ```sh
   sh .claude/scripts/new-feature.sh "$ARGUMENTS"
   ```

   Read the printed `FEATURE_DIR` / `SPEC_FILE`. Every path below is relative to that
   directory. Do not create the directory by hand.

2. **Understand the domain before writing.** Look at the existing modules
   (`{SOURCE_ROOT}/**/`), and at `docs/specs/` for related features. You are placing this
   feature in an existing domain, not inventing a vocabulary.

3. **Write the spec** into `SPEC_FILE`, following the seeded template.

   Order matters — fill §4 Domain Language **first**. The nouns chosen there become class
   names two phases later; a vague noun now is a vague package later.

   Then §1 Problem, §2 Goal, §3 Out of Scope, §5 Domain Concepts, §6 Scenarios,
   §7 Functional Requirements, §8 Business Rules, §9 Error Cases, §10 Non-Functional.

4. **Mark every unknown.** Anything the user did not state and that is not obvious becomes:

   ```
   [NEEDS CLARIFICATION: <a specific, answerable question>]
   ```

   Do **not** guess. Do **not** silently pick a default. A spec that quietly assumes is worse
   than one that visibly asks. Pay particular attention to the things people forget to say:
   authorization ("who may do this?"), the empty and error cases, volume, whether an existing
   API contract changes, and what happens on a retry.

5. **Enforce purity.** The spec describes WHAT and WHY. Before finishing, check your own
   output:

   ```sh
   grep -nE '@[A-Z]|Controller|Service|Repository|Entity|Port|Adapter|JPA|Spring|POST |GET ' <SPEC_FILE>
   ```

   Any hit outside prose means implementation detail leaked in. Move it to your head — it
   belongs in `plan.md`, which the next phase writes. Delete it from the spec.

6. **Check the Exit Gate** at the bottom of the spec and tick it honestly.

## Output

Report to the user:

- the feature id and the path to `spec.md`
- the scenarios and requirement count, in one line
- **every** `[NEEDS CLARIFICATION]` marker, listed — these are what `/hexa:clarify` resolves
- next step: `/hexa:clarify`

## Rules

- Never write code in this phase. Not even a sketch.
- Never name a class, package, annotation, table or library.
- §3 Out of Scope must not be empty — if you cannot think of an exclusion, you do not yet
  understand the boundary of the feature.
- Requirements are numbered, atomic and testable by a non-developer.
