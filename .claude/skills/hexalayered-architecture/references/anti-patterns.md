# Anti-Patterns

Each entry: the symptom, why it breaks the architecture, and the corrected code. This is the
highest-leverage file in the skill — most architectural decay is one of these fifteen.

---

## 1. Entity above the adapter

**Article II.** The single most damaging violation.

```java
// ❌
package dev.agitrubard.hexalayered.ticket.service.impl;

import dev.agitrubard.hexalayered.ticket.model.entity.TicketEntity;

class TicketReadServiceImpl implements TicketReadService {

    private final TicketReadPort ticketReadPort;

    public TicketEntity findById(Long id) {
        return ticketReadPort.findEntityById(id);
    }
}
```

**Why it breaks things.** Renaming a column now ripples through the service, the controller,
the response and the tests. The entire benefit of the port layer is gone, and the JSON
response is now silently coupled to the schema — including lazy-loading surprises when Jackson
serializes an uninitialized proxy.

```java
// ✅
class TicketReadServiceImpl implements TicketReadService {

    private final TicketReadPort ticketReadPort;

    public Ticket findById(Long id) {
        return ticketReadPort.findById(id)
                .orElseThrow(() -> new TicketNotFoundByIdException(id));
    }
}
```

The port returns `Optional<Ticket>`; the adapter maps entity → domain and the entity stops
there.

---

## 2. Repository injected above the adapter

**Article I.**

```java
// ❌
@Service
class TicketCreateServiceImpl implements TicketCreateService {
    private final TicketRepository ticketRepository;
}
```

The service is now bound to JPA. Swapping persistence, or testing without a database mindset,
means rewriting the service.

```java
// ✅
@Service
@RequiredArgsConstructor
class TicketCreateServiceImpl implements TicketCreateService {
    private final TicketSavePort ticketSavePort;
}
```

---

## 3. Controller reaching past the service

**Article I.**

```java
// ❌
@RestController
class TicketController {
    private final TicketReadPort ticketReadPort;      // skips the service
    private final TicketRepository ticketRepository;  // skips two layers
}
```

"It is only a read, there is no logic" — until authorization, filtering or an audit
requirement arrives, and there is no layer to put it in.

```java
// ✅
@RestController
@RequiredArgsConstructor
class TicketController {
    private final TicketReadService ticketReadService;
}
```

---

## 4. Public implementation classes

**Article IV.**

```java
// ❌
public class TicketCreateServiceImpl implements TicketCreateService { }
public class TicketAdapter implements TicketSavePort { }
public class TicketController { }
```

A public implementation can be imported and depended on directly, which defeats the interface
and defeats the compiler's ability to enforce Article I.

```java
// ✅
class TicketCreateServiceImpl implements TicketCreateService { }
class TicketAdapter implements TicketReadPort, TicketSavePort { }
class TicketController { }
```

Interfaces (`TicketCreateService`, `TicketSavePort`, `TicketRepository`) stay `public`.

---

## 5. Skipping the interface

**Article III.** README FAQ #16 is explicit: interfaces are mandatory regardless of perceived
need.

```java
// ❌
@Service
public class TicketService {                    // no contract
    private final TicketRepository repository;  // and no port
}
```

```java
// ✅
public interface TicketCreateService { Ticket create(TicketCreateRequest request); }

@Service
@RequiredArgsConstructor
class TicketCreateServiceImpl implements TicketCreateService {
    private final TicketSavePort ticketSavePort;
}
```

---

## 6. Business logic in the controller

**Article VIII.**

```java
// ❌
@PostMapping("/api/v1/ticket")
SuccessResponse<TicketResponse> create(@RequestBody TicketCreateRequest request) {

    if (ticketReadService.existsByTitle(request.getTitle())) {
        throw new TicketAlreadyExistsByTitleException(request.getTitle());
    }
    if (request.getPriority() == null) {
        request.setPriority(Priority.NORMAL);
    }
    ...
}
```

