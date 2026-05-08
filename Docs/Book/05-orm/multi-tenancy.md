# Multi-Tenancy

Implement SaaS applications with transparent data isolation.

## Multi-Tenancy Strategies

Dext supports three main strategies:

1. **Shared Database (Column-based isolation)**
2. **Separate Schema (PostgreSQL/SQL Server)**
3. **Separate Database**

## Shared Database (Column-based)

Add the `ITenantAware` interface to your classes, and Dext will automatically apply filters to all queries and populate the `TenantId` on save.

```pascal
type
  [Table('orders')]
  TOrder = class(TObject, ITenantAware)
  private
    FTenantId: string;
    // ...
  public
    [PK] property Id: Integer;
    property TenantId: string read FTenantId write FTenantId; // Isolation column
    property Description: string;
  end;
```

> 💡 **Tip**: You can inherit from `TTenantEntity` to get a default implementation of `ITenantAware`.

## Auto-Population

When you save a new entity that implements `ITenantAware`, the `DbContext` automatically populates the `TenantId` using the current `ITenantProvider`:

1. The entity is tracked by the `DbContext`.
2. During `SaveChanges`, the framework detects `ITenantAware`.
3. It assigns `FTenantProvider.Tenant.Id` to the entity.
4. The record is persisted with the correct isolation ID.

This ensures that even if you forget to set the tenant ID in your business logic, the data remains isolated and secure.

## Configuring Tenant via Middleware

The framework resolves the current tenant through the request (Header, Host, Query, etc.):

```pascal
App.UseMultiTenancy(procedure(Options: TMultiTenancyOptions)
  begin
    // Resolve tenant from 'X-Tenant' header
    Options.ResolveFromHeader('X-Tenant');
  end);
```

## Schema Isolation (Dynamic Schema)

For higher security and performance, you can use separate schemas (e.g., PostgreSQL `search_path` or SQL Server schemas). Dext implements this through **Dynamic Schema Resolution**:

1. **Configuration**:
   ```pascal
   App.UseMultiTenancy(procedure(Options: TMultiTenancyOptions)
     begin
       Options.Strategy := TTenancyStrategy.Schema;
       Options.ResolveFromHeader('X-Tenant');
     end);
   ```

2. **How it Works**:
   - When `DbContext` starts an operation, it automatically executes a context-switch command (e.g., `SET search_path = tenant1, public`) on the connection.
   - The generated SQL remains clean and developer-friendly (e.g., `SELECT * FROM customers`), allowing the database engine to resolve the table in the correct schema.
   - This ensures optimized query execution plans and consistent SQL logs across tenants.

3. **Design-Time Support**:
   Schema isolation also works within the **Delphi IDE**. By setting the `MetaCurSchema` or `Schema` parameter in a `TFDConnection`, the `TEntityDataSet` and `TEntityDataProvider` components will respect the tenant context during "Preview Data".

## Advantages of Multi-Tenancy in Dext

- **Transparency**: You write `Context.Users.ToList` and the framework adds `WHERE TenantId = 'abc'` automatically.
- **Security**: Prevents data leakage between customers at the architectural level.
- **Migrations**: The `dext migrate:up` CLI can apply migrations across all tenant schemas/databases.

---

[← Scaffolding](scaffolding.md) | [Next: Database as API →](../06-database-as-api/README.md)
