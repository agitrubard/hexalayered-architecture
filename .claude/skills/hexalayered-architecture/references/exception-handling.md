# Exception Handling

One rule shapes everything else: **the layer that detects the problem throws; a single handler
in `common` decides what the client sees.** No `try/catch` for domain errors anywhere in
between.

---

## The hierarchy

```
RuntimeException
└── common.exception
    ├── AbstractNotFoundException      → 404
    ├── AbstractConflictException      → 409
    ├── AbstractForbiddenException     → 403
    ├── AbstractAuthException          → 401
    └── AbstractServerException        → 500
        └── ticket.exception
            ├── TicketNotFoundByIdException          extends AbstractNotFoundException
            ├── TicketAlreadyExistsByTitleException  extends AbstractConflictException
            └── TicketStatusNotValidException        extends AbstractConflictException
```

Abstract bases live in `common.exception` and carry the HTTP semantics. Concrete exceptions
live in **their own module** and carry the message.

```java
package dev.agitrubard.hexalayered.common.exception;

public abstract class AbstractNotFoundException extends RuntimeException {

    @Serial
    private static final long serialVersionUID = 5804417337541293201L;

    protected AbstractNotFoundException(String message) {
        super(message);
    }
}
```

```java
package dev.agitrubard.hexalayered.ticket.exception;

public final class TicketNotFoundByIdException extends AbstractNotFoundException {

    @Serial
    private static final long serialVersionUID = -8080466932594432592L;

    public TicketNotFoundByIdException(Long id) {
        super("ticket does not exist! ID:" + id);
    }
}
```

Conventions that matter:

- `public final` — nobody subclasses a leaf exception.
- `@Serial private static final long serialVersionUID` — required, and a distinct value.
- The constructor takes the **identifying values**, and builds the message itself. Callers
  never format messages.
- The message names what was looked for and by what. It ends up in logs; make it useful.

---

## Who throws what

| Layer | Throws | Example |
|---|---|---|
| Controller | nothing — Bean Validation raises `MethodArgumentNotValidException` | |
| ServiceImpl | module business exceptions | `TicketNotFoundByIdException`, `TicketStatusNotValidException` |
| Adapter | infrastructure exceptions only | `FileReadException`, a wrapped client failure |
| Repository | Spring Data exceptions — left alone | |

```java
@Service
@RequiredArgsConstructor
class TicketCloseServiceImpl implements TicketCloseService {

    private final TicketReadPort ticketReadPort;
    private final TicketSavePort ticketSavePort;

    @Override
    public Ticket close(Long id, TicketCloseRequest request) {

        Ticket ticket = ticketReadPort.findById(id)
                .orElseThrow(() -> new TicketNotFoundByIdException(id));

        ticket.close(request.getReason());          // model enforces the transition

        return ticketSavePort.save(ticket);
    }
}
```

A read port returns `Optional<Ticket>` and the **service** decides that absence is an error —
the port has no opinion about whether "not found" is exceptional.

---

## The global handler

One `@RestControllerAdvice` in `common.exception.handler` maps exception → HTTP.

```java
package dev.agitrubard.hexalayered.common.exception.handler;

@Slf4j
@RestControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(AbstractNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    ErrorResponse handle(AbstractNotFoundException exception) {
        log.warn(exception.getMessage());
        return ErrorResponse.notFound(exception.getMessage());
    }

    @ExceptionHandler(AbstractConflictException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    ErrorResponse handle(AbstractConflictException exception) {
        log.warn(exception.getMessage());
        return ErrorResponse.conflict(exception.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    ErrorResponse handle(MethodArgumentNotValidException exception) {
        return ErrorResponse.validationError(exception.getBindingResult());
    }

    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    ErrorResponse handle(Exception exception) {
        log.error(exception.getMessage(), exception);
        return ErrorResponse.serverError();   // never leak the message to the client
    }
}
```

Handlers are registered against the **abstract** types, so a new module exception is covered
the moment it extends the right base. Nobody edits the handler to add an exception.

**Log levels:** expected business outcomes are `warn` (or `info`); only genuine failures are
`error` with a stack trace. A 404 that logs `error` with a stack trace makes real errors
invisible.

---

## Response envelope

```java
// success
{ "time": "…", "code": "…", "isSuccess": true,  "response": { … } }

// failure
{ "time": "…", "code": "…", "isSuccess": false, "header": "NOT_EXIST", "message": "…" }
```

The `code` is a per-request identifier: it goes into the log line and the response, so a user
report can be traced to a log entry. Never put a stack trace, a SQL fragment, or an internal
class name in `message`.

---

## Validation, split by layer

| Question | Layer | Mechanism | On failure |
|---|---|---|---|
| Is `title` present and ≤ 200 chars? | Controller | `@NotBlank @Size` on the request | 400 |
| Is `status` a known enum value? | Controller | Bean Validation / deserialization | 400 |
| Does ticket 42 exist? | ServiceImpl | port lookup | `TicketNotFoundByIdException` → 404 |
| Is that title already taken? | ServiceImpl | port lookup | `…AlreadyExists…Exception` → 409 |
| May this user close this ticket? | Controller (`@PreAuthorize`) + ServiceImpl (ownership) | | 403 |
| Is OPEN → CLOSED legal? | Domain model | `Ticket.close()` | `TicketStatusNotValidException` → 409 |

The dividing line: **if the check needs data, it is a business rule and belongs in the
service (or the model). If it can be answered from the payload alone, it is input validation
and belongs on the request.**

---

## Never

```java
// ❌ swallowing
try { ticketSavePort.save(ticket); } catch (Exception e) { log.error("failed"); }

// ❌ catching domain errors in the controller — that is the handler's job
try { return ticketReadService.findById(id); }
catch (TicketNotFoundByIdException e) { return ResponseEntity.notFound().build(); }

// ❌ untyped errors
throw new RuntimeException("ticket not found");

// ❌ control flow by exception
try { read(id); } catch (TicketNotFoundByIdException e) { create(id); }
//    use ticketReadPort.existsById(id) instead

// ❌ leaking internals
return ErrorResponse.of(exception.getStackTrace());
```