That rule is now untestable without MockMvc, and unreachable from any other entry point — a
scheduled job or a message consumer would have to duplicate it.

```java
// ✅ the controller only translates
@PostMapping("/api/v1/ticket")
SuccessResponse<TicketResponse> create(@RequestBody @Valid TicketCreateRequest request) {
    Ticket ticket = ticketCreateService.create(request);
    return SuccessResponse.of(ticketToTicketResponseMapper.map(ticket));
}
```

---

## 7. Anemic domain model

**Article VIII / README §Best Practices 2.**

```java
// ❌ the service manipulates fields the model should own
class TicketCloseServiceImpl implements TicketCloseService {
    public Ticket close(Long id) {
        Ticket ticket = ...;
        if (ticket.getStatus() != TicketStatus.OPEN) {
            throw new TicketStatusNotValidException(id, ticket.getStatus());
        }
        ticket.setStatus(TicketStatus.CLOSED);
        ticket.setClosedAt(LocalDateTime.now());
        return ticketSavePort.save(ticket);
    }
}
```

The same three lines will be re-written in every other service that closes a ticket, and one
of them will forget the guard.

```java
// ✅ the model owns its own transitions
public class Ticket extends BaseDomainModel {

    public void close() {
        if (!this.isOpen()) {
            throw new TicketStatusNotValidException(this.id, this.status);
        }
        this.status = TicketStatus.CLOSED;
        this.closedAt = LocalDateTime.now();
    }
}

class TicketCloseServiceImpl implements TicketCloseService {
    public Ticket close(Long id) {
        Ticket ticket = ticketReadPort.findById(id)
                .orElseThrow(() -> new TicketNotFoundByIdException(id));
        ticket.close();
        return ticketSavePort.save(ticket);
    }
}
```

---

## 8. Hand-rolled mapping

**Article VII.**

```java
// ❌
TicketEntity entity = new TicketEntity();
entity.setTitle(ticket.getTitle());
entity.setDescription(ticket.getDescription());
entity.setStatus(ticket.getStatus());
// ... and the field added next sprint, silently dropped
```

```java
// ✅
private final TicketToEntityMapper ticketToEntityMapper = TicketToEntityMapper.initialize();

TicketEntity entity = ticketToEntityMapper.map(ticket);
```

---

## 9. Reaching into another module

**Article VI.**

```java
// ❌ ticket importing institution's internals
import dev.agitrubard.hexalayered.institution.repository.InstitutionRepository;
import dev.agitrubard.hexalayered.institution.model.entity.InstitutionEntity;

class TicketCreateServiceImpl implements TicketCreateService {
    private final InstitutionRepository institutionRepository;
}
```

The two modules are now one, and any change to institution's schema breaks ticket.

```java
// ✅ through institution's public contract
import dev.agitrubard.hexalayered.institution.model.Institution;
import dev.agitrubard.hexalayered.institution.service.InstitutionReadService;

class TicketCreateServiceImpl implements TicketCreateService {
    private final InstitutionReadService institutionReadService;
}
```

If institution exposes nothing suitable, **add a service or port to institution** — do not
reach around it.

---

## 10. Ports that speak persistence

**Article II, subtler form.**

```java
// ❌ the port leaks the storage model through its signature
public interface TicketReadPort {
    TicketEntity findEntityById(Long id);
    List<TicketEntity> findAllByStatusColumn(String status);
}
```

```java
// ✅ the port speaks the domain
public interface TicketReadPort {
    Optional<Ticket> findById(Long id);
    List<Ticket> findAllByStatus(TicketStatus status);
    boolean existsByTitle(String title);
}
```

A port is a promise to the domain, not a thin wrapper over a repository.

---

## 11. `Manager`, `Helper`, `Util` as a layer

**Article V.**

```java
// ❌
@Component
public class TicketManager {          // which layer is this?
    public void processTicket(...) { }
}
```

A class whose name does not map to a layer is a class the architecture has no place for. Ask
what it actually does: business rules → a service; talking to something external → a port and
adapter; a pure function → a `*Util` in `util`, `final`, with a private constructor and no
dependencies.

