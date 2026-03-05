---
name: dext-collections
description: Use Dext generic collections — IList<T>, IChannel<T>, LINQ operations, ownership semantics, and thread-safe concurrency patterns.
---

# Dext Collections

## Core Import

```pascal
uses
  Dext.Collections; // IList<T>, TCollections, IChannel<T>, TChannel<T>
```

## Why Dext Collections Instead of `TList<T>`?

| Problem with `TList<T>` | Dext Solution |
|-------------------------|---------------|
| Manual `.Free` required | `IList<T>` is interface-based — freed automatically via ARC |
| Verbose filtering loops | Built-in LINQ: `.Where`, `.Select`, `.Any`, `.First` |
| No ownership semantics | Explicit ownership via `CreateObjectList` vs `CreateList` |
| Not thread-safe | Lock-free `IChannel<T>` for concurrent scenarios |

## Creating Lists

```pascal
uses
  Dext.Collections;

// Object list — OWNS the objects (auto-frees them)
var Users := TCollections.CreateObjectList<TUser>;

// Non-owning list — stores references, does NOT free objects
var RefList := TCollections.CreateList<TUser>;

// Non-owning list (explicit False)
var RefList := TCollections.CreateList<TUser>(False);

// Primitive list (no ownership concept)
var Numbers := TCollections.CreateList<Integer>;
```

> Always refer to lists by their interface type `IList<T>`, not by the concrete class.
> `IList<T>` goes out of scope automatically — no `try/finally Free` needed.

## Ownership Semantics

| Factory | OwnsObjects | When to Use |
|---------|-------------|-------------|
| `CreateObjectList<T>` | `True` | You create objects and want the list to own them |
| `CreateList<T>` | `False` | ORM-returned entities (DbContext manages lifecycle) |
| `CreateList<T>(True)` | `True` | Manual ownership preference |
| `CreateList<T>(False)` | `False` | Shared references, no ownership |

**ORM Rule**: Always use `OwnsObjects = False` for entity child collections, because the DbContext already manages their lifecycle.

```pascal
constructor TOrder.Create;
begin
  // False = DbContext manages the items, not the list
  FItems := TCollections.CreateList<TOrderItem>(False);
end;
```

## Basic Operations

```pascal
var Users := TCollections.CreateObjectList<TUser>;

// Add
Users.Add(User1);
Users.AddRange([User2, User3]);

// Access
var Count := Users.Count;
var First := Users[0];
var Last := Users[Users.Count - 1];

// Remove
Users.Remove(User1);    // By reference
Users.Delete(0);        // By index
Users.Clear;            // Remove all (frees if OwnsObjects=True)

// Iterate
for var User in Users do
  WriteLn(User.Name);
```

## LINQ Operations

Use `Prototype.Entity<T>` for type-safe lambda expressions:

```pascal
uses
  Dext.Entity.Prototype; // Prototype.Entity<T>

var u := Prototype.Entity<TUser>;

// Filter
var Admins := Users.Where(u.Role = 'admin').ToList;
var Active := Users.Where(u.IsActive).ToList;
var Adults := Users.Where(u.Age >= 18).ToList;

// Check existence
if Users.Any(u.Role = 'admin') then
  WriteLn('Has admins');

// First match
var First := Users.FirstOrDefault(u.IsVip);  // nil if not found
var First := Users.First(u.IsVip);            // Throws if not found

// Project (transform)
var Names := Users.Select<string>(u.Name).ToList;  // IList<string>
```

### Performance: Lazy vs Eager Evaluation

`.Where` and `.Select` return **lazy iterators** — no copy is made immediately:

```pascal
// Efficient: no copy — just iterate
for var Admin in Users.Where(u.Role = 'admin') do
  Process(Admin);

// Required when storing or returning results
var AdminList := Users.Where(u.Role = 'admin').ToList; // IList<TUser>
Result := Users.Select<string>(u.Name).ToList;          // IList<string>
```

## IList\<T\> Interface — Key Members

```pascal
IList<T> = interface
  // Count & capacity
  function Count: Integer;
  function IsEmpty: Boolean;

  // Add
  procedure Add(const Item: T);
  procedure AddRange(const Items: array of T);

  // Access
  function Get(Index: Integer): T;       // or Items[Index]
  property Items[Index: Integer]: T;

  // Remove
  procedure Remove(const Item: T);
  procedure Delete(Index: Integer);
  procedure Clear;

  // Search
  function Contains(const Item: T): Boolean;
  function IndexOf(const Item: T): Integer;

  // LINQ
  function Where(Expr): IEnumerable<T>;
  function Select<TResult>(Expr): IEnumerable<TResult>;
  function Any(Expr): Boolean;
  function First(Expr): T;
  function FirstOrDefault(Expr): T;
  procedure ForEach(Action);

  // Conversion
  function ToList: IList<T>;
  function ToArray: TArray<T>;
end;
```

## IChannel\<T\> — Concurrent Communication

Go-inspired channels for lock-free thread communication.

```pascal
uses
  Dext.Collections; // IChannel<T>, TChannel<T>

// Bounded channel (backpressure — blocks producer when full)
var Chan := TChannel<TOrder>.CreateBounded(100);

// Unbounded channel (no limit — use cautiously)
var Chan := TChannel<TOrder>.CreateUnbounded;
```

### Producer / Consumer Pattern

```pascal
var Chan := TChannel<TOrder>.CreateBounded(100);

// Producer Thread
TTask.Run(procedure
  begin
    Chan.Write(Order1);
    Chan.Write(Order2);
    Chan.Close;  // Signal that no more items will be written
  end);

// Consumer Thread
TTask.Run(procedure
  begin
    while Chan.IsOpen do
      ProcessOrder(Chan.Read);
  end);
```

### Channel Operations

```pascal
Chan.Write(Item);        // Send item (blocks if bounded and full)
var Item := Chan.Read;   // Receive item (blocks if empty)
Chan.Close;              // Signal channel is done producing
var Open := Chan.IsOpen; // Check if still open and has items
```

## IList\<T\> vs TObjectList\<T\> — Quick Comparison

| Feature | `IList<T>` (Dext) | `TObjectList<T>` (RTL) |
|---------|-------------------|------------------------|
| Memory management | Automatic (interface) | Manual `.Free` required |
| LINQ operations | Built-in | None |
| ORM return type | ✅ Always | ❌ Never |
| Thread-safe | Use `IChannel<T>` | `TCriticalSection` needed |
| `try/finally Free` | Not needed | Required |

## Common Mistakes

| Wrong | Correct |
|-------|---------|
| `var List: TList<TUser>` | `var List: IList<TUser>` |
| `TList<TUser>.Create` | `TCollections.CreateList<TUser>` |
| `List.Free` | Not needed — interface-managed |
| `CreateObjectList` for ORM child collections | `CreateList(False)` — DbContext owns them |
| `.Where(...)` without `.ToList` when storing | Always call `.ToList` to materialise |
| `TChannel` with no backpressure on high volume | Use `CreateBounded(N)` |

## Examples

| Example | What it shows |
|---------|---------------|
| `Dext.Examples.ComplexQuerying` | LINQ-style queries on ORM result sets, aggregation, filtering |
| `Web.DextStore` | `IList<T>` used for cart items, order lines, product catalogues |
