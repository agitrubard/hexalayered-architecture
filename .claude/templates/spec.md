# Feature Specification — {{FEATURE_NAME}}

**Feature ID:** `{{FEATURE_ID}}`
**Created:** {{DATE}}
**Status:** Draft
**Phase:** `/hexa:specify` → *(next: `/hexa:clarify`)*

> **This document describes WHAT and WHY, never HOW.**
> No class names, no package names, no `@RestController`, no table names, no framework.
> If a sentence could not be understood by a non-developer stakeholder, it belongs in
> `plan.md`, not here.

---

## 1. Problem

<!-- What is broken, missing or painful today? Who feels it? What does it cost? -->

## 2. Goal

<!-- One paragraph. The observable end state, in the user's vocabulary. -->

## 3. Out of Scope

<!-- Explicitly list what this feature will NOT do. This is what stops scope creep later. -->

- …

---

## 4. Domain Language

Terms this feature introduces or relies on. Use these words — and only these words —
consistently across `spec.md`, `plan.md` and the code.

| Term | Meaning | Notes |
|---|---|---|
| | | |

## 5. Domain Concepts

The things that exist and the relationships between them, described without persistence
detail.

| Concept | Description | Key attributes | Lifecycle / states |
|---|---|---|---|
| | | | |

---

## 6. User Scenarios

### Scenario 1 — <name>

**As a** <role>
**I want** <capability>
**So that** <benefit>

**Acceptance criteria**

1. **Given** <precondition> **when** <action> **then** <observable outcome>.
2. **Given** … **when** … **then** ….

### Scenario 2 — <name>

…

---

## 7. Functional Requirements

Each requirement is atomic, testable, and traceable to a scenario. `FR-###` ids are
referenced by `plan.md` and `tasks.md`.

| ID | Requirement | Scenario | Priority |
|---|---|---|---|
| FR-001 | The system MUST … | 1 | Must |
| FR-002 | The system MUST … | 1 | Must |
| FR-003 | The system SHOULD … | 2 | Should |

## 8. Business Rules

Invariants that must hold regardless of how the feature is invoked. These become
**service-layer validations** (Constitution Article VIII).

| ID | Rule | On violation |
|---|---|---|
| BR-001 | … | reject with … |

## 9. Error Cases

What can go wrong from the user's point of view, and what they should see.

| ID | Situation | Expected behaviour |
|---|---|---|
| ER-001 | … | … |

---

## 10. Non-Functional Requirements

| Aspect | Requirement |
|---|---|
| Performance | |
| Volume / scale | |
| Security & authorization | *who is allowed to do this?* |
| Auditability | *does this need to be logged / traceable?* |
| Backwards compatibility | *does this change an existing contract?* |

---

## 11. Open Questions

Everything uncertain is marked here, and `/hexa:clarify` resolves it. **The spec is not
done while any of these remain.**

- [ ] `[NEEDS CLARIFICATION: question]`

## 12. Clarifications

Appended by `/hexa:clarify`. Never edited by hand — it is the decision log.

<!-- ### Session {{DATE}}
- **Q:** …
  **A:** …
  **Applied to:** FR-00X / BR-00X -->

---

## Exit Gate — `/hexa:specify` is done when

- [ ] Every functional requirement is testable by someone who cannot see the code.
- [ ] Every scenario has at least one Given/When/Then acceptance criterion.
- [ ] Out of Scope is not empty.
- [ ] The document contains **no** class name, package name, annotation, table name or
      library name.
- [ ] Every ambiguity is either resolved or listed in §11.
