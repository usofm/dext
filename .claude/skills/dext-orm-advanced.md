---
name: dext-orm-advanced
description: Advanced Dext ORM features — entity relationships, inheritance mapping (TPH/TPT), specifications, migrations, raw SQL (FromSql), stored procedures, pessimistic/optimistic locking, multi-tenancy, and JSON column queries.
---

# Dext ORM — Advanced Features

> For basic entity definition, DbContext, CRUD, and Smart Properties, see `dext-orm.md`.

## Relationships

### One-to-Many

```pascal
uses
  Dext.Entity, Dext.Types.Lazy; // ILazy<T>

type
  [Table('orders')]
  TOrder = class
  private
    FUserId: Integer;
    FUser: ILazy<TUser>;
    function GetUser: TUser;
    procedure SetUser(Value: TUser);
  public
    [PK, AutoInc] property Id: Integer;

    [ForeignKey('user_id')]
    property UserId: Integer read FUserId write FUserId;

    property User: TUser read GetUser write SetUser; // Lazy-loaded
  end;

  [Table('users')]
  TUser = class
  private
    FOrders: ILazy<TList<TOrder>>;
  public
    [PK, AutoInc] property Id: Integer;

    [InverseProperty('User')]
    property Orders: TList<TOrder> read GetOrders; // Lazy collection
  end;
```

### Many-to-Many

```pascal
type
  [Table('users')]
  TUser = class
  public
    [ManyToMany('user_roles', 'user_id', 'role_id')]
    property Roles: TList<TRole> read GetRoles;
  end;

  [Table('roles')]
  TRole = class
  public
    [ManyToMany('user_roles', 'role_id', 'user_id')]
    property Users: TList<TUser> read GetUsers;
  end;

// Link / Unlink
Db.Users.LinkManyToMany(User, 'Roles', AdminRole);
Db.Users.UnlinkManyToMany(User, 'Roles', AdminRole);
Db.Users.SyncManyToMany(User, 'Roles', [Role1, Role2]);
Db.SaveChanges;
```

### Include (Eager Loading — Avoid N+1)

```pascal
uses Dext.Entity.Prototype;

var o := Prototype.Entity<TOrder>;

// Type-safe include
var Orders := Db.Orders
  .Include(o.User)    // Loads User in same query
  .Include(o.Items)
  .ToList;

// Deep include (string path)
var Orders := Db.Orders
  .Include(o.User)
  .Include('Items.Product')
  .ToList;
```

### Cascade Delete

```pascal
[ForeignKey('user_id'), OnDeleteCascade]
property UserId: Integer;
```

## Inheritance Mapping

### Table Per Hierarchy (TPH) — Default

All classes share one table; a discriminator column identifies the type:

```pascal
type
  [Table('people')]
  [Inheritance(TablePerHierarchy)]
  [DiscriminatorColumn('person_type')]
  TPerson = class
  public
    [PK, AutoInc] Id: Integer;
    Name: string;
  end;

  [DiscriminatorValue('student')]
  TStudent = class(TPerson)
  public
    EnrollmentNumber: string;
  end;

  [DiscriminatorValue('teacher')]
  TTeacher = class(TPerson)
  public
    Subject: string;
  end;

// Polymorphic query — returns TStudent and TTeacher instances
var People := Db.People.ToList;
for var P in People do
  if P is TStudent then
    WriteLn(TStudent(P).EnrollmentNumber);
```

TPH is fast — no JOINs needed for polymorphic queries.

### Table Per Type (TPT) — Normalized Schema

Each class gets its own table, sharing the PK:

```pascal
type
  [Table('vehicles')]
  [Inheritance(TablePerType)]
  TVehicle = class
  public
    [PK] Id: Integer;
    Brand: string;
  end;

  [Table('cars')]
  TCar = class(TVehicle)
  public
    NumberOfDoors: Integer;
  end;
```

## Specifications

Encapsulate reusable, composable query predicates:

