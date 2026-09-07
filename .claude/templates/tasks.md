# Task List — {{FEATURE_NAME}}

**Feature ID:** `{{FEATURE_ID}}`
**Spec:** [`spec.md`](./spec.md) · **Plan:** [`plan.md`](./plan.md)
**Created:** {{DATE}}
**Phase:** `/hexa:tasks` → *(next: `/hexa:implement`)*

---

## Legend

- `[ ]` not started · `[~]` in progress · `[x]` done
- **`[P]`** — parallelizable: touches no file another unfinished task touches
- Every task names its **exact target file path**. A task without a path is not a task.

## Ordering Law

Tasks are ordered **inside-out**, because that is the direction the dependencies point:

```
1. enums & domain model      →  nothing depends on the layers above
2. entity
3. mappers
4. repository
5. port interfaces
6. adapters                  →  + AdapterTest
7. exceptions
8. service interfaces
9. service implementations   →  + ServiceImplTest
10. request / response models
11. controller               →  + ControllerTest
12. end-to-end test
13. migration & docs
```

Within a unit, the **test comes first** where it can drive the shape; where the type is a
pure data holder, the builder comes first.

---

## Phase 1 — Domain Core

- [ ] **T001** `[P]` Create enum `[Domain]Status`
      → `src/main/java/…/[module]/model/enums/[Domain]Status.java`
      *plan §3.1 · FR-001*
- [ ] **T002** Create domain model `[Domain]` extending `BaseDomainModel`
      → `src/main/java/…/[module]/model/[Domain].java`
      *plan §3.1*
- [ ] **T003** `[P]` Create test builder `[Domain]Builder` with `withValidValues()`
      → `src/test/java/…/[module]/model/[Domain]Builder.java`
      *Article IX*

## Phase 2 — Persistence

- [ ] **T004** Create entity `[Domain]Entity` extending `BaseEntity`
      → `src/main/java/…/[module]/model/entity/[Domain]Entity.java`
- [ ] **T005** `[P]` Create test builder `[Domain]EntityBuilder`
      → `src/test/java/…/[module]/model/entity/[Domain]EntityBuilder.java`
- [ ] **T006** `[P]` Create mapper `[Domain]ToEntityMapper`
      → `src/main/java/…/[module]/model/mapper/[Domain]ToEntityMapper.java`
- [ ] **T007** `[P]` Create mapper `[Domain]EntityToDomainMapper`
      → `src/main/java/…/[module]/model/mapper/[Domain]EntityToDomainMapper.java`
- [ ] **T008** Create `[Domain]Repository`
      → `src/main/java/…/[module]/repository/[Domain]Repository.java`

## Phase 3 — Ports & Adapters

- [ ] **T009** `[P]` Create `[Domain]ReadPort` *(public interface)*
      → `src/main/java/…/[module]/port/[Domain]ReadPort.java`
- [ ] **T010** `[P]` Create `[Domain]SavePort` *(public interface)*
      → `src/main/java/…/[module]/port/[Domain]SavePort.java`
- [ ] **T011** Write `[Domain]AdapterTest` — repository mocked
      → `src/test/java/…/[module]/port/adapter/[Domain]AdapterTest.java`
- [ ] **T012** Create `[Domain]Adapter` *(package-private)* implementing the ports
      → `src/main/java/…/[module]/port/adapter/[Domain]Adapter.java`
      *Article II: entity → domain mapping happens here and nowhere above*

## Phase 4 — Business Logic

- [ ] **T013** `[P]` Create `[Domain]NotFoundByIdException`
      → `src/main/java/…/[module]/exception/[Domain]NotFoundByIdException.java`
      *ER-001*
- [ ] **T014** `[P]` Create `[Domain][Action]Service` *(public interface)*
      → `src/main/java/…/[module]/service/[Domain][Action]Service.java`
- [ ] **T015** Write `[Domain][Action]ServiceImplTest` — ports mocked, covers BR-001
      → `src/test/java/…/[module]/service/impl/[Domain][Action]ServiceImplTest.java`
- [ ] **T016** Create `[Domain][Action]ServiceImpl` *(package-private)*
      → `src/main/java/…/[module]/service/impl/[Domain][Action]ServiceImpl.java`

## Phase 5 — API Surface

- [ ] **T017** `[P]` Create `[Domain][Action]Request` with validation annotations
      → `src/main/java/…/[module]/model/request/[Domain][Action]Request.java`
      *Article VIII: input validation lives here*
- [ ] **T018** `[P]` Create `[Domain][Action]RequestBuilder`
      → `src/test/java/…/[module]/model/request/[Domain][Action]RequestBuilder.java`
- [ ] **T019** `[P]` Create `[Domain]Response`
      → `src/main/java/…/[module]/model/response/[Domain]Response.java`
- [ ] **T020** `[P]` Create `[Domain]To[Domain]ResponseMapper`
      → `src/main/java/…/[module]/model/mapper/[Domain]To[Domain]ResponseMapper.java`
- [ ] **T021** Write `[Domain]ControllerTest` — service mocked, happy path + validation failures
      → `src/test/java/…/[module]/controller/[Domain]ControllerTest.java`
- [ ] **T022** Create `[Domain]Controller` *(package-private)*
      → `src/main/java/…/[module]/controller/[Domain]Controller.java`

## Phase 6 — Integration & Closure

- [ ] **T023** Write `[Domain]EndToEndTest` covering Scenario 1
      → `src/test/java/…/[module]/controller/[Domain]EndToEndTest.java`
- [ ] **T024** Database migration
      → `src/main/resources/db/migration/V…__….sql`
- [ ] **T025** Run `sh .claude/scripts/check-architecture.sh --all` → must exit 0
- [ ] **T026** Run the full suite → must be green
- [ ] **T027** Run `/hexa:analyze` → no HIGH findings

---

## Traceability

Every requirement must land in at least one task; every task must serve a requirement.

| Requirement | Tasks |
|---|---|
| FR-001 | T002, T012, T016, T022 |
| FR-002 | |
| BR-001 | T015, T016 |
| ER-001 | T013, T021 |

---

## Progress

| Phase | Tasks | Done |
|---|---|---|
| 1 — Domain Core | T001–T003 | 0/3 |
| 2 — Persistence | T004–T008 | 0/5 |
| 3 — Ports & Adapters | T009–T012 | 0/4 |
| 4 — Business Logic | T013–T016 | 0/4 |
| 5 — API Surface | T017–T022 | 0/6 |
| 6 — Integration | T023–T027 | 0/5 |
