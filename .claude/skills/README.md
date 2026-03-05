# Dext Framework — Agent Skills

Focused instruction packages for writing correct, idiomatic **Dext** (Delphi modern framework) code.

## Available Skills

| Skill | File | Load When |
|-------|------|-----------|
| **dext-web** | `dext-web.md` | Building HTTP endpoints, Minimal APIs, Controllers, routing, model binding, Results pattern |
| **dext-orm** | `dext-orm.md` | ORM entities, DbContext, querying, Smart Properties, CRUD, migrations |
| **dext-di** | `dext-di.md` | Service registration, lifetimes (Scoped/Singleton/Transient), constructor injection, factory registration |
| **dext-testing** | `dext-testing.md` | Unit tests, Mock<T>, fluent assertions (Should), TestFixture, TearDown |
| **dext-auth** | `dext-auth.md` | JWT authentication, login endpoints, [Authorize], claims, TClaimsBuilder |
| **dext-app-structure** | `dext-app-structure.md` | Startup class, middleware pipeline, .dpr bootstrap, project layout, database seeding |
| **dext-collections** | `dext-collections.md` | IList<T>, TCollections, LINQ operations, ownership semantics, IChannel<T> |

## Trigger Guide

**Load `dext-web`** when:
- Creating or modifying HTTP endpoints (`MapGet`, `MapPost`, `[HttpGet]`, `[HttpPost]`)
- Writing controllers (`[ApiController]`, `TInterfacedObject`)
- Handling model binding, route parameters, query strings, headers
- Using `Results.Ok`, `Results.Created`, etc.

**Load `dext-orm`** when:
- Defining entity classes with `[Table]`, `[PK]`, `[Required]`, etc.
- Writing `TDbContext` subclasses with `IDbSet<T>` properties
- Querying with `.Where`, `.ToList`, `.Find`, Smart Properties
- Adding/updating/removing records, database seeding

**Load `dext-di`** when:
- Registering services with `.AddScoped`, `.AddSingleton`, `.AddTransient`
- Setting up `ConfigureServices` in a Startup class
- Injecting services via constructors or `[Inject]` attribute
- Using factory registration with `IServiceProvider`

**Load `dext-testing`** when:
- Writing `[TestFixture]` classes
- Using `Mock<T>` (from `Dext.Mocks`)
- Writing fluent assertions with `Should(...)`
- Setting up test projects (`.dpr`)

**Load `dext-auth`** when:
- Implementing JWT authentication
- Creating login endpoints
- Using `[Authorize]`, `[AllowAnonymous]`
- Building claims with `TClaimsBuilder`

**Load `dext-app-structure`** when:
- Creating a new Dext project from scratch
- Setting up the Startup class and middleware pipeline
- Configuring the `.dpr` entry point
- Organising project files and modules

**Load `dext-collections`** when:
- Using `IList<T>`, `TCollections.CreateList`, `TCollections.CreateObjectList`
- Writing LINQ-style queries on in-memory lists
- Using `IChannel<T>` for thread communication

## Key Framework Facts

- **Package**: Dext.Core, Dext.EF.Core, Dext.Web.Core, Dext.Testing, Dext.Net
- **Target**: Delphi 11 Alexandria and newer
- **Paradigm**: ASP.NET Core-inspired (Minimal APIs, Controller pattern, DI, ORM)
- **Source**: `$(DEXT)\Sources\` — set `DEXT` environment variable
- **Examples**: `$(DEXT)\Examples\` — 39 complete example projects
- **Docs**: `$(DEXT)\Docs\Book\` — 79 markdown chapters

## Critical Rules (Apply to All Skills)

1. **Route params use `{id}` syntax**, not `:id` (Express style)
2. **Route params in controllers MUST start with `/`**: `[HttpGet('/{id}')]`
3. **NEVER name a controller method `Create`** — conflicts with Delphi constructors (use `CreateUser`, `CreateOrder`, etc.)
4. **NEVER use `Ctx.RequestServices.GetService<T>`** — use generic type parameters
5. **NEVER use `TObjectList<T>`** for ORM results — use `IList<T>` from `Dext.Collections`
6. **NEVER use `[StringLength]`** — use `[MaxLength(N)]`
7. **NEVER use `NavType<T>`** — use `Nullable<T>` from `Dext.Types.Nullable`
8. **Always `.WithPooling(True)`** for Web API DbContexts
9. **Always call `.Update(Entity)` before `SaveChanges`** for detached entities
10. **`Mock<T>` is a Record** — never call `.Free` on it
