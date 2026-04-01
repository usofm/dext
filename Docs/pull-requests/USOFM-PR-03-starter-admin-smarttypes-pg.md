## Summary

Updates **`Web.Dext.Starter.Admin`** to demonstrate **Smart Types** (`IntType`, `StringType`, `FloatType`) on `TCustomer`, registers **FireDAC PostgreSQL and SQLite** drivers in the **`.dpr`** (required when `UseDriver('PG')`), and keeps sample **Postgres** connection settings (including UTF-8).

## Changes

- **`Web.Dext.Starter.Admin.dpr`**  
  - `uses FireDAC.Phys.PG, FireDAC.Phys.SQLite` so **`Driver [PG] is not registered`** does not occur at runtime.

- **`AppStartup.pas`**  
  - `DB_PROVIDER` toggle / `UseDriver('PG')` / connection string (e.g. `CharacterSet=utf8`) as appropriate for local demo.

- **`Customer.pas`**  
  - Fields/properties use **`IntType` / `StringType` / `FloatType`** + `Dext.Core.SmartTypes`.

- **`Customer.Endpoints.pas`**  
  - HTML row generation uses **`.AsInteger` / `.AsString` / `.AsDouble`** for `Format` / `FormatFloat`.

- **`Web.Dext.Starter.Admin.dproj` / `.res`**  
  - IDE/project updates from building the sample (binary `.res` may differ by environment).

## Notes

- **PostgreSQL**: still requires **`libpq.dll`** (and friends) on **PATH** or next to the executable.
- **SQLite**: linking `FireDAC.Phys.SQLite` keeps **`DB_PROVIDER = SQLITE`** working without extra components.

## Testing

- Build and run **`Web.Dext.Starter.Admin`** with **`SQLITE`** and **`POSTGRES`** (with DB + DLLs present).
