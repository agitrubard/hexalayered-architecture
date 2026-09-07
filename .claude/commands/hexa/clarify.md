---
description: Resolve every open question in the feature spec and log the decisions
argument-hint: [feature directory — defaults to the most recent]
allowed-tools: Bash, Read, Edit, Grep, AskUserQuestion, Skill
---

# /hexa:clarify

Resolve the open questions in the specification, so the plan is built on decisions rather than
assumptions.

You are in **Phase 2** of Spec Driven Development.

## Locate the spec

```sh
sh .claude/scripts/new-feature.sh --current
```

Use `$ARGUMENTS` instead if the user named a feature directory. Read `spec.md` in full.

## Steps

1. **Collect the questions.**

   ```sh
   grep -n "NEEDS CLARIFICATION" <SPEC_FILE>
   ```

   Then re-read the spec and add what the markers missed:

   - a term used in §6–§9 that §4 Domain Language never defines
   - a requirement with no acceptance criterion
   - a happy path with no stated failure behaviour
   - no authorization rule — who is allowed to do this?
   - no volume or performance expectation where one clearly matters
   - a change to an existing API contract that nobody has called out
   - a state in §5 with no transition into or out of it

2. **Rank by design impact.** A question that changes *which ports exist* outranks a question
   about a label. Ask the ones that would change the architecture first.

3. **Ask.** Use `AskUserQuestion`, at most **five per round**. Offer concrete options with
   their trade-offs, not open prompts — "Should soft-deleted tickets appear in the list?
   (a) never, (b) only for admins, (c) with a flag" beats "how should deletion work?".

   Recommend an option when there is a sensible default, and say why.

4. **Apply each answer.**
   - Rewrite the affected FR/BR/ER — do not just annotate it.
   - Remove the resolved `[NEEDS CLARIFICATION]` marker.
   - Append to §12 Clarifications:

     ```markdown
     ### Session <date>
     - **Q:** <question>
       **A:** <answer>
       **Applied to:** FR-003, BR-001
     ```

5. **Repeat** until no markers remain. New answers often expose new questions — that is the
   process working, not a failure.

6. **Verify the gate.**

   ```sh
   grep -c "NEEDS CLARIFICATION" <SPEC_FILE>   # must print 0
   ```

## Output

- how many questions were resolved this round
- which requirements changed
- whether the spec is now ready for `/hexa:plan`, or what still blocks it

## Rules

- Never answer a question on the user's behalf. If they say "you decide", record *that* as the
  answer along with the choice you made and the reason.
- §12 Clarifications is a log — append only, never rewrite history.
- Still no implementation vocabulary. Answers change requirements, not designs.
- If the user's answer contradicts an existing requirement, say so explicitly and ask which
  one wins before editing.
