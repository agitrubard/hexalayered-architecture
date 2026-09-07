# Testing

Each layer is tested in isolation, with the layer below it mocked. That isolation is the
payoff for the layering — skipping it forfeits the reason to layer at all.

---

## The test matrix

| Under test | Test class | Mocked | Base class |
|---|---|---|---|
| `TicketController` | `TicketControllerTest` | the Service interfaces | `RestControllerTest` |
| `TicketCreateServiceImpl` | `TicketCreateServiceImplTest` | the Ports | `UnitTest` |
| `TicketAdapter` | `TicketAdapterTest` | the Repository | `UnitTest` |
| `TicketCodeGenerator` | `TicketCodeGeneratorTest` | nothing | `UnitTest` |
| the whole flow | `TicketEndToEndTest` | nothing (Testcontainers) | `EndToEndTest` |

Mappers are not unit-tested directly — MapStruct generates them, and the adapter and
controller tests already exercise them. Test a mapper only when it carries a hand-written
`default` or `@Named` method.

---

## Base classes

```java
// src/test/java/{BASE_PACKAGE}/UnitTest.java
@ExtendWith(MockitoExtension.class)
public abstract class UnitTest {
}
```

```java
// src/test/java/{BASE_PACKAGE}/RestControllerTest.java
@AutoConfigureMockMvc
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
public abstract class RestControllerTest {

    @Autowired
    protected MockMvc mockMvc;

    @Autowired
    protected ObjectMapper objectMapper;
}
```

```java
// src/test/java/{BASE_PACKAGE}/EndToEndTest.java
@AutoConfigureMockMvc
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
public abstract class EndToEndTest {
    // container configuration shared by every e2e test
}
```

---

## Naming and shape

Method names: `given<Precondition>_when<Event>_then<Outcome>`, or `when…_then…` when there is
no meaningful precondition. Bodies are sectioned.

```java
class TicketCreateServiceImplTest extends UnitTest {

    @InjectMocks
    private TicketCreateServiceImpl ticketCreateService;

    @Mock
    private TicketReadPort ticketReadPort;

    @Mock
    private TicketSavePort ticketSavePort;

    @Test
    void givenValidTicketCreateRequest_whenTicketCreated_thenReturnTicket() {

        // Given
        TicketCreateRequest mockRequest = new TicketCreateRequestBuilder()
                .withValidValues()
                .build();

        // When
        Mockito.when(ticketReadPort.existsByTitle(mockRequest.getTitle()))
                .thenReturn(false);

        Ticket mockTicket = new TicketBuilder()
                .withValidValues()
                .withTitle(mockRequest.getTitle())
                .build();

        Mockito.when(ticketSavePort.save(Mockito.any(Ticket.class)))
                .thenReturn(mockTicket);

        // Then
        Ticket ticket = ticketCreateService.create(mockRequest);

        Assertions.assertEquals(mockRequest.getTitle(), ticket.getTitle());
        Assertions.assertEquals(TicketStatus.OPEN, ticket.getStatus());

        // Verify
        Mockito.verify(ticketReadPort, Mockito.times(1))
                .existsByTitle(mockRequest.getTitle());
        Mockito.verify(ticketSavePort, Mockito.times(1))
                .save(Mockito.any(Ticket.class));
    }

    @Test
    void givenTicketCreateRequest_whenTitleAlreadyExists_thenThrowTicketAlreadyExistsByTitleException() {

        // Given
        TicketCreateRequest mockRequest = new TicketCreateRequestBuilder()
                .withValidValues()
                .build();

        // When
        Mockito.when(ticketReadPort.existsByTitle(mockRequest.getTitle()))
                .thenReturn(true);

        // Then
        Assertions.assertThrows(
                TicketAlreadyExistsByTitleException.class,
                () -> ticketCreateService.create(mockRequest)
        );

        // Verify
        Mockito.verify(ticketSavePort, Mockito.never())
                .save(Mockito.any(Ticket.class));
    }
}
```

`Mockito.verify(..., never())` on the negative path is what proves the guard actually
short-circuited, rather than the exception coming from somewhere else.

---

## Test data builders

Every type that appears in a test gets a builder in the mirrored test package. No object
literals scattered across test files.

```java
package dev.agitrubard.hexalayered.ticket.model;

public class TicketBuilder extends TestDataBuilder<Ticket> {

    public TicketBuilder() {
        super(Ticket.class);
    }

    public TicketBuilder withValidValues() {
        return this
                .withId(1L)
                .withCode("TCK-0001")
                .withTitle("Broken elevator on floor 3")
                .withDescription("The elevator stops between floors.")
                .withStatus(TicketStatus.OPEN);
    }

    public TicketBuilder withId(Long id) {
        data.setId(id);
        return this;
    }

    public TicketBuilder withTitle(String title) {
        data.setTitle(title);
        return this;
    }

    public TicketBuilder withStatus(TicketStatus status) {
        data.setStatus(status);
        return this;
    }
}
```