```java
// ✅
public interface TicketCloseService { Ticket close(Long id); }

// or, for a genuinely pure helper
public final class TicketCodeGenerator {
    private TicketCodeGenerator() { }
    public static String generate() { ... }
}
```

---

## 12. Fat request objects doing business validation

**Article VIII.**

```java
// ❌ a request that needs a database to validate itself
public class TicketCreateRequest {
    @InstitutionMustBeActive          // custom validator that injects a repository
    private Long institutionId;
}
```

Validation that needs data is a business rule. Putting it in a Bean Validation constraint hides
it from the service, makes it untestable in isolation, and quietly opens a database call
inside deserialization.

```java
// ✅ shape on the request, rule in the service
public class TicketCreateRequest {
    @NotNull
    private Long institutionId;
}

class TicketCreateServiceImpl implements TicketCreateService {
    public Ticket create(TicketCreateRequest request) {
        Institution institution = institutionReadService.findById(request.getInstitutionId());
        if (!institution.isActive()) {
            throw new InstitutionNotActiveException(institution.getId());
        }
        ...
    }
}
```

---

## 13. Returning the domain model as the API response

**Article I / README §Best Practices 10.**

```java
// ❌
@GetMapping("/api/v1/ticket/{id}")
SuccessResponse<Ticket> findById(@PathVariable Long id) {
    return SuccessResponse.of(ticketReadService.findById(id));
}
```

The API contract is now whatever the domain happens to contain. An internal field added next
month leaks to every client.

```java
// ✅
@GetMapping("/api/v1/ticket/{id}")
SuccessResponse<TicketResponse> findById(@PathVariable Long id) {
    Ticket ticket = ticketReadService.findById(id);
    return SuccessResponse.of(ticketToTicketResponseMapper.map(ticket));
}
```

---

## 14. God service

**README FAQ #13, #15.**

```java
// ❌ 900 lines, twelve ports, four concerns
@Service
class TicketServiceImpl implements TicketService {
    // create, read, update, delete, export, notify, archive, report...
}
```

Split by action once read and write logic stop overlapping, the class passes ~300 lines, or the
parts change at different rates:

```java
// ✅
public interface TicketCreateService { }
public interface TicketReadService { }
public interface TicketUpdateService { }
public interface TicketDeleteService { }
```

The mirror-image mistake is real too: four one-method services in a thin CRUD module is
ceremony. Start unified, split when a signal appears.

---

## 15. `@Transactional` in the wrong place

**Article VIII.**

```java
// ❌ on the controller — the transaction now spans HTTP serialization
@Transactional
@PostMapping("/api/v1/ticket")
SuccessResponse<TicketResponse> create(...) { }
```

```java
// ✅ at the persistence boundary
@Component
@Transactional(readOnly = true)
class TicketAdapter implements TicketReadPort, TicketSavePort {

    @Override
    @Transactional
    public Ticket save(Ticket ticket) { ... }
}
```

For one logical operation spanning several ports, put `@Transactional` on the `ServiceImpl`
method — never above it.

---

## Review checklist

Run through this before calling a change done:

- [ ] No `*Entity` import outside `model.entity`, `repository`, `port.adapter`, `model.mapper`.
- [ ] No `*Repository` import outside `port.adapter`.
- [ ] `*Controller`, `*ServiceImpl`, `*Adapter` are package-private.
- [ ] `*Service`, `*Port`, `*Repository` are `public interface`.
- [ ] Every class is in the package its suffix demands.
- [ ] Cross-module imports touch only `service`, `port` or `model` of the other module.
- [ ] No hand-rolled field copying.
- [ ] Business rules are in the service or the model, not the controller and not the request.
- [ ] The controller returns a `*Response`, never a domain model or an entity.
- [ ] Every new service impl, adapter and controller has a test.

Then: `sh .claude/scripts/check-architecture.sh --all`
