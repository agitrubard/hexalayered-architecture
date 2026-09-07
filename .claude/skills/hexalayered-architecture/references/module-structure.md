# Module Structure

A HexaLayered application is a set of **vertical slices**. Each module owns its whole stack —
controller down to repository — and is isolated from the others.

---

## Application layout

```
{BASE_PACKAGE}
├── common          ← shared foundation, depends on no feature module
├── ticket          ← feature module
├── institution     ← feature module
└── Application.java
```

Dependency direction:

```
ticket ──┐
         ├──► common
institution ─┘

ticket ──► institution   only through institution.service / institution.port  (Article VI)
```

`common` never depends on a feature module. If it starts to, the thing you put in `common`
belongs in a module.

---

## A feature module

```
{BASE_PACKAGE}.ticket
│
├── controller
│   └── TicketController                    package-private
│
├── service
│   ├── TicketCreateService                 public interface
│   ├── TicketReadService                   public interface
│   ├── TicketUpdateService                 public interface
│   ├── TicketDeleteService                 public interface
│   └── impl
│       ├── TicketCreateServiceImpl         package-private
│       ├── TicketReadServiceImpl           package-private
│       ├── TicketUpdateServiceImpl         package-private
│       └── TicketDeleteServiceImpl         package-private
│
├── port
│   ├── TicketReadPort                      public interface
│   ├── TicketSavePort                      public interface
│   ├── TicketDeletePort                    public interface
│   └── adapter
│       └── TicketAdapter                   package-private
│
├── repository
│   └── TicketRepository                    public interface
│
├── exception
│   ├── TicketNotFoundByIdException
│   └── TicketAlreadyExistsByTitleException
│
├── model
│   ├── Ticket                              domain model
│   ├── TicketFilter                        (optional)
│   ├── entity
│   │   └── TicketEntity
│   ├── enums
│   │   └── TicketStatus
│   ├── mapper
│   │   ├── TicketToEntityMapper
│   │   ├── TicketEntityToDomainMapper
│   │   └── TicketToTicketResponseMapper
│   ├── request
│   │   ├── TicketCreateRequest
│   │   └── TicketUpdateRequest
│   └── response
│       └── TicketResponse
│
└── util                                    (optional)
    └── TicketCodeGenerator
```

A module may additionally carry `configuration/`, `security/`, `filter/`, `client/` or
`scheduler/` packages when it genuinely owns those concerns.

---

## The `common` module

```
{BASE_PACKAGE}.common
│
├── configuration
│   ├── DataSourceConfiguration
│   ├── OpenApiConfiguration
│   └── WebConfiguration
│
├── exception
│   ├── handler
│   │   └── GlobalExceptionHandler
│   ├── AbstractNotFoundException
│   ├── AbstractConflictException
│   ├── AbstractForbiddenException
│   ├── AbstractServerException
│   └── FileReadException
│
├── model
│   ├── BaseDomainModel                     createdUser/createdAt/updatedUser/updatedAt
│   ├── Page                                framework-agnostic page wrapper
│   ├── Pageable
│   ├── Sort
│   ├── Filter                              marker for module filters
│   ├── entity
│   │   └── BaseEntity                      audit columns + @MappedSuperclass
│   ├── mapper
│   │   └── BaseMapper<SOURCE, TARGET>      map(SOURCE) / map(List<SOURCE>)
│   └── response
│       ├── BaseResponse
│       ├── SuccessResponse
│       ├── ErrorResponse
│       └── PageResponse
│
└── util
    ├── FileUtil
    ├── ListUtil
    ├── RandomUtil
    └── validation
        └── … custom constraint annotations & validators
```

**What earns a place in `common`:** something at least two modules need, that carries no
business meaning of its own. A `TicketStatus` enum used by two modules does **not** belong
here — it belongs to `ticket`, and the other module reads it through `ticket.model`.

---

## Test tree

The test package mirrors the production package exactly.

```
src/test/java/{BASE_PACKAGE}
├── UnitTest.java                     @ExtendWith(MockitoExtension.class)
├── RestControllerTest.java           @WebMvcTest / @AutoConfigureMockMvc
├── EndToEndTest.java                 @SpringBootTest + Testcontainers
│
└── ticket
    ├── controller
    │   ├── TicketControllerTest
    │   └── TicketEndToEndTest
    ├── service/impl
    │   └── TicketCreateServiceImplTest
    ├── port/adapter
    │   └── TicketAdapterTest
    └── model
        ├── TicketBuilder
        ├── entity/TicketEntityBuilder
        └── request/TicketCreateRequestBuilder
```

---

## Drawing module boundaries

A module is a **business capability**, not a technical grouping.

| ✅ Module | ❌ Not a module |
|---|---|
| `ticket`, `institution`, `auth`, `notification`, `payment` | `dto`, `service`, `util`, `manager`, `core`, `api` |

Signals you have drawn the boundary wrong:

- Two modules constantly need each other's internals → they are one module.
- A module has a controller and nothing else → it is a facade over another module; merge it.
- A module has no controller and no port used by anyone → it is dead, or it belongs in
  `common`.
- Every feature touches the same module → that module is a god-module; split it by capability.

---

## Inter-module communication

```java
// ✅ ticket depends on institution's public contract
package dev.agitrubard.hexalayered.ticket.service.impl;

import dev.agitrubard.hexalayered.institution.model.Institution;
import dev.agitrubard.hexalayered.institution.service.InstitutionReadService;

@Service
@RequiredArgsConstructor
class TicketCreateServiceImpl implements TicketCreateService {

    private final InstitutionReadService institutionReadService;   // public interface ✅
    private final TicketSavePort ticketSavePort;

    @Override
    public Ticket create(TicketCreateRequest request) {
        Institution institution = institutionReadService.findById(request.getInstitutionId());
        ...
    }
}
```

```java
// ❌ reaching around institution's contract
import dev.agitrubard.hexalayered.institution.repository.InstitutionRepository;   // Article VI
import dev.agitrubard.hexalayered.institution.model.entity.InstitutionEntity;     // Articles II + VI
```

When module A needs something module B does not expose, **add a service or port to B**. Never
reach into B — that is how two modules quietly become one.

For heavier decoupling, publish a domain event from A and let B subscribe through its own
port; the event type lives in the publishing module's `model`.

---

## Adding a module

1. `/hexa:module <name>` — or follow
   [`.claude/templates/module-blueprint.md`](../../../templates/module-blueprint.md).
2. Create the package tree, including `model/entity`, `model/mapper`, `port/adapter`,
   `service/impl`.
3. Build inside-out: enums → domain → entity → mappers → repository → ports → adapter →
   exceptions → services → request/response → controller.
4. Mirror the tree under `src/test/java`, with builders.
5. `sh .claude/scripts/check-architecture.sh --all`.
