---
name: dext-database-as-api
description: Expose full REST CRUD endpoints automatically from Dext ORM entities with zero boilerplate using TDataApiHandler. Use when you need instant GET/POST/PUT/DELETE for an entity without writing controllers or services.
---

# Dext Database as API (Zero-Code CRUD)

Generate a complete REST API for an entity with a single line. No controller, no service, no repository needed.

## Core Import

```pascal
uses
  Dext.Web.DataApi; // TDataApiHandler<T>
```

> 📦 Example: `Web.DatabaseAsApi`

## Quick Start

```pascal
// Entity
type
  [Table('products')]
  TProduct = class
  public
    [PK, AutoInc] property Id: Integer;
    [Required, MaxLength(100)] property Name: string;
    property Price: Double;
    property Stock: Integer;
  end;

// In Startup Configure — maps all 5 CRUD endpoints
App.Builder
  .UseExceptionHandler
  .Map(TDataApiHandler<TProduct>, '/api/products')
  .UseSwagger(...);
```

## Generated Endpoints

| HTTP | URL | Description |
|------|-----|-------------|
| `GET` | `/api/products` | List all (pagination + filters) |
| `GET` | `/api/products/{id}` | Find by ID |
| `POST` | `/api/products` | Create new record |
| `PUT` | `/api/products/{id}` | Update existing record |
| `DELETE` | `/api/products/{id}` | Delete record |

## Query Parameters (Auto-Supported)

### Pagination & Ordering

```
GET /api/products?page=1&pageSize=20
GET /api/products?orderBy=Name&desc=true
```

### Filtering

```
GET /api/products?Name=Keyboard       # Exact match
GET /api/products?Price_gt=100        # Greater than
GET /api/products?Price_lt=500        # Less than
GET /api/products?Stock_gte=1         # Greater or equal
GET /api/products?Status_in=Active,Pending  # IN filter
```

## Restricting Operations

```pascal
App.Builder.Map(TDataApiHandler<TProduct>, '/api/products',
  procedure(Options: TDataApiOptions)
  begin
    Options.AllowedOperations := [ToRead, ToCreate]; // Read + Create only
    Options.RequireAuthorization := True;             // Requires JWT
  end);
```

Available operations: `ToRead`, `ToCreate`, `ToUpdate`, `ToDelete`.

## Multiple Entities

```pascal
App.Builder
  .UseExceptionHandler
  .UseAuthentication
  .Map(TDataApiHandler<TProduct>, '/api/products')
  .Map(TDataApiHandler<TCategory>, '/api/categories')
  .Map(TDataApiHandler<TOrder>, '/api/orders',
    procedure(O: TDataApiOptions)
    begin
      O.AllowedOperations := [ToRead];  // Read-only
      O.RequireAuthorization := True;
    end)
  .UseSwagger(...);
```

## When to Use vs When to Write a Controller

| Use `TDataApiHandler` | Write a Controller/Service |
|-----------------------|---------------------------|
| Simple CRUD for internal/admin tools | Complex business logic on save/delete |
| Rapid prototyping | Validation beyond ORM attributes |
| Read-only data exposure | Custom response shapes |
| Admin dashboards | Multi-entity transactions |

## Examples

| Example | What it shows |
|---------|---------------|
| `Web.DatabaseAsApi` | Zero-code CRUD: `TDataApiHandler<T>`, snake_case JSON, Swagger auto-docs |
