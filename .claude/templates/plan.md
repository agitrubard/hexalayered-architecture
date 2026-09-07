# Implementation Plan — {{FEATURE_NAME}}

**Feature ID:** `{{FEATURE_ID}}`
**Spec:** [`spec.md`](./spec.md)
**Created:** {{DATE}}
**Phase:** `/hexa:plan` → *(next: `/hexa:tasks`)*

> **This document describes HOW.** Every class that will exist, in which package, with which
> visibility, taking which types and returning which types — decided *before* a file is
> created, so nothing lands in the wrong package.
>
> Rules: [`.claude/constitution.md`](../../../.claude/constitution.md)

---

## 1. Approach

<!-- 3–8 sentences. The shape of the solution and the one or two decisions that drove it. -->

## 2. Module Map

| Module | New or existing? | Why it is involved |
|---|---|---|
| `[module]` | | |

**Cross-module dependencies introduced**

| From | To | Through (must be a public Service or Port) | Justification |
|---|---|---|---|
| | | | |

> Constitution Article VI: a module may only reach another module through its **public
> Service or Port interfaces**. Never its repository, entity, `service.impl` or
> `port.adapter`.

---

## 3. Layer Design

Fill one table per module. `Access` is not optional — it is Article IV.

### Module `[module]`

#### 3.1 Domain & Models

| Type | Package | Access | Notes |
|---|---|---|---|
| `[Domain]` | `{BASE_PACKAGE}.[module].model` | public | extends `BaseDomainModel` |
| `[Domain]Entity` | `{BASE_PACKAGE}.[module].model.entity` | public | extends `BaseEntity`; table `…` |
| `[Domain]Status` | `{BASE_PACKAGE}.[module].model.enums` | public | values: … |
| `[Domain][Action]Request` | `{BASE_PACKAGE}.[module].model.request` | public | validated with `@…` |
| `[Domain]Response` | `{BASE_PACKAGE}.[module].model.response` | public | |
| `[Domain]ToEntityMapper` | `{BASE_PACKAGE}.[module].model.mapper` | public interface | MapStruct |
| `[Domain]EntityToDomainMapper` | `{BASE_PACKAGE}.[module].model.mapper` | public interface | MapStruct |

#### 3.2 Repository

| Type | Package | Access | Methods |
|---|---|---|---|
| `[Domain]Repository` | `{BASE_PACKAGE}.[module].repository` | public interface | `extends JpaRepository<[Domain]Entity, ID>` + … |

#### 3.3 Ports & Adapters

| Port | Access | Method(s) | Input → Output | Adapter | Access |
|---|---|---|---|---|---|
| `[Domain]ReadPort` | public interface | `findById(ID)` | `ID` → `Optional<[Domain]>` | `[Domain]ReadAdapter` | package-private |
| `[Domain]SavePort` | public interface | `save([Domain])` | `[Domain]` → `[Domain]` | `[Domain]SaveAdapter` | package-private |

> **Granularity decision** (README FAQ #14): one adapter per port, or one adapter implementing
> several ports? State the choice and the reason.
>
> Chosen: … because ….

#### 3.4 Services

| Service interface | Access | Method | Input → Output | Impl | Access | Ports used |
|---|---|---|---|---|---|---|
| `[Domain]CreateService` | public interface | `create(...)` | `[Domain]CreateRequest` → `[Domain]` | `[Domain]CreateServiceImpl` | package-private | `[Domain]SavePort` |

> **Granularity decision** (README FAQ #13 & #15): split by action, or one service?
>
> Chosen: … because ….

#### 3.5 Controller

| Type | Access | Endpoint | Request | Response |
|---|---|---|---|---|
| `[Domain]Controller` | package-private | `POST /api/v1/[domain]` | `[Domain]CreateRequest` | `SuccessResponse<[Domain]Response>` |

#### 3.6 Exceptions

| Exception | Package | Extends | Thrown by | HTTP |
|---|---|---|---|---|
| `[Domain]NotFoundByIdException` | `{BASE_PACKAGE}.[module].exception` | `AbstractNotFoundException` | `[Domain]ReadServiceImpl` | 404 |

---

## 4. Data Flow

Trace each functional requirement through the layers, so a missing port is visible on paper.

**FR-001 — <requirement>**

```
POST /api/v1/…
  → [Domain]Controller.create(@Valid [Domain]CreateRequest)
  → [Domain]CreateService.create(request)                      (interface)
  → [Domain]CreateServiceImpl                                   (business rules: BR-001)
      → [Domain]ReadPort.existsByName(...)      → throws [Domain]AlreadyExistsException
      → [Domain]SavePort.save(domain)
          → [Domain]SaveAdapter                                 (domain → entity)
              → [Domain]Repository.save(entity)
  ← [Domain]  → [Domain]ToResponseMapper → SuccessResponse<[Domain]Response>
```

---

## 5. Persistence Changes

| Change | Detail |
|---|---|
| New tables | |
| Altered columns | |
| Indexes | |
| Migration script | `…` |

---

## 6. Constitution Check

Every row must be **PASS** before `/hexa:tasks` runs. A `DEVIATION` requires a linked ADR.

| Article | Check | Status |
|---|---|---|
| I — Layer Direction | No layer is skipped; no upward dependency | ☐ PASS |
| II — Entity Containment | No `*Entity` above `port.adapter` / `model.mapper` | ☐ PASS |
| III — Interface Boundaries | Every Service and Port has an interface | ☐ PASS |
| IV — Access Modifiers | Controller / `*ServiceImpl` / `*Adapter` are package-private | ☐ PASS |
| V — Naming | Every type above matches the naming table | ☐ PASS |
| VI — Module Isolation | Cross-module access only via public Service/Port | ☐ PASS |
| VII — Mapping | A mapper exists for every conversion; none inline | ☐ PASS |
| VIII — Validation & Errors | Input in controller, rules in service, module exceptions | ☐ PASS |
| IX — Test Contract | A test is planned for every controller, service impl, adapter | ☐ PASS |

**Deviations**

| Article | What we do instead | ADR |
|---|---|---|
| | | `docs/adr/NNN-….md` |

---

## 7. Risks & Trade-offs

| Risk | Impact | Mitigation |
|---|---|---|
| | | |

---

## Exit Gate — `/hexa:plan` is done when

- [ ] Every FR in `spec.md` appears in §4 Data Flow.
- [ ] Every type in §3 has a package **and** an access modifier.
- [ ] §6 Constitution Check is all PASS, or every deviation has an ADR.
- [ ] No new class is introduced that has no caller in §4.
