# HexaLayered Architecture — Constitution

> The non-negotiable law of this codebase. Every spec, plan, task and line of code is
> checked against it. When a rule here conflicts with convenience, the rule wins.
> A deliberate deviation is not a violation **only** if it is recorded as an ADR
> (`.claude/templates/adr.md`) and referenced from the feature's `plan.md`.

**Source of truth:** [`README.md`](../README.md) of the HexaLayered Architecture project.
This file restates those rules in a testable form. If the two ever disagree, `README.md` wins
and this file is the bug.

---

## Project Variables

These are filled in once, by `/hexa:bootstrap`, when the kit is dropped into a project.
Until then they hold the reference values from the architecture README.

| Variable | Value |
|---|---|
| `BASE_PACKAGE` | `dev.agitrubard.hexalayered` |
| `SOURCE_ROOT` | `src/main/java` |
| `TEST_ROOT` | `src/test/java` |
| `BUILD_TOOL` | Maven |
| `TEST_COMMAND` | `./mvnw test` |
| `SINGLE_TEST_COMMAND` | `./mvnw test -Dtest=<ClassName>` |
| `LINT_COMMAND` | `./mvnw -q checkstyle:check` (adjust or remove) |

Throughout this kit, `[module]` means a feature module package (`ticket`, `institution`, …)
and `[Domain]` means the domain noun in PascalCase (`Ticket`, `Institution`).

---

## Article I — Layer Direction

**Rule.** Control flows in exactly one direction and never skips a layer:

```
Controller  →  Service (interface)  →  ServiceImpl  →  Port (interface)  →  Adapter  →  Repository  →  DB
```

- A Controller calls **only** Service interfaces.
- A `ServiceImpl` calls **only** Port interfaces (and other Service interfaces, incl. from
  other modules).
- An Adapter calls **only** Repositories and external clients.
- Nothing calls **upward**. A Service never knows a Controller exists; an Adapter never knows a
  Service exists.

**Rationale.** This is what makes the outer layers replaceable without touching the core, and
what makes each layer independently testable (README §Advantages 4, 5).

**Violation looks like**

```java
// ❌ Controller reaching past the Service layer
@RestController
class TicketController {
    private final TicketRepository ticketRepository; // Article I
}

// ❌ ServiceImpl reaching past the Port layer
class TicketCreateServiceImpl implements TicketCreateService {
    private final TicketRepository ticketRepository; // Article I
}
```

---

## Article II — Entity Containment

**Rule.** `*Entity` types **cannot leave the persistence edge**. An `[Domain]Entity` may be
referenced only from:

- `[module].model.entity` (itself)
- `[module].repository`
- `[module].port.adapter`
- `[module].model.mapper` (the mappers that convert it)

It must **never** appear in `controller`, `service`, `service.impl`, `port` (interface),
`model` (domain), `model.request`, `model.response`, or in another module — not as a
parameter, not as a return type, not as an `import`.

The currency between layers above the adapter is the **domain model** (`Ticket`), never the
entity (`TicketEntity`).

**Rationale.** "Entity objects cannot leave the adapter layer, so the rest of the application
is not affected when the database structure changes" (README §Advantages 1).

**Violation looks like**

```java
package dev.agitrubard.hexalayered.ticket.service.impl;

import dev.agitrubard.hexalayered.ticket.model.entity.TicketEntity; // Article II

class TicketReadServiceImpl implements TicketReadService {
    public TicketEntity findById(Long id) { ... } // Article II
}
```

---

## Article III — Interface Boundaries

**Rule.** Every crossing between layers goes through an interface. Concretely:

| Crossing | Interface that must exist |
|---|---|
| Controller → Service | `[Domain][Action]Service` |
| ServiceImpl → Port | `[Domain][Action]Port` |
| Adapter → Persistence | `[Domain]Repository` |

