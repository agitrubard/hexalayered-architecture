# Models and Mapping

Four kinds of object, four different jobs. Confusing them is how a HexaLayered codebase
degrades back into a layered-with-entities-everywhere codebase.

| Kind | Package | Purpose | Lives between |
|---|---|---|---|
| **Domain model** — `Ticket` | `model` | the business concept; the currency of the app | Controller ↔ Service ↔ Port |
| **Entity** — `TicketEntity` | `model.entity` | a database row | Adapter ↔ Repository ↔ DB |
| **Request** — `TicketCreateRequest` | `model.request` | untrusted input from a client | HTTP → Controller → Service |
| **Response** — `TicketResponse` | `model.response` | the shape the client is promised | Controller → HTTP |

**Rule of thumb:** if you can see an HTTP concern, it is a request/response. If you can see a
column or a `@ManyToOne`, it is an entity. Everything in between is the domain model.

---

## Domain model

The centre of the application. It carries behaviour, not just data.

```java
package dev.agitrubard.hexalayered.ticket.model;

@Getter
@Setter
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = true)
public class Ticket extends BaseDomainModel {

    private Long id;
    private String code;
    private String title;
    private String description;
    private TicketStatus status;

    public boolean isOpen() {
        return TicketStatus.OPEN == this.status;
    }

    public void close(String reason) {
        if (!this.isOpen()) {
            throw new TicketStatusNotValidException(this.id, this.status);
        }
        this.status = TicketStatus.CLOSED;
        this.closeReason = reason;
    }
}
```

- Extends `BaseDomainModel` for audit fields.
- **No JPA annotations.** No `@Entity`, `@Column`, `@Table`, `@ManyToOne`.
- No Jackson shaping for the wire — that is the response's job.
- Business questions (`isOpen()`) and legal state transitions (`close()`) belong **here**,
  not in the service. A service that reads a field, decides, and writes the field back is
  doing the model's job.
- Prefer immutability where the domain allows it (README §Best Practices 11): expose intent
  methods rather than open setters.

---

## Entity

A row. Nothing more.

```java
package dev.agitrubard.hexalayered.ticket.model.entity;

@Entity
@Table(name = "TICKET")
@Getter
@Setter
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class TicketEntity extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @Column(name = "CODE")
    private String code;

    @Column(name = "TITLE")
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(name = "STATUS")
    private TicketStatus status;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "INSTITUTION_ID")
    private InstitutionEntity institution;
}
```

- No business methods. `isOpen()` on an entity means the domain leaked downward.
- **Never returned above the adapter** — not from a port, not from a service, never as a
  response body.
- Entity-to-entity relations (`@ManyToOne`) are fine *inside* the persistence layer; the
  corresponding domain models need not mirror them one-to-one.

---

## Request

Untrusted input. This is where format validation happens (Article VIII).

```java
package dev.agitrubard.hexalayered.ticket.model.request;

@Getter
@Setter
public class TicketCreateRequest {

    @NotBlank
    @Size(min = 3, max = 200)
    private String title;

    @Size(max = 4000)
    private String description;

    @NotNull
    private Long institutionId;
}
```

- Validate **shape** here: null, blank, length, pattern, range, enum membership.
- Do **not** validate business rules here ("this institution must be active") — that needs
  data, so it belongs in the service.
- A request never carries an entity, and never carries a persistence id it should not expose.

---

## Response

The contract with the client. Kept separate from the domain so the domain can evolve without
breaking API consumers.

```java
package dev.agitrubard.hexalayered.ticket.model.response;

@Getter
@Setter
@Builder
public class TicketResponse {

    private Long id;
    private String code;
    private String title;
    private TicketStatus status;
    private LocalDateTime createdAt;
}
```

Never return the domain model directly from a controller. The day the domain gains an internal
field, you would leak it.

---

## Mappers

A dedicated class per direction, in `model.mapper` (Article VII).

```java
package dev.agitrubard.hexalayered.ticket.model.mapper;

@Mapper
public interface TicketEntityToDomainMapper extends BaseMapper<TicketEntity, Ticket> {

    static TicketEntityToDomainMapper initialize() {
        return Mappers.getMapper(TicketEntityToDomainMapper.class);
    }
}
```

with the shared base:

```java
package dev.agitrubard.hexalayered.common.model.mapper;

public interface BaseMapper<SOURCE, TARGET> {

    TARGET map(SOURCE source);

    List<TARGET> map(List<SOURCE> sources);
}
```

**Held as a field, not injected:**

```java
private final TicketEntityToDomainMapper ticketEntityToDomainMapper =
        TicketEntityToDomainMapper.initialize();
```

MapStruct generates the implementation at compile time, so there is nothing to autowire and
nothing to mock — tests exercise the real mapping.

### Which mapper goes where

| Conversion | Mapper | Used in |
|---|---|---|
| domain → entity | `TicketToEntityMapper` | adapter (write) |
| entity → domain | `TicketEntityToDomainMapper` | adapter (read) |
| domain → response | `TicketToTicketResponseMapper` | controller |
| request → domain | `TicketCreateRequestToDomainMapper` | service *(when the request is not used directly)* |

### When a mapper is not enough

For a non-mechanical conversion, add a `@Named` method or a `default` method to the mapper
interface — do not spread the logic into the caller:

```java
@Mapper
public interface TicketToTicketResponseMapper extends BaseMapper<Ticket, TicketResponse> {

    @Mapping(target = "displayTitle", source = ".", qualifiedByName = "toDisplayTitle")
    @Override
    TicketResponse map(Ticket source);

    @Named("toDisplayTitle")
    default String toDisplayTitle(Ticket ticket) {
        return "[" + ticket.getCode() + "] " + ticket.getTitle();
    }

    static TicketToTicketResponseMapper initialize() {
        return Mappers.getMapper(TicketToTicketResponseMapper.class);
    }
}
```

### Never

```java
// ❌ hand-rolled mapping inside an adapter or service — Article VII
TicketEntity entity = new TicketEntity();
entity.setTitle(ticket.getTitle());
entity.setDescription(ticket.getDescription());
entity.setStatus(ticket.getStatus());
```

Every field added later has to be remembered in every such block. That is exactly the class of
bug the mapper removes.

---

## Enums

```java
package dev.agitrubard.hexalayered.ticket.model.enums;

public enum TicketStatus {
    OPEN,
    IN_PROGRESS,
    RESOLVED,
    CLOSED
}
```

- Shared by the domain model and the entity — this is the one type that legitimately spans
  both, because it carries no persistence or transport concern.
- Persist with `@Enumerated(EnumType.STRING)`, never `ORDINAL`: ordinals break the moment
  someone reorders the constants.
- An enum owned by module `ticket` stays in `ticket.model.enums`, even when another module
  reads it.