```pascal
uses Dext.Specifications;

type
  TActiveAdultSpec = class(TSpecification<TUser>)
  public
    function IsSatisfiedBy(Entity: TUser): Boolean; override;
    function ToExpression: TSpecExpression; override;
  end;

function TActiveAdultSpec.IsSatisfiedBy(Entity: TUser): Boolean;
begin
  Result := Entity.IsActive and (Entity.Age >= 18);
end;

function TActiveAdultSpec.ToExpression: TSpecExpression;
begin
  var u := TUser.Props;
  Result := (u.IsActive = True) and (u.Age >= 18);
end;

// Usage
var Spec := TActiveAdultSpec.Create;
var Users := Db.Users.Where(Spec).ToList;
```

### Combining Specifications

```pascal
var Active := TActiveUserSpec.Create;
var Adult  := TAdultUserSpec.Create;

var Combined := Active.And(Adult);           // AND
var Either   := AdminSpec.Or(ModeratorSpec); // OR
var Inactive := ActiveSpec.Not;              // NOT

// Parameterized
var ByAge := TAgeRangeSpec.Create(MinAge, MaxAge);
```

## Migrations

```pascal
unit Migration_001_CreateUsers;

interface
uses
  Dext.Entity.Migrations;

type
  [Migration(1, 'CreateUsers')]
  TMigration_001_CreateUsers = class(TMigration)
  public
    procedure Up; override;
    procedure Down; override;
  end;

implementation

procedure TMigration_001_CreateUsers.Up;
begin
  CreateTable('users', procedure(T: TTableBuilder)
    begin
      T.AddColumn('id').AsInteger.PrimaryKey.AutoIncrement;
      T.AddColumn('name').AsString(100).NotNull;
      T.AddColumn('email').AsString(255).NotNull.Unique;
      T.AddColumn('created_at').AsDateTime.Default('CURRENT_TIMESTAMP');
    end);
end;

procedure TMigration_001_CreateUsers.Down;
begin
  DropTable('users');
end;
```

### Table Builder API

```pascal
T.AddColumn('id').AsInteger.PrimaryKey.AutoIncrement
T.AddColumn('name').AsString(100).NotNull
T.AddColumn('email').AsString(255).Nullable
T.AddColumn('price').AsDecimal(10, 2).Default('0.00')
T.AddColumn('active').AsBoolean.Default('true')
T.AddColumn('created_at').AsDateTime
T.AddColumn('data').AsText    // TEXT/CLOB
T.AddColumn('blob').AsBlob
T.AddColumn('uuid').AsGuid

// Constraints
T.AddColumn('email').AsString(255).Unique
T.AddForeignKey('user_id', 'users', 'id').OnDeleteCascade
T.AddIndex('idx_email', 'email')
T.AddUniqueIndex('idx_email_unique', 'email')

// Alter
AlterTable('users', procedure(T: TTableBuilder)
  begin
    T.AddColumn('phone').AsString(20).Nullable;
    T.DropColumn('legacy');
    T.RenameColumn('name', 'full_name');
  end);

// Raw SQL
Execute('CREATE INDEX CONCURRENTLY ...');
```

Register migrations — add to the program's `uses` clause:
```pascal
uses
  Migration_001_CreateUsers,
  Migration_002_AddEmailIndex;
// Dext auto-discovers [Migration] attributed classes
```

### Migration CLI

```bash
dext migrate:up               # Apply pending
dext migrate:down             # Rollback last
dext migrate:list             # Show status
dext migrate:generate --name AddOrdersTable
```

## Raw SQL with FromSql

```pascal
// Basic
var Users := Db.Users.FromSql('SELECT * FROM Users WHERE Active = 1').ToList;

// Parameterized (always use params to prevent injection)
var Adults := Db.Users
  .FromSql('SELECT * FROM Users WHERE Age >= :Age', [MinAge])
  .ToList;

// Chain fluent API after FromSql
var List := Db.Users
  .FromSql('SELECT * FROM Users WHERE Role = :Role', ['Admin'])
  .Where(Prop('Active') = True)
  .OrderBy(Prop('Name'))
  .Skip(10).Take(5)
  .ToList;

// Large result sets — streaming
var Query := Db.Users.FromSql('SELECT * FROM Users');
var Iterator := TSqlQueryIterator<TUser>.Create(Query);
try
  while Iterator.Next do
    ProcessUser(Iterator.Current);
finally
  Iterator.Free;
end;
```

