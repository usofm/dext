---
name: dext-orm
description: Use the Dext ORM — define entities, create DbContext, query data with Smart Properties, and handle CRUD operations.
---

# Dext ORM

## Core Imports

```pascal
uses
  Dext.Entity;       // Facade: Table, Column, PK, AutoInc, Required, MaxLength, etc.
  Dext.Entity.Core;  // REQUIRED for generics: IDbSet<T>, TDbContext
  Dext.Collections;  // IList<T>, TCollections
```

> Use `Dext.Entity` for attributes.
> Use `Dext.Entity.Core` in any unit that declares `IDbSet<T>` properties.
> **NEVER** import `Dext.Entity.Attributes` directly.

## 1. Define an Entity

```pascal
unit MyProject.Domain.Entities;

interface
uses
  Dext.Entity; // All attributes available from here

type
  [Table('users')]
  TUser = class
  private
    FId: Integer;
    FName: string;
    FEmail: string;
    FCreatedAt: TDateTime;
    FIsActive: Boolean;
  public
    [PK, AutoInc]
    property Id: Integer read FId write FId;

    [Required, MaxLength(100)]
    property Name: string read FName write FName;

    [Required, MaxLength(200)]
    property Email: string read FEmail write FEmail;

    [CreatedAt]
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;

    property IsActive: Boolean read FIsActive write FIsActive;
  end;
```

### Attribute Declaration Style

Place multiple attributes on the same line, comma-separated:
```pascal
[Required, MaxLength(50), JSONName('code')]   // ✅ Correct
[Required]                                     // ❌ Avoid splitting
[MaxLength(50)]
```

## Available Attributes

### Table Mapping
| Attribute | Description |
|-----------|-------------|
| `[Table('name')]` | Map to specific table name |
| `[Table]` | Use Naming Strategy |
| `[Schema('schema')]` | Specify schema |

### Column Mapping
| Attribute | Description |
|-----------|-------------|
| `[PK]` | Primary key |
| `[AutoInc]` | Auto-increment (integer PK) |
| `[Column('name')]` | Map to specific column name |
| `[NotMapped]` | Exclude from DB and JSON |
| `[CreatedAt]` | Timestamp set on INSERT |
| `[UpdatedAt]` | Timestamp set on UPDATE |
| `[SoftDelete('col', 1, 0)]` | Logical deletion flag |
| `[Version]` | Optimistic concurrency |

### Validation
| Attribute | Description |
|-----------|-------------|
| `[Required]` | NOT NULL + validated on SaveChanges |
| `[MaxLength(N)]` | Max string length |
| `[MinLength(N)]` | Min string length |

> `[StringLength]` does **NOT** exist in Dext. Always use `[MaxLength(N)]`.

### Type Hints
| Attribute | Description |
|-----------|-------------|
| `[Precision(18, 2)]` | Decimal precision/scale |
| `[Default('value')]` | Database default |
| `[JsonColumn]` | Store as JSON in DB |
| `[DbType(ftGuid)]` | Force specific TFieldType |
| `[TypeConverter(TMyConverter)]` | Custom type converter |

### Relationships
| Attribute | Description |
|-----------|-------------|
| `[ForeignKey('col')]` | Foreign key column |
| `[InverseProperty('prop')]` | Navigation link |

## Nullable Columns

```pascal
uses
  Dext.Types.Nullable; // Required for Nullable<T>

type
  [Table('tickets')]
  TTicket = class
  private
    FAssigneeId: Nullable<Integer>;
  public
    [ForeignKey('Assignee')]
    property AssigneeId: Nullable<Integer> read FAssigneeId write FAssigneeId;
  end;

// Usage
Ticket.AssigneeId := AgentId;              // Integer → Nullable<Integer> implicit
if Ticket.AssigneeId.HasValue then
  WriteLn(Ticket.AssigneeId.Value);
var Id := Ticket.AssigneeId.GetValueOrDefault(0);
Ticket.AssigneeId := Nullable<Integer>.Null; // Set to NULL
```

> `NavType<T>` does **NOT** exist in Dext. Always use `Nullable<T>`.

## Entity Collections (Owned)

For `IList<T>` child collections tracked by DbContext:

```pascal
uses
  Dext.Collections; // IList<T>, TCollections

type
  [Table('orders')]
  TOrder = class
  private
    FItems: IList<TOrderItem>;
  public
    constructor Create;
    property Items: IList<TOrderItem> read FItems;
  end;

constructor TOrder.Create;
begin
  // ALWAYS pass False (OwnsObjects) — DbContext manages lifecycle
  FItems := TCollections.CreateList<TOrderItem>(False);
end;
```

> **Why `False`?** DbContext already manages entity lifecycle. `True` causes Double Free (Invalid Pointer Operation) on shutdown.
> In unit tests (no DbContext), you must **manually free** child items.

