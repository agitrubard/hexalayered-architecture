# 🏛️ HexaLayered Architecture

## Table of Contents

1. [Summary](#summary)
2. [Architecture Overview](#architecture-overview)
3. [Layers and Responsibilities](#layers-and-responsibilities)
    - [Controller Layer](#1-controller-layer)
    - [Service Layer](#2-service-layer)
    - [Port/Adapter Layer](#3-portadapter-layer)
    - [Repository Layer](#4-repository-layer)
4. [Naming Conventions](#naming-conventions)
5. [Advantages and Solved Problems](#advantages-and-solved-problems)
6. [Best Practices](#best-practices)
7. [Modular Structure](#modular-structure)
8. [Contribute](#contribute)
9. [License](#license)
10. [FAQ](#faq)

## Summary

HexaLayered Architecture is an innovative architectural approach developed for Spring Boot applications, combining the
advantages of Hexagonal (Ports and Adapters) and Layered architectures. This architecture aims to develop scalable and
sustainable applications by combining modularity and simplicity.

The name "HexaLayered" reflects the combination of two basic architectural approaches:

- **Hexa-**: Comes from Hexagonal Architecture. This architecture aims to isolate the core of the application from the
  outside world and manage dependencies.
- **-Layered**: Inspired by the traditional Layered Architecture. This is based on the principle of dividing the
  application into layers with specific responsibilities.

HexaLayered Architecture offers a flexible, sustainable and understandable architectural solution for modern Spring Boot
applications.

This architectural approach:

- Reduces entity addiction
- Increases modularity
- Facilitates the implementation of Domain-Driven Design principles
- Increases testability
- Limits the impact of changes
- Facilitates code organization and maintenance

Thanks to its modular port, adapter and service structure, it offers the flexibility to independently develop and modify
different parts of the application. This architecture facilitates the organization and maintenance of code, improves
testability, and ensures long-term sustainability, even in large and complex projects.

When using HexaLayered Architecture, following the best practices mentioned above will allow you to make the most of the
advantages provided by the architecture. Remember that each project may have its own unique requirements and adapt this
architecture to the needs of your project when necessary.

This architectural approach guides software development teams in writing clean, modular and sustainable code. As a
result, HexaLayered Architecture offers a powerful architectural solution that supports modern software development
practices, helping you create scalable and durable applications.

---

## Architecture Overview

HexaLayered Architecture consists of four main layers:

1. **Controller Layer**
2. **Service Layer**
3. **Port/Adapter Layer**
4. **Repository Layer**

These layers communicate with each other through specific interfaces, and each has its own responsibilities.

---

## Layers and Responsibilities

### 1. Controller Layer

**Meets HTTP requests, processes request objects, and returns appropriate response objects.**

- **Package**: `dev.agitrubard.hexalayered.[module].controller`
- **Input**: Request Object | `TicketCreateRequest`
- **Output**: Response Object | `TicketResponse`
- **Communication**: It communicates directly with the Service Layer.
- **Access Modifier**:
    - Controller classes should be `package-private`

**Example:**

```java
package dev.agitrubard.hexalayered.ticket.controller;

@RestController
class TicketController {

    private final TicketCreateService ticketCreateService;

    TicketController(TicketCreateService ticketCreateService) {
        this.ticketCreateService = ticketCreateService;
    }

    @PostMapping("/api/v1/ticket")
    SuccessResponse<TicketResponse> create(@RequestBody TicketCreateRequest request) {
        Ticket ticket = ticketCreateService.createTicket(request);
        TicketResponse ticketResponse = TicketToResponseMapper.map(ticket);
        return SuccessResponse.of(ticket);
    }
}
```

### 2. Service Layer

**Executes business logic, performs necessary validations and performs operations on domain objects.**

- **Package**:
    - Interface: `dev.agitrubard.hexalayered.[module].service`
    - Implementation: `dev.agitrubard.hexalayered.[module].service.impl`
- **Input**: Request Object or specific wrapper objects | `TicketCreateRequest` or `Long` or `String` etc.
- **Output**: Domain Object or specific wrapper objects | `Ticket` or `Long` or `String` etc.
- **Communication**:
    - The service interface is called by the Controller.
    - ServiceImpl communicates with the Port/Adapter Layer using Port interfaces.
- **Access Modifier**:
    - Service interfaces should be `public`
    - Service implementation classes should be `package-private`

**Example:**

```java
package dev.agitrubard.hexalayered.ticket.service;

public interface TicketCreateService {
    Ticket create(TicketCreateRequest request);
}
```

```java
package dev.agitrubard.hexalayered.ticket.service.impl;

class TicketCreateServiceImpl implements TicketCreateService {

    private final TicketSavePort ticketSavePort;

    TicketCreateServiceImpl(TicketSavePort ticketSavePort) {
        this.ticketSavePort = ticketSavePort;
    }

    @Override
    public Ticket create(TicketCreateRequest request) {
        Ticket ticket = new Ticket(request.getTitle(), request.getDescription());
        return ticketSavePort.saveTicket(ticket);
    }
}
```

### 3. Port/Adapter Layer

**Provides communication with external systems, converts domain objects into formats that external systems can
understand
and does the opposite.**

- **Package**:
    - Port: `dev.agitrubard.hexalayered.[module].port`
    - Adapter: `dev.agitrubard.hexalayered.[module].port.adapter`
- **Input**: Domain Object or specific wrapper objects | `Ticket` or `Long` or `String` etc.
- **Output**: Domain Object or specific wrapper objects | `Ticket` or `Long` or `String` etc.
- **Communication**:
    - Port interfaces are called by service implementations
    - Adapters (port implementations) communicate with the repository layer.
- **Access Modifier**:
    - Port interfaces should be `public`
    - Adapter classes should be `package-private`

**Example:**

```java
package dev.agitrubard.hexalayered.ticket.port;

public interface TicketSavePort {

    Ticket save(Ticket ticket);

}
```

```java
package dev.agitrubard.hexalayered.ticket.port.adapter;

class TicketSaveAdapter implements TicketSavePort {

    private final TicketRepository ticketRepository;

    TicketSaveAdapter(TicketRepository ticketRepository) {
        this.ticketRepository = ticketRepository;
    }

    @Override
    public Ticket save(Ticket ticket) {
        TicketEntity entity = TicketToEntityMapper.map(ticket);
        TicketEntity savedEntity = ticketRepository.save(entity);
        return TicketEntityToDomainMapper.map(savedEntity);
    }
}
```

### 4. Repository Layer

**Performs database operations, manages CRUD operations on entity objects.**

- **Paket**: `dev.agitrubard.hexalayered.[module].repository`
- **Input**: Entity Object or specific wrapper objects | `TicketEntity` or `Long` or `String` etc.
- **Output**: Entity Object or specific wrapper objects | `TicketEntity` or `Long` or `String` etc.
- **Communication**: Called by adapters (port implementations).
- **Access Modifier**: `public`

**Example:**

```java
package dev.agitrubard.hexalayered.ticket.repository;

public interface TicketRepository extends JpaRepository<TicketEntity, Long> {
}
```

---

## Naming Conventions

1. **Controller**:
    - Package: `dev.agitrubard.hexalayered.[module].controller`
    - Class: `[Domain]Controller` | `TicketController`, `InstitutionController`

2. **Service**:
    - Package:
        - Interface Package: `dev.agitrubard.hexalayered.[module].service`
        - Implementation Package: `dev.agitrubard.hexalayered.[module].service.impl`
    - Interface: `[Domain][Action]Service` | `TicketCreationService`, `InstitutionUpdateService`
    - Implementation: `[Domain][Action]ServiceImpl` | `TicketCreationServiceImpl`, `InstitutionUpdateServiceImpl`

3. **Port & Adapter**:
    - Package:
        - Interface Package: `dev.agitrubard.hexalayered.[module].port`
        - Implementation Package: `dev.agitrubard.hexalayered.[module].port.adapter`
    - Interface: `[Domain][Action]Port` | `TicketSavePort`, `InstitutionReadPort`
    - Implementation: `[Domain][Action]Adapter` | `TicketSaveAdapter`, `InstitutionReadAdapter`

4. **Repository**:
    - Package: `dev.agitrubard.hexalayered.[module].repository`
    - Interface: `[Domain]Repository` | `TicketRepository`, `InstitutionRepository`

5. **Domain Model**:
    - Package: `dev.agitrubard.hexalayered.[module].model`
    - Class: `[Domain]` | `Ticket`, `Institution`

6. **Entity**:
    - Package: `dev.agitrubard.hexalayered.[module].model.entity`
    - Class: `[Domain]Entity` | `TicketEntity`, `InstitutionEntity`

7. **Request**:
    - Package: `dev.agitrubard.hexalayered.[module].model.request`
    - Class: `[Domain][Action]Request` | `TicketCreateRequest`, `InstitutionUpdateRequest`

8. **Response**:
    - Package: `dev.agitrubard.hexalayered.[module].model.response`
    - Class: `[Domain]Response` or `[Domain][Action]Response` | `TicketResponse`, `InstitutionResponse`

9. **Exception**:
    - Package: `dev.agitrubard.hexalayered.[module].exception`
    - Class: `[ErrorAction]Exception` | `TicketNotFoundByIdException`

10. **Util**:

- Package: `dev.agitrubard.hexalayered.[module].util`
- Class: `[Name]Util` or `[Name][Action]Util` or `[Domain][Action]` | `FileUtil` or `FileReadUtil` or `
  TicketCodeGenerator`

---

## Advantages and Solved Problems

**1. Reducing Entity Dependency**:

- By highlighting the use of domain objects, it prevents the use of entity objects throughout the application.
- Entity objects cannot leave the adapter layer, so the rest of the application is not affected when the database
  structure changes.

**2. Modularity and Insulation**:

- Each module is independent in itself and isolated from other modules.
- Changes only affect the relevant module, other modules are not affected.

**3. Modular Port, Adapter and Service Structure**:

- Separate port, adapter and service classes can be created for each function.
- This structure supports the Single Responsibility Principle (SRP) and reduces code repetition.

**4. Clean Architecture**:

- Clearly separates the inner and outer layers.
- Dependencies are from the inside out, the outer layers are not dependent on the inner layers.

**5. Easy Testability**:

- Each layer can be tested independently.
- Isolated tests can be written using mock objects.

**6. DDD Compliance**:

- Facilitates the implementation of Domain-Driven Design principles.
- Domain objects are located in the center of the application.

**7. Flexibility and Interchangeability**:

- Interaction with external systems can be easily changed via Port/Adapter Layer.
- It is easier to add new features or change existing features.

---

## Best Practices

1. **Layer Insulation**: Ensure that each layer fulfills its responsibility and is isolated from the details of the
   other layers.
2. **Centrality of Domain Objects**: Put domain objects in the center of the application and execute business logic over
   these objects.
3. **Dependency Injection**: Use Dependency Injection (DI) to manage interlayer dependencies.
4. **Naming Consistency**: Sticky adhere to the specified naming standards. This facilitates the readability and
   maintenance of the code.
5. **Protecting the Modular Structure**: Make each module independent in itself. Keep inter-module dependencies to a
   minimum.
6. **Port and Adapter Separation**: Create a separate adapter for each port. This makes it easy to switch between
   different implementations.
7. **Service Modularity**: Design the services in a thin modular structure with a single responsibility.
8. **Exception Handling**: Create custom exception classes for each layer and manage them appropriately.
9. **Validation**: Perform business rule validations in the service layer and input validations in the controller layer.
10. **Mapper Usage**: Use dedicated mapper classes for object transformations between different layers.
11. **Immutable Objects**: Use immutable objects as much as possible, especially for domain objects.
12. **Documentation**: Provide adequate documentation for each module, service and important class.

---

## Modular Structure

HexaLayered Architecture divides the application into modules according to different business domains. Each module
contains the above-mentioned layers.

Below is an example of an application structure that includes the Common, Ticket and Institution modules:

```
dev.agitrubard.hexalayered
├── common
│   │
│   ├── configuration
│   │   └── DataSourceConfiguration
│   │
│   ├── exception
│   │   ├── handler
│   │   │   └── GlobalExceptionHandler
│   │   ├── AbstractNotFoundException
│   │   ├── AbstractServerException
│   │   └── FileReadException
│   │
│   ├── model
│   │   ├── entity
│   │   │   └── BaseEntity
│   │   ├── mapper
│   │   │   └── BaseMapper
│   │   ├── response
│   │   │   ├── ErrorResponse
│   │   │   └── SuccessResponse
│   │   └── BaseDomainModel
│   │
│   └── util
│       ├── FileUtil
│       └── ListUtil
│
│
├── ticket
│   │
│   ├── controller
│   │   └── TicketController
│   │
│   ├── exception
│   │   └── TicketNotFoundByIdException
│   │
│   ├── service
│   │   ├── TicketCreateService
│   │   ├── TicketUpdateService
│   │   ├── TicketDeleteService
│   │   └── impl
│   │       ├── TicketCreateServiceImpl
│   │       ├── TicketUpdateServiceImpl
│   │       └── TicketDeleteServiceImpl
│   │
│   ├── port
│   │   ├── TicketSavePort
│   │   ├── TicketReadPort
│   │   ├── TicketDeletePort
│   │   └── adapter
│   │       ├── TicketSaveAdapter
│   │       ├── TicketReadAdapter
│   │       └── TicketDeleteAdapter
│   │
│   ├── repository
│   │   └── TicketRepository
│   │
│   ├── model
│   │   ├── entity
│   │   │   └── TicketEntity
│   │   ├── enums
│   │   │   └── TicketStatus
│   │   ├── mapper
│   │   │   ├── TicketToEntityMapper
│   │   │   └── TicketEntityToDomainMapper
│   │   ├── request
│   │   │   ├── TicketCreateRequest
│   │   │   └── TicketUpdateRequest
│   │   ├── response
│   │   │   └── TicketResponse
│   │   └── Ticket
│   │
│   └── util
│       └── TicketCodeGenerator
│
│
└── institution
    │
    ├── controller
    │   └── InstitutionController
    │
    ├── exception
    │   ├── InstitutionAlreadyExistByNameException
    │   └── InstitutionNotFoundByIdException
    │
    ├── service
    │   ├── InstitutionService
    │   └── impl
    │       └── InstitutionServiceImpl
    │
    ├── port
    │   ├── InstitutionSavePort
    │   ├── InstitutionReadPort
    │   ├── InstitutionDeletePort
    │   └── adapter
    │       └── InstitutionAdapter
    │
    ├── repository
    │   └── InstitutionRepository
    │
    └── model
        ├── entity
        │   └── InstitutionEntity
        ├── enums
        │   └── InstitutionStatus
        ├── mapper
        │   ├── InstitutionToEntityMapper
        │   └── InstitutionEntityToDomainMapper
        ├── request
        │   ├── InstitutionCreateRequest
        │   └── InstitutionUpdateRequest
        ├── response
        │   └── InstitutionResponse
        └── Institution
```

---

## Contribute

We can work together to develop and improve HexaLayered Architecture. You can review
the [CONTRIBUTING.md](CONTRIBUTING.md) file to contribute.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## FAQ

**1. How can I integrate HexaLayered Architecture into my current project?**

```
You can progressively migrate your current project to HexaLayered Architecture. Start by developing new modules with
this architecture, and gradually transform existing modules over time. Begin with the most isolated parts of your
application and work your way towards more integrated components.
```

**2. Is HexaLayered Architecture compatible with microservices architecture?**

```
Yes, HexaLayered Architecture is highly compatible with microservices. Each microservice can implement the HexaLayered
Architecture internally, providing a consistent structure across your microservices ecosystem while maintaining loose
coupling between services.
```

**3. How does HexaLayered Architecture improve testability?**

```
HexaLayered Architecture improves testability by clearly separating concerns and dependencies. Each layer can be tested
in isolation using mocks or stubs for its dependencies. This allows for more focused unit tests, easier integration
tests, and overall better test coverage.
```

**4. What's the difference between Ports and Adapters in this architecture?**

```
Ports are interfaces that define how the application interacts with external systems or how external systems interact
with the application. Adapters are the concrete implementations of these interfaces. This separation allows for easy
swapping of implementations without changing the core business logic.
```

**5. How do I handle cross-cutting concerns in HexaLayered Architecture?**

```
Cross-cutting concerns like logging, security, and transaction management can be handled using aspects (AOP) or by
implementing these concerns in the appropriate layers. For example, security checks can be done in the Controller layer,
while transaction management might be handled in the Service layer.
```

**6. Can I use HexaLayered Architecture with other frameworks besides Spring Boot?**

```
While the examples provided are in Spring Boot, the principles of HexaLayered Architecture are framework-agnostic. You
can apply this architecture to projects using other frameworks or even in different programming languages, adapting the
implementation details as necessary.
```

**7. How does HexaLayered Architecture support Domain-Driven Design (DDD)?**

```
HexaLayered Architecture aligns well with DDD principles. The domain model remains at the core of the application,
isolated from external concerns. The Port and Adapter layers help in creating a clear boundary between the domain and
infrastructure, which is a key aspect of DDD.
```

**8. What are the performance implications of using HexaLayered Architecture?**

```
Generally, the performance impact of HexaLayered Architecture is minimal. While it may introduce a slight overhead due
to additional layers and mappings, the benefits in terms of maintainability and flexibility usually outweigh this.
Proper implementation and optimization can mitigate most performance concerns.
```

**9. How do I handle database transactions across multiple services in HexaLayered Architecture?**

```
For transactions spanning multiple services, you can use distributed transaction management techniques like the Saga
pattern or two-phase commit protocol. Alternatively, you might reconsider your domain boundaries to minimize the need
for cross-service transactions.
```

**10. Is HexaLayered Architecture suitable for small projects?**

```
While HexaLayered Architecture shines in medium to large projects, it might be overkill for very small applications.
However, if you anticipate your project growing in complexity, starting with this architecture can set a solid
foundation for future expansion.
```

**11. How do I manage dependencies between different modules in HexaLayered Architecture?**

```
Dependencies between modules should be managed through well-defined interfaces. If one module needs functionality from
another, this should be exposed through a port (interface) and accessed via an adapter. This maintains the modularity
and allows for easier changes in the future.
```

**12. Can I use HexaLayered Architecture with event-driven systems?**

```
Yes, HexaLayered Architecture works well with event-driven systems. Events can be treated as a type of port, with
adapters handling the publishing and subscribing to these events. This allows the core domain logic to remain isolated
from the specifics of the event system being used.
```

**13. If I don't have a very comprehensive service, should I still separate it according to tasks like Read, Write?**

```
It depends on the complexity and potential growth of your service. For simpler services, it's often acceptable to keep
read and write operations in a single service class. However, if you anticipate that the service might grow in
complexity or if you want to maintain consistency with larger services in your project, separating them can be
beneficial.
Key considerations:

If the service has distinct read and write logic that doesn't overlap significantly, separation might be cleaner.

If you foresee the service growing more complex in the future, early separation can make future changes easier. For very simple CRUD operations, a single service might be more pragmatic.
Consistency across your project is important. If other services are separated, maintaining the same pattern could be
beneficial for developer familiarity.

Remember, the goal is to balance clean architecture principles with practical development needs. It's okay to start with
a single service and refactor later if needed.
```

**14. If I don't have a very comprehensive port/adapter,
should I still separate it according to tasks like Read, Write?**

```
Similar to services, the decision to separate ports and adapters depends on the complexity of the operations and the
potential for future growth. Here are some guidelines:

For simple CRUD operations, a single port/adapter pair might be sufficient. For example, a TicketPort and TicketAdapter
could handle all basic operations.

If read and write operations have significantly different concerns (e.g., different external systems, caching
strategies, or transaction requirements), separation might be beneficial.

Consider the Single Responsibility Principle. If read and write operations have distinct responsibilities or might
evolve independently, separating them could make the code more maintainable.

Think about testing: if separating read and write operations would make your tests cleaner and more focused, it might be
worth doing.

Consider the consistency with your service layer. If you've separated your services into read and write, it might make
sense to reflect this in your ports and adapters.

Ultimately, the decision should be based on your specific use case, the complexity of your domain, and your team's
preferences. It's perfectly acceptable to start with a single port/adapter and refactor later if the need arises. The
key is to keep your code organized, maintainable, and aligned with your project's overall architecture.
```

**15. How do I decide when to create separate classes for different operations versus keeping them in one class?**

```
This decision applies to both services and ports/adapters. Consider the following factors:

Complexity: If the logic for different operations (e.g., read, write, update) is complex and distinct, separate classes
might be clearer.

Size: If a single class is becoming too large (e.g., over 300 lines), it might be time to split it.
Change frequency: If certain operations change more frequently than others, separating them can isolate changes.

Reusability: If some operations are reused across different contexts, separating them can promote code reuse.
Team structure: If different team members or teams are responsible for different operations, separation can help with
parallel development.

Performance: In some cases, separating read and write operations can help with optimizing each for its specific needs (
e.g., read optimization vs. write consistency).

Remember, the goal of HexaLayered Architecture is to create a clean, maintainable, and flexible codebase. The level of
granularity should serve this goal without introducing unnecessary complexity.
```

**16. Should I always create interfaces? What happens if I don't create an interface?**

```
In HexaLayered Architecture, interfaces are crucial for certain components but not always necessary for every class. Here's a guideline:

When to use interfaces:
1. Ports: Always use interfaces for ports. This is essential for the hexagonal architecture aspect.
2. Services: Generally use interfaces for services, especially if multiple implementations are possible.
3. Complex components: Use interfaces for components that might have different implementations in the future.

When interfaces might not be needed:
1. Simple data objects or DTOs
2. Utility classes
3. Classes unlikely to have multiple implementations

Consequences of not using interfaces:
- Reduced flexibility in swapping implementations
- More difficult to mock for testing
- Potential for tighter coupling between components

Best practice:
Use interfaces where they provide clear benefits (like in ports and services), but avoid creating unnecessary abstractions for simple or stable components.

Remember, the goal is to balance flexibility and simplicity in your architecture.
```