# Feature Specifications

Spec Driven Development artifacts. One directory per feature, created by
`/hexa:specify` (via `.claude/scripts/new-feature.sh`).

```
docs/specs/
├── 001-close-ticket-with-reason/
│   ├── spec.md      WHAT & WHY      — /hexa:specify, /hexa:clarify
│   ├── plan.md      HOW            — /hexa:plan
│   └── tasks.md     ordered work    — /hexa:tasks
└── 002-…/
```

These are reviewed like code, because they are the record of **why** the code looks the way it
does. They belong in the pull request alongside the change they describe.

| File | Contains | Never contains |
|---|---|---|
| `spec.md` | problem, scenarios, `FR-###`, `BR-###`, `ER-###`, domain language | class names, packages, annotations, tables |
| `plan.md` | modules, per-layer class design, packages, access modifiers, data flow, Constitution Check | code |
| `tasks.md` | ordered tasks with exact file paths and requirement references | design decisions |

Architectural decisions that deviate from `.claude/constitution.md` go in `docs/adr/`, using
`.claude/templates/adr.md`, and are linked from the feature's `plan.md` §6.

Workflow reference:
[`.claude/skills/spec-driven-development/`](../../.claude/skills/spec-driven-development/SKILL.md)