## 2. Create a DbContext

```pascal
unit MyProject.Data.Context;

interface
uses
  Dext.Entity.Core, // IDbSet<T>, TDbContext — REQUIRED for generics
  Dext.Entity;      // Facade

type
  TAppDbContext = class(TDbContext)
  private
    function GetUsers: IDbSet<TUser>;
    function GetOrders: IDbSet<TOrder>;
  public
    property Users: IDbSet<TUser> read GetUsers;
    property Orders: IDbSet<TOrder> read GetOrders;
  end;

implementation
uses
  MyProject.Domain.Entities;

function TAppDbContext.GetUsers: IDbSet<TUser>;
begin
  Result := Entities<TUser>;
end;

function TAppDbContext.GetOrders: IDbSet<TOrder>;
begin
  Result := Entities<TOrder>;
end;
```

> Expose `IDbSet<T>` as **properties** (not methods) to avoid syntactic ambiguities.
> `Dext.Entity.Core` is required in the interface section — `Dext.Entity` does not export generics.

## 3. Configure the Database (via DI)

```pascal
procedure TStartup.ConfigureServices(const Services: TDextServices; const Configuration: IConfiguration);
begin
  Services
    .AddDbContext<TAppDbContext>(ConfigureDatabase)
    .AddScoped<IUserService, TUserService>;
end;

procedure TStartup.ConfigureDatabase(Options: TDbContextOptions);
begin
  Options
    .UseSQLite('App.db')
    .WithPooling(True); // REQUIRED for production Web APIs
end;
```

Supported databases:
- `.UseSQLite('filename.db')`
- `.UsePostgreSQL('connection-string')`
- `.UseMySQL('connection-string')`
- `.UseSQLServer('connection-string')`

> **Always enable `.WithPooling(True)`** for Web APIs. They are multithreaded; without pooling you get connection exhaustion.

## 4. CRUD Operations

### Create

```pascal
var User := TUser.Create;
User.Name := 'Alice';
User.Email := 'alice@example.com';

Db.Users.Add(User);
Db.SaveChanges;

// User.Id is auto-populated — NEVER query the DB again for the ID
WriteLn('Created user ID: ', User.Id);
```

### Read

```pascal
// Find by primary key
var User := Db.Users.Find(1);

// All records
var All := Db.Users.ToList;

// First / FirstOrDefault
var First := Db.Users.First;           // Throws if empty
var First := Db.Users.FirstOrDefault;  // Returns nil if empty
```

### Update

```pascal
var User := Db.Users.Find(1);
User.Name := 'Bob';
Db.Users.Update(User);  // REQUIRED: mark entity as Modified
Db.SaveChanges;
```

> **Always** call `.Update(Entity)` before `SaveChanges`. Auto-tracking can fail silently for detached entities.

### Delete

```pascal
var User := Db.Users.Find(1);
Db.Users.Remove(User);
Db.SaveChanges;
```

### Create Tables

```pascal
if Db.EnsureCreated then
  // Schema was just created
```

## 5. Querying with Smart Properties

Smart Properties provide compile-time safe queries.

### Defining Smart Properties

```pascal
type
  TUserProps = record
    Id: Prop<Integer>;
    Name: Prop<string>;
    Email: Prop<string>;
    Age: Prop<Integer>;
    IsActive: Prop<Boolean>;
  end;

  [Table('users')]
  TUser = class
  public
    class var Props: TUserProps;  // Declare as class var
    // ... properties ...
  end;
```

### Querying — Recommended Pattern

Use inline `var` with camelCase alias, close to the query:

```pascal
// ✅ CORRECT: camelCase var alias
var u := TUser.Props;
var ActiveUsers := Db.Users
  .Where(u.IsActive = True)
  .ToList;

// Multiple conditions with AND/OR
var Results := Db.Users
  .Where((u.Age >= 18) and (u.Status = 'active'))
  .ToList;

// ❌ WRONG: Repeating TUser.Props for every field
Db.Users.Where((TUser.Props.Email = Email) and (TUser.Props.Age > 18))
```

### Filtering Operations

```pascal
var u := TUser.Props;

// Comparison
u.Age = 25        // Equal
u.Age <> 25       // Not equal
u.Age > 18        // Greater than
u.Age >= 18       // Greater or equal

// String
u.Name.Contains('John')
u.Name.StartsWith('J')
u.Name.EndsWith('son')
u.Email.IsNull
u.Email.IsNotNull

// IN clause
u.Status.In(['active', 'pending'])
u.Id.In([1, 2, 3])

// Logical
(u.Age >= 18) and (u.Age <= 65)
(u.Status = 'active') or (u.IsAdmin = True)
not u.IsDeleted
```

### Ordering