There is no "it is only one implementation, so skip the interface" exemption. Interfaces are
mandatory **regardless of perceived immediate need** (README FAQ #16).

**Rationale.** Abstraction, swappable implementations, mockability, dependency inversion, and
one consistent shape across the whole codebase.

---

## Article IV — Access Modifiers

**Rule.** Visibility is part of the architecture, not a style preference.

| Type | Modifier |
|---|---|
| `[Domain]Controller` | **package-private** |
| `[Domain][Action]Service` (interface) | `public` |
| `[Domain][Action]ServiceImpl` | **package-private** |
| `[Domain][Action]Port` (interface) | `public` |
| `[Domain][Action]Adapter` | **package-private** |
| `[Domain]Repository` (interface) | `public` |
| Domain model, `*Request`, `*Response`, `*Entity`, enums | `public` |
| Exceptions | `public` |
| Mappers | `public interface` (MapStruct) |
| `*Util` / generators | `public`, `final`, private constructor |

**Rationale.** A package-private implementation physically cannot be imported from another
package, so the compiler — not a reviewer — enforces Articles I and III.

**Violation looks like**

```java
public class TicketController { }        // Article IV — must be package-private
public class TicketCreateServiceImpl { } // Article IV — must be package-private
interface TicketSavePort { }             // Article IV — must be public
```

---

## Article V — Naming

**Rule.** Names are mechanical. Given a domain `[Domain]` and an action `[Action]`:

| # | Kind | Package | Type name |
|---|---|---|---|
| 1 | Controller | `{BASE_PACKAGE}.[module].controller` | `[Domain]Controller` |
| 2 | Service | `{BASE_PACKAGE}.[module].service` | `[Domain][Action]Service` |
| 2b | Service impl | `{BASE_PACKAGE}.[module].service.impl` | `[Domain][Action]ServiceImpl` |
| 3 | Port | `{BASE_PACKAGE}.[module].port` | `[Domain][Action]Port` |
| 3b | Adapter | `{BASE_PACKAGE}.[module].port.adapter` | `[Domain][Action]Adapter` |
| 4 | Repository | `{BASE_PACKAGE}.[module].repository` | `[Domain]Repository` |
| 5 | Domain model | `{BASE_PACKAGE}.[module].model` | `[Domain]` |
| 6 | Entity | `{BASE_PACKAGE}.[module].model.entity` | `[Domain]Entity` |
| 7 | Request | `{BASE_PACKAGE}.[module].model.request` | `[Domain][Action]Request` |
| 8 | Response | `{BASE_PACKAGE}.[module].model.response` | `[Domain]Response` / `[Domain][Action]Response` |
| 9 | Exception | `{BASE_PACKAGE}.[module].exception` | `[ErrorAction]Exception` |
| 10 | Util | `{BASE_PACKAGE}.[module].util` | `[Name]Util` / `[Name][Action]Util` / `[Domain][Action]` |

Supporting kinds that follow from the same rule:

| Kind | Package | Type name |
|---|---|---|
| Enum | `{BASE_PACKAGE}.[module].model.enums` | `[Domain][Concept]` — e.g. `TicketStatus` |
| Mapper | `{BASE_PACKAGE}.[module].model.mapper` | `[Source]To[Target]Mapper` |
| Filter | `{BASE_PACKAGE}.[module].model` | `[Domain]Filter` |

`[Action]` is a verb in its bare form: `Create`, `Read`, `Update`, `Delete`, `Save`, `Search`.
Never `Creation`, `Getting`, `Deleting`, and never `Manager`, `Helper`, `Processor`, `Handler`
as a substitute for a layer suffix.

**Rationale.** README §Naming Conventions. Consistent names are what let a reader — and this
kit's tooling — locate any class from its role alone.

---

## Article VI — Module Isolation

**Rule.** Each feature module owns its whole vertical stack. Module `A` may reference module
`B` **only** through:

- `B.service` — a public Service interface, or
- `B.port` — a public Port interface, or
- `B.model` — B's domain model / enums / exceptions.

Module `A` may **never** import `B.repository`, `B.model.entity`, `B.service.impl`,
`B.port.adapter`, or `B.controller`.

There is one shared module, `common`, which every module may depend on and which depends on no
feature module.

**Rationale.** "Changes only affect the relevant module" (README §Advantages 2), and README
FAQ #11 on managing inter-module dependencies through well-defined interfaces.

---

## Article VII — Mapping

**Rule.** Every type conversion between layers happens in a dedicated mapper class. No manual
field-by-field copying inside a controller, service, or adapter.

Canonical mappers per module:

| Direction | Mapper | Lives in / used by |
|---|---|---|
| domain → entity | `[Domain]ToEntityMapper` | adapter (write path) |
| entity → domain | `[Domain]EntityToDomainMapper` | adapter (read path) |
| domain → response | `[Domain]To[Domain]ResponseMapper` | controller |
| request → domain | `[Domain][Action]RequestToDomainMapper` | service (when the request is not consumed directly) |

Mappers are MapStruct interfaces extending a shared `BaseMapper<SOURCE, TARGET>` and exposing a
static `initialize()`. They are held as constant fields, not injected:

```java
private final TicketEntityToDomainMapper ticketEntityToDomainMapper =
        TicketEntityToDomainMapper.initialize();
```

**Rationale.** README §Best Practices 10. Mapping is the mechanism that makes Article II
enforceable — without it, entities leak by accident.

---

## Article VIII — Validation, Errors and Transactions

**Rule.**

1. **Input validation** (format, nullability, size, regex) belongs to the Controller layer via
   Jakarta Bean Validation on `*Request` objects (`@Valid`, `@NotBlank`, `@Size`, custom
   validators in `common.util.validation`).
2. **Business-rule validation** (does it exist? is it allowed? is the state transition legal?)
   belongs to the **Service** layer, and throws a module exception.
3. Each module declares its own exceptions in `[module].exception`, extending a shared abstract
   type in `common.exception` (`AbstractNotFoundException`, `AbstractConflictException`,
   `AbstractServerException`, …). They carry a `@Serial serialVersionUID`.
4. Exceptions are translated to HTTP by a single `GlobalExceptionHandler` in
   `common.exception.handler`. Controllers contain no `try/catch` for domain errors.
5. Every response is wrapped in the shared envelope (`SuccessResponse` / `ErrorResponse`).
6. `@Transactional` belongs on the **Adapter** (persistence boundary) or, for a multi-port unit
   of work, on the `ServiceImpl` method. Never on a Controller.

**Rationale.** README §Best Practices 8 & 9, README FAQ #5.

---

## Article IX — Test Contract

**Rule.** A layer is not done until its test exists.

| Production type | Required test | Base class |
|---|---|---|
| `[Domain]Controller` | `[Domain]ControllerTest` — MockMvc, Service mocked | `RestControllerTest` |
| `[Domain][Action]ServiceImpl` | `[Domain][Action]ServiceImplTest` — Ports mocked | `UnitTest` |
| `[Domain][Action]Adapter` | `[Domain][Action]AdapterTest` — Repository mocked | `UnitTest` |
| Non-trivial `*Util` | `[Name]UtilTest` | `UnitTest` |
| Each user-facing endpoint | `[Domain]EndToEndTest` (at least the happy path) | `EndToEndTest` |

- Test method names are `given<Precondition>_when<Event>_then<Outcome>` — or
  `when<Event>_then<Outcome>` when there is no meaningful precondition.
- Test data comes from **builders** — `[Type]Builder` in the mirrored test package, with a
  `withValidValues()` seed and `withX(...)` overrides. No object literals scattered across
  tests.
- Every test body is sectioned `// Given` / `// When` / `// Then`.
- The test package mirrors the production package exactly.

**Rationale.** README §Advantages 5 and §Best Practices — isolated tests per layer are the
payoff for the layering; skipping them forfeits the reason to layer at all.

---

## Article X — Spec Before Code

**Rule.** Non-trivial work follows the Spec Driven Development loop, and each artifact lives in
`docs/specs/<NNN-feature-slug>/`:

```
/hexa:specify  →  spec.md    (WHAT & WHY — no class names, no packages, no framework)
/hexa:clarify  →  spec.md    (ambiguities resolved and logged)
/hexa:plan     →  plan.md    (HOW — modules, per-layer class design, Constitution Check)
/hexa:tasks    →  tasks.md   (ordered, inside-out, test-first, file-precise)
/hexa:implement→  code       (one layer at a time, verified after each)
/hexa:analyze  →  report     (spec ↔ plan ↔ tasks ↔ code consistency)
```

Trivial work — a typo, a log line, a one-field addition to an existing request — may skip
straight to implementation, but never skips Articles I–IX.

**Rationale.** The architecture only survives if the *design decision* about which module,
which ports and which services a feature needs is made deliberately and written down, before a
file gets created in the wrong package.

---

## Enforcement

- `.claude/scripts/check-architecture.sh` mechanically checks Articles I, II, IV, V and VI on
  every `Write`/`Edit` via the `PostToolUse` hook in `.claude/settings.json`.
  A violation exits `2` and the message is fed back so it gets fixed immediately.
- Articles III, VII, VIII, IX and X are judgement calls: they are enforced by
  `/hexa:review`, the `hexa-architecture-reviewer` agent, and the Constitution Check gate
  inside `/hexa:plan`.
- The script is a **floor, not a ceiling**. Passing it is not evidence the design is right.
