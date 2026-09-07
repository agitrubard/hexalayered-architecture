# The Four Layers

For each layer: what it is responsible for, what it is allowed to touch, what types cross its
boundary, and what it must never do.

---

## 1. Controller Layer

**Package** `{BASE_PACKAGE}.[module].controller`
**Visibility** package-private
**Responsibility** Meet the HTTP request, hand it to a service, shape the answer.

| | |
|---|---|
| **Input** | `[Domain][Action]Request` (validated), path/query params |
| **Output** | `SuccessResponse<[Domain]Response>` / `PageResponse<…>` |
| **May call** | Service **interfaces** only |
| **May never touch** | `*Port`, `*Adapter`, `*Repository`, `*Entity` |

```java
package dev.agitrubard.hexalayered.ticket.controller;

@RestController
@RequiredArgsConstructor
class TicketController {

    private final TicketCreateService ticketCreateService;

    private final TicketToTicketResponseMapper ticketToTicketResponseMapper =
            TicketToTicketResponseMapper.initialize();

    @PostMapping("/api/v1/ticket")
    SuccessResponse<TicketResponse> create(@RequestBody @Valid TicketCreateRequest request) {
        Ticket ticket = ticketCreateService.create(request);
        TicketResponse response = ticketToTicketResponseMapper.map(ticket);
        return SuccessResponse.of(response);
    }
}
```

**Does**
- HTTP concerns: routing, status codes, headers, content negotiation.
- Input validation via `@Valid` on the request object.
- Authorization entry points (`@PreAuthorize`).
- Domain → response mapping.

**Does not**
- Contain `if` statements about business rules.
- Catch domain exceptions — `GlobalExceptionHandler` does that.
- Open transactions.
- Know that a database exists.

**Why package-private:** nothing in the application should ever depend on a controller. Making
it package-private turns "should" into "cannot".

---

## 2. Service Layer

**Package** `{BASE_PACKAGE}.[module].service` (interface) ·
`{BASE_PACKAGE}.[module].service.impl` (implementation)
**Visibility** interface `public`, implementation package-private
**Responsibility** Execute business logic; validate business rules; orchestrate ports.

| | |
|---|---|
| **Input** | `*Request`, or plain values (`Long id`, `String code`) |
| **Output** | **domain objects** (`Ticket`), or plain values |
| **May call** | Port interfaces; other modules' Service interfaces |
| **May never touch** | `*Repository`, `*Entity`, `*Adapter`, any `*Controller` |

```java
package dev.agitrubard.hexalayered.ticket.service;

public interface TicketCreateService {
    Ticket create(TicketCreateRequest request);
}
```

```java
package dev.agitrubard.hexalayered.ticket.service.impl;

@Service
@RequiredArgsConstructor
class TicketCreateServiceImpl implements TicketCreateService {

    private final TicketReadPort ticketReadPort;
    private final TicketSavePort ticketSavePort;

    @Override
    public Ticket create(TicketCreateRequest request) {

        boolean alreadyExists = ticketReadPort.existsByTitle(request.getTitle());
        if (alreadyExists) {
            throw new TicketAlreadyExistsByTitleException(request.getTitle());
        }

        Ticket ticket = Ticket.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .status(TicketStatus.OPEN)
                .build();

        return ticketSavePort.save(ticket);
    }
}
```

