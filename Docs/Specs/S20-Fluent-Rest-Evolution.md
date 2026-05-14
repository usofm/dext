# S20 - Fluent REST Evolution & Typed Payloads

## Status
- **Date**: 2026-05-14
- **Author**: Antigravity & Cesar Romero
- **Status**: Implemented
- **Issue Reference**: Issue #119

## 1. Context & Rationale
The current `Dext.Net` implementation requires manual instantiation of `TRestRequest` for complex requests, which breaks the fluent flow initiated by `TRestClient`. Additionally, the generic payload support in `TRestRequest` is currently constrained to `class` types, while many modern DTOs in Dext are implemented as **records** or **arrays of records**.

This specification outlines the evolution of the REST stack to support a seamless fluent experience and native record/array serialization.

## 2. Goals
- **Eliminate Constructor Friction**: Allow creating builders directly from the client.
- **Support Modern DTOs**: Native support for `record` and `TArray<T>` in bodies and responses.
- **Maintain Clean API**: Adhere to the framework's minimalist and expressive design.
- **Zero Breaking Changes**: Preserve existing `Get`/`Post` method signatures.

## 3. Technical Design

### 3.1. TRestClient Request Factories
To maintain a clean API and avoid return-type collisions with existing `Get`/`Post` methods, we will use a **Grouping Pattern** for builders.

#### A. The `Request` Fluent Entry Point
Instead of adding many methods to the root of `TRestClient`, we expose a `Request` property (or method) that acts as a factory for `TRestRequest`.

**Usage:**
```pascal
Client.Request.Get('/users').Header(...).Execute;
Client.Request.Post('/users').Body(Dto).Execute;
```

**Design Rationale:**
The transition from root-level suffixes (e.g., `GetRequest`) to the grouping pattern (`Request.Get`) is based on:
1. **Action vs. Planning Separation**: Root methods like `Get`/`Post` are execution-oriented (returning an async task). Grouping builders under `Request` creates a semantic barrier, signaling that the developer is now in "Planning/Builder Mode".
2. **Namespace Hygiene**: Prevents "Method Hell" on the `TRestClient` root, keeping autocomplete focused on direct actions while hiding complexity behind the `Request` portal.
3. **Overload Workaround**: Elegantly bypasses Delphi's inability to overload by return type, without resorting to verbose or non-standard method names.

**Implementation Detail:**
`TRestClient` will expose an overloaded `Request` method:
1. `function Request: TRestRequestFactory; overload;` (Returns a record helper).
2. `function Request(AMethod: TDextHttpMethod; const AEndpoint: string): TRestRequest; overload;` (Direct factory).

#### B. TRestRequestFactory Structure
A lightweight record that carries the originating `TRestClient` and provides verb-specific builders.

> **Important**: `TRestRequestFactory` **must** hold a reference to the `TRestClient` that created it, as `TRestRequest.Create(AClient, AMethod, AEndpoint)` requires it.

```pascal
TRestRequestFactory = record
private
  FClient: TRestClient;  // captures the originating client
public
  function Get(const AEndpoint: string = ''): TRestRequest;
  function Post(const AEndpoint: string = ''): TRestRequest;
  function Put(const AEndpoint: string = ''): TRestRequest;
  function Delete(const AEndpoint: string = ''): TRestRequest;
  function Patch(const AEndpoint: string = ''): TRestRequest;
end;
```

`TRestClient.Request` instantiates the factory passing `Self`:
```pascal
function TRestClient.Request: TRestRequestFactory;
begin
  Result.FClient := Self;
end;
```

### 3.2. TRestRequest Body Evolution
The `Body<T>` method in `TRestRequest` will be updated to support any serializable type.

#### Strategy: Unconstrained Generic (Unified Support)
To avoid Delphi compiler error `E2252` (Ambiguity between class and record constraints for overloaded generic methods), we have adopted a unified unconstrained generic for individual payloads, supplemented by a specialized array helper:

```pascal
// Unified: handles both classes and records (DTOs)
function Body<T>(const ABody: T): TRestRequest; overload;

// Semantic Helper: explicitly handles TArray of records to avoid collection ambiguity
function BodyArray<R: record>(const ABody: TArray<R>): TRestRequest;
```

All overloads delegate to `JsonBody(TDextJson.Serialize<T>(ABody))`. The removal of the `: class` constraint across the REST stack (Client and Request) allows for a much more flexible DTO architecture.

### 3.3. Typed Responses for Records and Arrays
The `Execute<T>` method and `IRestResponse<T>` interface will be updated to allow `record` and `TArray<T>` as target types.

```pascal
var Users := Client.Request.Get('/users')
  .Execute<TArray<TUserRecord>>
  .Await;
```

## 4. Design Principles & Constraints

### Clean API (No "With" Prefixes)
Following the decision to maintain a high signal-to-noise ratio:
- **REJECTED**: `WithHeader`, `WithQuery`, `WithBody`.
- **ACCEPTED**: `Header`, `QueryParam`, `Body`.

### Implementation Strategy
The new methods will be implemented as additive changes in `Dext.Net.RestClient.pas` and `Dext.Net.RestRequest.pas`. If necessary, `TRestClient` (the record facade) will use a record helper or direct method additions to maintain binary compatibility if interfaces are strictly controlled.

## 5. Files Impacted
- `Sources\Net\Dext.Net.RestClient.pas`
- `Sources\Net\Dext.Net.RestRequest.pas`
- `Sources\Net\Dext.Net.Authentication.pas` (if new auth-specific fluent methods are added)

## 6. Acceptance Criteria
- [ ] `Client.Request.Post('/path')` returns a valid `TRestRequest` builder.
- [ ] `Request.Body<TRecord>(MyRecord)` serializes correctly without compiler errors.
- [ ] `Request.Body<TArray<TRecord>>(MyArray)` serializes correctly.
- [ ] Existing `Client.Get('/path').Await` calls continue to work without modification.
- [ ] `Execute<TArray<T>>` correctly deserializes JSON arrays into Delphi arrays.
