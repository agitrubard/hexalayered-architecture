# Module Blueprint — `[module]`

Use this when creating a **brand-new feature module**. Every path below is mandatory unless
marked *optional*; a module that skips a layer has already broken Article I or III.

`[module]` = lowercase package segment (`ticket`) · `[Domain]` = PascalCase noun (`Ticket`)

---

## Package tree

```
{BASE_PACKAGE}.[module]
│
├── controller
│   └── [Domain]Controller                      package-private  @RestController
│
├── service
│   ├── [Domain]CreateService                   public interface
│   ├── [Domain]ReadService                     public interface
│   ├── [Domain]UpdateService                   public interface
│   ├── [Domain]DeleteService                   public interface
│   └── impl
│       ├── [Domain]CreateServiceImpl           package-private  @Service
│       ├── [Domain]ReadServiceImpl             package-private  @Service
│       ├── [Domain]UpdateServiceImpl           package-private  @Service
│       └── [Domain]DeleteServiceImpl           package-private  @Service
│
├── port
│   ├── [Domain]ReadPort                        public interface
│   ├── [Domain]SavePort                        public interface
│   ├── [Domain]DeletePort                      public interface
│   └── adapter
│       └── [Domain]Adapter                     package-private  @Component
│
├── repository
│   └── [Domain]Repository                      public interface  extends JpaRepository
│
├── exception
│   ├── [Domain]NotFoundByIdException           public  extends AbstractNotFoundException
│   └── [Domain]AlreadyExistsByNameException    public  extends AbstractConflictException
│
├── model
│   ├── [Domain]                                public  extends BaseDomainModel
│   ├── [Domain]Filter                          public  (optional — list/search)
│   ├── entity
│   │   └── [Domain]Entity                      public  extends BaseEntity  @Entity
│   ├── enums
│   │   └── [Domain]Status                      public enum
│   ├── mapper
│   │   ├── [Domain]ToEntityMapper              public interface  @Mapper
│   │   ├── [Domain]EntityToDomainMapper        public interface  @Mapper
│   │   └── [Domain]To[Domain]ResponseMapper    public interface  @Mapper
│   ├── request
│   │   ├── [Domain]CreateRequest               public
│   │   └── [Domain]UpdateRequest               public
│   └── response
│       └── [Domain]Response                    public
│
└── util                                        (optional)
    └── [Domain]CodeGenerator                   public final
```

Mirrored test tree:

```
{BASE_PACKAGE}.[module]
├── controller
│   ├── [Domain]ControllerTest                  extends RestControllerTest
│   └── [Domain]EndToEndTest                    extends EndToEndTest
├── service/impl
│   └── [Domain][Action]ServiceImplTest         extends UnitTest
├── port/adapter
│   └── [Domain]AdapterTest                     extends UnitTest
└── model
    ├── [Domain]Builder
    ├── entity/[Domain]EntityBuilder
    └── request/[Domain]CreateRequestBuilder
```

---

## Creation checklist

Work **inside-out**. Tick as you go.

### 1. Domain core
- [ ] `model/enums/[Domain]Status.java` — the states from the spec's lifecycle column
- [ ] `model/[Domain].java` — `extends BaseDomainModel`, `@Getter @Setter @SuperBuilder`,
      behaviour methods (`isActive()`, …) live here, not in the service
- [ ] test: `model/[Domain]Builder.java` with `withValidValues()`

### 2. Persistence
- [ ] `model/entity/[Domain]Entity.java` — `@Entity`, `@Table(name = "[DOMAIN]")`,
      `extends BaseEntity`; **no business methods**
- [ ] test: `model/entity/[Domain]EntityBuilder.java`
- [ ] `model/mapper/[Domain]ToEntityMapper.java` — `@Mapper`, `extends BaseMapper<[Domain], [Domain]Entity>`, static `initialize()`
- [ ] `model/mapper/[Domain]EntityToDomainMapper.java` — the reverse
- [ ] `repository/[Domain]Repository.java` — `public interface … extends JpaRepository<[Domain]Entity, ID>`

### 3. Ports & adapters
- [ ] `port/[Domain]ReadPort.java` — `public interface`; signatures use **domain** types only
- [ ] `port/[Domain]SavePort.java`
- [ ] `port/[Domain]DeletePort.java`
- [ ] test: `port/adapter/[Domain]AdapterTest.java` (repository mocked)
- [ ] `port/adapter/[Domain]Adapter.java` — package-private `@Component`,
      `@Transactional(readOnly = true)`, mappers as `initialize()` fields.
      **This is the only place `[Domain]Entity` and `[Domain]Repository` may both appear.**

### 4. Business logic
- [ ] `exception/[Domain]NotFoundByIdException.java` — `@Serial serialVersionUID`
- [ ] `service/[Domain][Action]Service.java` — one interface per action
- [ ] test: `service/impl/[Domain][Action]ServiceImplTest.java` (ports mocked)
- [ ] `service/impl/[Domain][Action]ServiceImpl.java` — package-private `@Service`,
      `@RequiredArgsConstructor`; business rules validated here

### 5. API surface
- [ ] `model/request/[Domain]CreateRequest.java` — Jakarta validation annotations
- [ ] test: `model/request/[Domain]CreateRequestBuilder.java`
- [ ] `model/response/[Domain]Response.java`
- [ ] `model/mapper/[Domain]To[Domain]ResponseMapper.java`
- [ ] test: `controller/[Domain]ControllerTest.java` (service mocked)
- [ ] `controller/[Domain]Controller.java` — package-private `@RestController`,
      `@Valid` on request bodies, wraps output in `SuccessResponse`

### 6. Wiring & closure
- [ ] Migration script for the new table
- [ ] `sh .claude/scripts/check-architecture.sh --all` exits 0
- [ ] Full test suite green
- [ ] `controller/[Domain]EndToEndTest.java` covers the primary scenario

---

## Granularity guidance

Before splitting a service or port per action, apply README FAQ #13–#15:

| Signal | Split into `Read` / `Create` / `Update` / `Delete` | Keep as one |
|---|---|---|
| Read and write logic barely overlap | ✅ | |
| The class is heading past ~300 lines | ✅ | |
| Different parts change at very different rates | ✅ | |
| Read needs caching, write needs transactions | ✅ | |
| Plain CRUD, thin logic, small domain | | ✅ |
| The rest of the codebase is already split | ✅ (consistency) | |
| The rest of the codebase is already unified | | ✅ (consistency) |

Starting unified and splitting later is legitimate. Starting split "just in case" and never
filling the classes is not.

---

## Common module (`common`) — create once per project

```
{BASE_PACKAGE}.common
├── configuration/           DataSourceConfiguration, OpenApiConfiguration, …
├── exception/
│   ├── handler/GlobalExceptionHandler
│   ├── AbstractNotFoundException
│   ├── AbstractConflictException
│   └── AbstractServerException
├── model/
│   ├── BaseDomainModel                audit fields for domain models
│   ├── entity/BaseEntity              audit columns for entities
│   ├── mapper/BaseMapper<S, T>        map(S) / map(List<S>)
│   └── response/
│       ├── SuccessResponse
│       ├── ErrorResponse
│       └── PageResponse
└── util/                              FileUtil, ListUtil, RandomUtil, …
```

`common` depends on **no** feature module. Every feature module may depend on `common`.
