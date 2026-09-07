---
name: hexalayered-architecture
description: HexaLayered Architecture rules for Spring Boot projects — the four layers (Controller, Service, Port/Adapter, Repository), package and naming conventions, access modifiers, domain-vs-entity separation, mapping, exception handling and per-layer testing. Use whenever writing, reviewing, moving or naming any Java class in a HexaLayered project; when deciding which package a type belongs in; when a controller, service, port, adapter, repository, mapper, entity or domain model is involved; or when asked where code should live, whether to split a service or port, or why a build/architecture check failed.
---

# HexaLayered Architecture

HexaLayered = **Hexa**gonal (ports & adapters) + **Layered**. Business logic sits in the
middle, the outside world reaches it only through interfaces, and each layer has exactly one
job.

The binding rules are in **[`.claude/constitution.md`](../../constitution.md)** — read it
before making an architectural decision. This skill is the working knowledge that makes those
rules easy to apply.

---

## The one-minute version

```
HTTP  →  Controller  →  Service (iface)  →  ServiceImpl  →  Port (iface)  →  Adapter  →  Repository  →  DB
         Request/            business logic                  domain in,       maps domain      Entity
         Response            on domain objects               domain out       ↔ entity
```

| Layer | Package | Speaks | Visibility |
|---|---|---|---|
| Controller | `[module].controller` | `*Request` → `*Response` | **package-private** |
| Service | `[module].service` | request/scalar → **domain** | `public interface` |
| ServiceImpl | `[module].service.impl` | same | **package-private** |
| Port | `[module].port` | **domain** → **domain** | `public interface` |
| Adapter | `[module].port.adapter` | domain ↔ entity | **package-private** |
| Repository | `[module].repository` | `*Entity` | `public interface` |

Five rules that prevent almost every mistake:

1. **Entities never go above the adapter.** The currency above it is the domain model.
2. **Every layer crossing goes through an interface** — even with one implementation.
3. **Implementations are package-private.** Contracts are public. The compiler then enforces
   rule 2.
4. **Names are mechanical**: `[Domain][Action]Service`, `[Domain][Action]Port`,
   `[Domain]Repository`, `[Domain]Entity`. The name tells you the package; the package tells
   you the name.
5. **Modules are vertical slices.** Module A touches module B only through B's public Service
   or Port interfaces.

---

## Where to look

Read the reference for the decision you are making — not all of them.

| You are… | Read |
|---|---|
| deciding what a layer may do, call, take or return | [`references/layers.md`](references/layers.md) |
| naming a class or choosing its package | [`references/naming-conventions.md`](references/naming-conventions.md) |
| creating a module, or laying out a new project | [`references/module-structure.md`](references/module-structure.md) |
| writing a domain model, entity, request, response or mapper | [`references/models-and-mapping.md`](references/models-and-mapping.md) |
| throwing, catching or translating an error | [`references/exception-handling.md`](references/exception-handling.md) |
| writing tests, builders or test base classes | [`references/testing.md`](references/testing.md) |
| reviewing code, or a check just failed | [`references/anti-patterns.md`](references/anti-patterns.md) |

Scaffolding a whole module? Use
[`.claude/templates/module-blueprint.md`](../../templates/module-blueprint.md), or run
`/hexa:module <name>`.

---

## Decision shortcuts

**"Which package does this class go in?"** — Read its suffix. `*Controller` → `controller`.
`*Service` → `service`. `*ServiceImpl` → `service.impl`. `*Port` → `port`. `*Adapter` →
`port.adapter`. `*Repository` → `repository`. `*Entity` → `model.entity`. `*Request` →
`model.request`. `*Response` → `model.response`. `*Mapper` → `model.mapper`. `*Exception` →
`exception`. `*Util` → `util`. Anything else that is a domain noun → `model`.

**"Do I need an interface here?"** — Yes. Always, for Service and Port. There is no
single-implementation exemption (README FAQ #16).

**"Should I split `TicketService` into `TicketCreateService` / `TicketReadService`?"** — Split
when read and write logic barely overlap, when the class is heading past ~300 lines, when the
parts change at different rates, or when the rest of the codebase is already split. Keep it
unified for thin CRUD in a small domain. Starting unified and splitting later is fine
(README FAQ #13, #15).

**"One adapter per port, or one adapter for several ports?"** — One adapter implementing
`ReadPort` + `SavePort` over a single repository is idiomatic. Split when the ports talk to
genuinely different systems, or need different caching or transaction behaviour
(README FAQ #14).

**"Module A needs something from module B."** — Call B's public `Service` or `Port` interface.
Never B's repository, entity, `service.impl` or `port.adapter`. If B exposes nothing suitable,
add a port to B — do not reach around it (README FAQ #11).

**"This is just a small change, can I skip a layer?"** — No. A shortcut through one layer is
what turns the architecture into a suggestion.

---

## Before you finish

Run the checker on what you wrote:

```sh
sh .claude/scripts/check-architecture.sh <file...>   # or --all
```

It mechanically enforces Articles I, II, IV, V and VI. Passing it means you did not break the
structure; it does not mean the design is right — that is what `/hexa:review` and the
`hexa-architecture-reviewer` agent are for.