`.AsNoTracking` — read-only, not tracked by DbContext.

## Stored Procedures

```pascal
type
  TMyProcs = class
  public
    [StoredProcedure('sp_GetCustomerBalance')]
    procedure GetBalance(
      [DbParam(pdInput)] CustomerId: Integer;
      [DbParam(pdOutput)] out Balance: Currency
    );

    [StoredProcedure('fn_GetActiveCustomers')]
    function GetActiveCustomers(
      [DbParam(pdInput)] RegionId: Integer
    ): IList<TCustomer>;
  end;

// Execute
var Procs := ServiceProvider.GetService<TMyProcs>;
var Balance: Currency;
Procs.GetBalance(123, Balance);

// Multiple result sets
var Results := Db.ExecuteProcedure('sp_GetInvoicesAndItems', [CustomerId]);
var Invoices := Results.Read<TInvoice>;
var Items    := Results.Read<TInvoiceItem>;
```

`[DbParam]` directions: `pdInput`, `pdOutput`, `pdInputOutput`, `pdReturnValue`.

## Locking

### Optimistic (Version Column)

```pascal
type
  [Table('products')]
  TProduct = class
  public
    [PK, AutoInc] property Id: Integer;
    [Version] property Version: Integer; // Auto-incremented by Dext on update
  end;

// On conflict, SaveChanges raises DbUpdateConcurrencyException
```

### Pessimistic (Lock at Query Time)

```pascal
var Product := Db.Products
  .Where(Prop('Id') = 1)
  .Lock(TLockMode.Update)  // FOR UPDATE / UPDLOCK
  .FirstOrDefault;

Product.Price := Product.Price * 1.1;
Db.SaveChanges;
// Lock released when transaction ends
```

| Mode | SQL |
|------|-----|
| `TLockMode.None` | (default) |
| `TLockMode.Update` | `FOR UPDATE` / `UPDLOCK` |
| `TLockMode.Shared` | `FOR SHARE` / `HOLDLOCK` |

### Offline Locking

```pascal
var Token := Db.LockManager.AcquireLock('TProduct', ProductId, TenantId);
if Token <> '' then
  // Record is locked for this session
  ...
  Db.LockManager.ReleaseLock(Token);
```

## Multi-Tenancy

### Strategy 1: Shared DB (Column-Based)

```pascal
type
  [Table('orders')]
  TOrder = class(TObject, ITenantAware)
  public
    [PK] property Id: Integer;
    property TenantId: string; // Auto-populated by DbContext
    property Description: string;
  end;
  // Or inherit from TTenantEntity
```

Configure in pipeline:
```pascal
App.Builder.UseMultiTenancy(procedure(Options: TMultiTenancyOptions)
  begin
    Options.ResolveFromHeader('X-Tenant'); // or ResolveFromHost
  end);
```

All queries automatically get `WHERE TenantId = 'current-tenant'`.

### Strategy 2: Schema Isolation

```pascal
App.Builder.UseMultiTenancy(procedure(Options: TMultiTenancyOptions)
  begin
    Options.Strategy := TTenancyStrategy.Schema;
    Options.ResolveFromHost; // customer1.myapp.com → schema "customer1"
  end);
```

## Examples

| Example | What it shows |
|---------|---------------|
| `Orm.EntityDemo` | Relationships, lazy loading, soft delete, optimistic concurrency |
| `Orm.Specification` | Specification pattern with expression trees and SQL generation |
| `Dext.Examples.ComplexQuerying` | JSON column queries, aggregations, advanced filtering |
| `Dext.Examples.MultiTenancy` | SaaS multi-tenant: tenant middleware, data isolation, per-tenant scoping |
