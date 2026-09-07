# Naming Conventions

The name determines the package, and the package determines the name. Nothing here is
stylistic — the architecture checker and every reader rely on it.

`[Domain]` = PascalCase domain noun (`Ticket`) · `[module]` = lowercase package segment
(`ticket`) · `[Action]` = bare verb (`Create`, `Read`, `Update`, `Delete`, `Save`, `Search`)

---

## The table

| # | Kind | Package | Type name | Example |
|---|---|---|---|---|
| 1 | Controller | `[module].controller` | `[Domain]Controller` | `TicketController` |
| 2 | Service | `[module].service` | `[Domain][Action]Service` | `TicketCreateService` |
| 2b | Service impl | `[module].service.impl` | `[Domain][Action]ServiceImpl` | `TicketCreateServiceImpl` |
| 3 | Port | `[module].port` | `[Domain][Action]Port` | `TicketSavePort` |
| 3b | Adapter | `[module].port.adapter` | `[Domain][Action]Adapter` | `TicketSaveAdapter` |
| 4 | Repository | `[module].repository` | `[Domain]Repository` | `TicketRepository` |
| 5 | Domain model | `[module].model` | `[Domain]` | `Ticket` |
| 6 | Entity | `[module].model.entity` | `[Domain]Entity` | `TicketEntity` |
| 7 | Request | `[module].model.request` | `[Domain][Action]Request` | `TicketCreateRequest` |
| 8 | Response | `[module].model.response` | `[Domain]Response` / `[Domain][Action]Response` | `TicketResponse` |
| 9 | Exception | `[module].exception` | `[ErrorAction]Exception` | `TicketNotFoundByIdException` |
| 10 | Util | `[module].util` | `[Name]Util` / `[Name][Action]Util` / `[Domain][Action]` | `FileUtil`, `FileReadUtil`, `TicketCodeGenerator` |

Types that follow from the same logic:

| Kind | Package | Type name | Example |
|---|---|---|---|
| Enum | `[module].model.enums` | `[Domain][Concept]` | `TicketStatus` |
| Mapper | `[module].model.mapper` | `[Source]To[Target]Mapper` | `TicketEntityToDomainMapper` |
| Filter | `[module].model` | `[Domain]Filter` | `TicketFilter` |
| Configuration | `[module].configuration` | `[Concept]Configuration` | `DataSourceConfiguration` |
| Test builder | *mirrors the type's package, in test root* | `[Type]Builder` | `TicketBuilder` |

---

## Verbs

Use the bare verb. The suffix already says what kind of thing it is.

| ✅ | ❌ |
|---|---|
| `TicketCreateService` | `TicketCreationService`, `CreateTicketService`, `TicketCreatorService` |
| `TicketReadPort` | `TicketGetterPort`, `TicketFetchingPort`, `TicketQueryPort` |
| `TicketDeleteAdapter` | `TicketRemovalAdapter`, `TicketEraserAdapter` |

Standard action vocabulary: **Create · Read · Update · Delete · Save · Search · Send ·
Publish · Validate**. Reach for a new verb only when none of these fits the intent.

## Banned suffixes

`Manager`, `Helper`, `Processor`, `Handler`, `Facade`, `Utils`, `Impl` (on anything that is
not a `*ServiceImpl`), `Bean`, `DTO`, `VO`, `Info`, `Data`.

Each of these hides which layer a class belongs to. If a class does not fit any layer suffix,
the class is doing something the architecture has no place for — which is the finding, not the
naming.

`Handler` has exactly one legitimate use: `GlobalExceptionHandler` in
`common.exception.handler`.

## Exception naming

`[Domain][Problem][Qualifier]Exception` — the name alone should tell you what went wrong and
what identified the thing.

| Situation | Name |
|---|---|
| Not found by id | `TicketNotFoundByIdException` |
| Not found by a business key | `TicketNotFoundByCodeException` |
| Already exists | `InstitutionAlreadyExistsByNameException` |
| Illegal state transition | `TicketStatusNotValidException` |
| Not permitted | `TicketAccessDeniedException` |
| Infrastructure failed | `FileReadException` |

Avoid bare `TicketException` — it says nothing at the call site or in a log.

## Mapper naming

`[Source]To[Target]Mapper`, read left to right as the direction of the conversion:

| Direction | Name |
|---|---|
| `Ticket` → `TicketEntity` | `TicketToEntityMapper` |
| `TicketEntity` → `Ticket` | `TicketEntityToDomainMapper` |
| `Ticket` → `TicketResponse` | `TicketToTicketResponseMapper` |
| `TicketCreateRequest` → `Ticket` | `TicketCreateRequestToDomainMapper` |

## Endpoints

`/api/v{version}/{resource}` — plural for collections, singular for one item.

| Operation | Method & path |
|---|---|
| Create | `POST /api/v1/ticket` |
| Read one | `GET /api/v1/ticket/{id}` |
| List / search | `POST /api/v1/tickets` (filter in the body) or `GET /api/v1/tickets` |
| Update | `PUT /api/v1/ticket/{id}` |
| Partial update | `PATCH /api/v1/ticket/{id}/status` |
| Delete | `DELETE /api/v1/ticket/{id}` |

## Test naming

| Kind | Name |
|---|---|
| Test class | `[TypeUnderTest]Test` — `TicketCreateServiceImplTest` |
| End-to-end | `[Domain]EndToEndTest` |
| Builder | `[Type]Builder` |
| Method | `given<Precondition>_when<Event>_then<Outcome>` |
| Method (no precondition) | `when<Event>_then<Outcome>` |

```java
@Test
void givenValidTicketCreateRequest_whenTicketCreated_thenReturnTicket() { }

@Test
void givenTicketCreateRequest_whenTitleAlreadyExists_thenThrowTicketAlreadyExistsByTitleException() { }

@Test
void whenTicketsNotFound_thenReturnEmptyList() { }
```

## Database naming

| Kind | Convention | Example |
|---|---|---|
| Table | `UPPER_SNAKE`, singular | `TICKET`, `TICKET_COMMENT` |
| Column | `UPPER_SNAKE` | `CREATED_AT`, `INSTITUTION_ID` |
| Foreign key | `FK_<TABLE>_<REFERENCED>` | `FK_TICKET_INSTITUTION` |
| Index | `IDX_<TABLE>_<COLUMNS>` | `IDX_TICKET_STATUS` |

Adopt the project's existing convention if it differs — but adopt it everywhere.

---

## Quick lookup: name → package

```
*Controller       → [module].controller
*Service          → [module].service
*ServiceImpl      → [module].service.impl
*Port             → [module].port
*Adapter          → [module].port.adapter
*Repository       → [module].repository
*Entity           → [module].model.entity
*Request          → [module].model.request
*Response         → [module].model.response
*Mapper           → [module].model.mapper
*Exception        → [module].exception
*Util             → [module].util
*Configuration    → [module].configuration
enum              → [module].model.enums
anything else     → [module].model
```