**Does**
- Business-rule validation ("does it exist?", "is this transition legal?", "is the quota
  spent?") and throws module exceptions when a rule fails.
- Orchestration across several ports, and across other modules' services.
- Transaction boundaries when one logical operation spans several ports.

**Does not**
- Reach a repository directly. That is what a port is for.
- Return an entity, or accept one.
- Format anything for HTTP.

**Naming the action:** `TicketCreateService`, not `TicketCreationService` or `TicketManager`.
`[Domain][Action]Service`.

---

## 3. Port / Adapter Layer

**Package** `{BASE_PACKAGE}.[module].port` (interface) ·
`{BASE_PACKAGE}.[module].port.adapter` (implementation)
**Visibility** port `public`, adapter package-private
**Responsibility** Talk to the outside world — the database, a queue, an HTTP client, a mail
server — and translate between it and the domain.

| | |
|---|---|
| **Input** | domain objects, or plain values |
| **Output** | domain objects, or plain values — **never entities** |
| **May call** | `*Repository`, external clients |
| **May never touch** | `*Service`, `*Controller` |

```java
package dev.agitrubard.hexalayered.ticket.port;

public interface TicketSavePort {
    Ticket save(Ticket ticket);
}
```

```java
package dev.agitrubard.hexalayered.ticket.port.adapter;

@Component
@RequiredArgsConstructor
@Transactional(readOnly = true)
class TicketAdapter implements TicketReadPort, TicketSavePort {

    private final TicketRepository ticketRepository;

    private final TicketToEntityMapper ticketToEntityMapper =
            TicketToEntityMapper.initialize();
    private final TicketEntityToDomainMapper ticketEntityToDomainMapper =
            TicketEntityToDomainMapper.initialize();

    @Override
    public Optional<Ticket> findById(Long id) {
        return ticketRepository.findById(id)
                .map(ticketEntityToDomainMapper::map);
    }

    @Override
    @Transactional
    public Ticket save(Ticket ticket) {
        TicketEntity entity = ticketToEntityMapper.map(ticket);
        TicketEntity saved = ticketRepository.save(entity);
        return ticketEntityToDomainMapper.map(saved);
    }
}
```

**This is the containment boundary.** The adapter is the only class in the module where an
entity and a domain object legitimately appear side by side. Everything above it sees domain
objects only — which is what makes a schema change local (README §Advantages 1).

**Ports are not only for databases.** A mail sender, a payment gateway, a cache, an event
publisher, another bounded context — each is a port with an adapter behind it. That is how the
domain stays ignorant of the infrastructure (README FAQ #12).

**Port method signatures use domain vocabulary**, not persistence vocabulary:
`findById(Long)` returning `Optional<Ticket>` — not `findEntityById` returning `TicketEntity`.

---

## 4. Repository Layer

**Package** `{BASE_PACKAGE}.[module].repository`
**Visibility** `public interface`
**Responsibility** CRUD and queries over entities. Nothing else.

| | |
|---|---|
| **Input** | `*Entity`, ids, `Specification`, `Pageable` |
| **Output** | `*Entity`, `Optional<*Entity>`, `Page<*Entity>` |
| **Called by** | adapters only |

```java
package dev.agitrubard.hexalayered.ticket.repository;

public interface TicketRepository extends JpaRepository<TicketEntity, Long>,
                                          JpaSpecificationExecutor<TicketEntity> {

    Optional<TicketEntity> findByCode(String code);

    boolean existsByTitle(String title);
}
```

**Does not** contain business logic, mapping, or `@Transactional` orchestration.

---

## Allowed dependency matrix

Rows call columns. `✅` allowed · `—` forbidden.

| ↓ calls → | Controller | Service (iface) | ServiceImpl | Port | Adapter | Repository | Domain | Entity |
|---|---|---|---|---|---|---|---|---|
| **Controller** | — | ✅ | — | — | — | — | ✅ | — |
| **ServiceImpl** | — | ✅ | — | ✅ | — | — | ✅ | — |
| **Adapter** | — | — | — | ✅ | — | ✅ | ✅ | ✅ |
| **Repository** | — | — | — | — | — | — | — | ✅ |
| **Mapper** | — | — | — | — | — | — | ✅ | ✅ |

A `ServiceImpl` calling another module's `Service` interface is the one legitimate sideways
edge (Article VI).

---

## Cross-cutting concerns

| Concern | Where it belongs |
|---|---|
| Authentication / authorization | Controller (`@PreAuthorize`), plus a security filter in `common` |
| Input validation | Controller, via Bean Validation on `*Request` |
| Business validation | ServiceImpl |
| Transactions | Adapter for a single persistence operation; ServiceImpl for a multi-port unit of work |
| Caching | Adapter (`@Cacheable` / `@CacheEvict`) |
| Logging & audit | Adapter or an AOP aspect in `common`; never scattered in controllers |
| Error → HTTP translation | `common.exception.handler.GlobalExceptionHandler` |
| Pagination & sorting | shared `Pageable`/`Page` types in `common.model`, mapped at the adapter |