Why builders pay for themselves: adding a required field to `Ticket` is one edit in
`withValidValues()`, not fifty edits across the suite. And a test that overrides exactly one
field states its intent in one line.

---

## Controller tests

The service is mocked — a controller test proves routing, validation, and response shaping,
nothing else.

```java
class TicketControllerTest extends RestControllerTest {

    @MockitoBean
    private TicketCreateService ticketCreateService;

    private final TicketToTicketResponseMapper ticketToTicketResponseMapper =
            TicketToTicketResponseMapper.initialize();

    private static final String BASE_PATH = "/api/v1/ticket";

    @Test
    void givenValidTicketCreateRequest_whenTicketCreated_thenReturnTicketResponse() throws Exception {

        // Given
        TicketCreateRequest mockRequest = new TicketCreateRequestBuilder()
                .withValidValues()
                .build();

        // When
        Ticket mockTicket = new TicketBuilder().withValidValues().build();

        Mockito.when(ticketCreateService.create(Mockito.any(TicketCreateRequest.class)))
                .thenReturn(mockTicket);

        // Then
        mockMvc.perform(MockMvcRequestBuilders.post(BASE_PATH)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(mockRequest)))
                .andExpect(MockMvcResultMatchers.status().isOk())
                .andExpect(MockMvcResultMatchers.jsonPath("$.isSuccess").value(true))
                .andExpect(MockMvcResultMatchers.jsonPath("$.response.title")
                        .value(mockTicket.getTitle()));

        // Verify
        Mockito.verify(ticketCreateService, Mockito.times(1))
                .create(Mockito.any(TicketCreateRequest.class));
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {" ", "ab"})
    void givenInvalidTitle_whenTicketCreated_thenReturnValidationError(String invalidTitle) throws Exception {

        // Given
        TicketCreateRequest mockRequest = new TicketCreateRequestBuilder()
                .withValidValues()
                .withTitle(invalidTitle)
                .build();

        // Then
        mockMvc.perform(MockMvcRequestBuilders.post(BASE_PATH)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(mockRequest)))
                .andExpect(MockMvcResultMatchers.status().isBadRequest());

        // Verify
        Mockito.verify(ticketCreateService, Mockito.never())
                .create(Mockito.any(TicketCreateRequest.class));
    }
}
```

Validation boundaries are exactly what `@ParameterizedTest` is for — one method, every invalid
shape.

---

## Adapter tests

The repository is mocked; the mappers are real. This is where you prove Article II holds: the
adapter takes domain in and gives domain back.

```java
class TicketAdapterTest extends UnitTest {

    @InjectMocks
    private TicketAdapter ticketAdapter;

    @Mock
    private TicketRepository ticketRepository;

    @Test
    void givenTicketId_whenTicketFound_thenReturnTicket() {

        // Given
        Long mockId = 1L;

        // When
        TicketEntity mockEntity = new TicketEntityBuilder()
                .withValidValues()
                .withId(mockId)
                .build();

        Mockito.when(ticketRepository.findById(mockId))
                .thenReturn(Optional.of(mockEntity));

        // Then
        Optional<Ticket> ticket = ticketAdapter.findById(mockId);

        Assertions.assertTrue(ticket.isPresent());
        Assertions.assertEquals(mockEntity.getTitle(), ticket.get().getTitle());

        // Verify
        Mockito.verify(ticketRepository, Mockito.times(1)).findById(mockId);
    }
}
```

---

## End-to-end tests

Real HTTP, real Spring context, real database in a container. One per user-facing scenario —
the happy path plus the errors a client must be able to rely on. Not a substitute for the
isolated tests: e2e tells you the wiring works, unit tests tell you the logic is right.

---

## Coverage that means something

- Every business rule (`BR-###` in the spec) has a test that fails when the rule is removed.
- Every error case (`ER-###`) has a test asserting the exception type or HTTP status.
- Every `if` in a service has both branches covered.
- Every validation annotation on a request has at least one rejecting input.

A high coverage percentage with no assertion on the negative path proves nothing.

---

## Never

```java
// ❌ a test that asserts the mock
Mockito.when(port.findById(1L)).thenReturn(Optional.of(ticket));
Assertions.assertEquals(ticket, port.findById(1L).get());   // tests Mockito

// ❌ shared mutable state between tests
private static Ticket ticket = new Ticket();

// ❌ non-deterministic expectations
Assertions.assertEquals(LocalDateTime.now(), ticket.getCreatedAt());

// ❌ a name that says nothing
@Test void test1() { }
@Test void testCreate() { }

// ❌ several unrelated behaviours in one method
```