```pascal
var u := TUser.Props;

// ALWAYS use .Asc or .Desc — passing Prop directly causes E2010
var Users := Db.Users.QueryAll
  .OrderBy(u.Name.Asc)
  .ToList;

var Latest := Db.Orders.QueryAll
  .OrderBy(u.CreatedAt.Desc)
  .ToList;

// Multi-column
Db.Users.QueryAll
  .OrderBy(u.LastName.Asc)
  .OrderBy(u.FirstName.Asc)
  .ToList;
```

### Pagination

```pascal
var u := TUser.Props;
var Page := Db.Users.QueryAll
  .OrderBy(u.Id.Asc)
  .Skip(20)   // Skip first N
  .Take(10)   // Return next N
  .ToList;
```

### Aggregates

```pascal
var u := TUser.Props;

var Total := Db.Users.Count;
var ActiveCount := Db.Users.Where(u.IsActive = True).Count;
var HasAdmin := Db.Users.Where(u.Role = 'admin').Any;
```

### Projection

```pascal
type
  TUserDto = record
    Name: string;
    Email: string;
  end;

var u := Prototype.Entity<TUser>;
var Dtos := Db.Users
  .Select<TUserDto>([u.Name, u.Email])
  .ToList;
```

## 6. IList<T> — Dext Collections

ORM always returns `IList<T>`, not `TObjectList<T>`:

```pascal
uses
  Dext.Collections;  // IList<T>, TCollections

var Users: IList<TUser>;
Users := Db.Users.ToList;  // Returns IList<TUser>

for var User in Users do
  WriteLn(User.Name);
// No Free needed — IList<T> is interface-managed

// Create a new list manually
var MyList := TCollections.CreateList<TUser>;         // No ownership
var OwnedList := TCollections.CreateList<TUser>(True); // Owns objects (auto-frees)
```

## 7. Database Seeding

Seed in the `.dpr` before `App.Run`:

```pascal
class procedure TDbSeeder.Seed(const Provider: IServiceProvider);
begin
  var Scope := Provider.CreateScope;
  try
    var Db := Scope.ServiceProvider.GetService(TAppDbContext) as TAppDbContext;
    if Db.EnsureCreated then
    begin
      var u := TUser.Props;
      if not Db.Users.Where(u.Role = 'admin').Any then
      begin
        var Admin := TUser.Create;
        Admin.Name := 'Admin';
        Admin.Email := 'admin@example.com';
        Db.Users.Add(Admin);
        Db.SaveChanges;
      end;
    end;
  finally
    Scope := nil;
  end;
end;
```

## 8. Memory Management Notes

- `IDbSet<T>.Find` / `ToList` — entities tracked by DbContext, freed on context dispose.
- `Db.Detach(Entity)` removes from IdentityMap but does **NOT** free memory. Call `Entity.Free` separately.
- After `SaveChanges`, IDs on inserted entities are **already populated** — no re-query needed.

## Naming Conventions

Default: property name = column name. For new projects, override with a Naming Strategy:

```pascal
procedure TAppDbContext.OnModelCreating(Builder: TModelBuilder);
begin
  Builder.UseNamingStrategy(TSnakeCaseNamingStrategy);
end;
// TUser → table "user", CreatedAt → column "created_at"
```

Override specific names with `[Table('name')]` / `[Column('name')]`.

## Common Mistakes

| Wrong | Correct |
|-------|---------|
| `uses Dext.Entity.Attributes` | `uses Dext.Entity` |
| Missing `Dext.Entity.Core` for `IDbSet<T>` | Add `Dext.Entity.Core` to uses |
| `TObjectList<T>` return type | `IList<T>` from `Dext.Collections` |
| `[StringLength(N)]` attribute | `[MaxLength(N)]` |
| `NavType<T>` for nullable FK | `Nullable<T>` from `Dext.Types.Nullable` |
| `FItems := TList.Create` (OwnsObjects=True) | `TCollections.CreateList<T>(False)` |
| No `.Update(Entity)` before `SaveChanges` | Always call `.Update()` explicitly |
| Query DB again after SaveChanges to get ID | ID is already set on the entity |
| `.OrderBy(u.Name)` without `.Asc`/`.Desc` | `.OrderBy(u.Name.Asc)` |
| `TUser.Props.Field` per expression | `var u := TUser.Props; u.Field` |

## Examples

| Example | What it shows |
|---------|---------------|
| `Orm.EntityDemo` | Comprehensive ORM: CRUD, relationships, lazy loading, soft delete, concurrency |
| `Orm.EntityStyles` | Classic (native types) vs Smart Properties side-by-side comparison |
| `Web.SmartPropsDemo` | `StringType`, `CurrencyType` — type-safe fluent queries, model binding |
| `Dext.Examples.ComplexQuerying` | JSON fields, aggregations, reporting, date range filters |
