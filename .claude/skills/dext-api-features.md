---
name: dext-api-features
description: Configure cross-cutting API features in Dext — CORS, rate limiting, response caching, health checks, OpenAPI/Swagger, and custom middleware. Use when setting up the HTTP pipeline, protecting endpoints, or documenting APIs.
---

# Dext API Features

## Middleware Pipeline Order

```pascal
App.Builder
  .UseExceptionHandler    // 1. Always first
  .UseHttpLogging         // 2. Logging
  .UseCors(...)           // 3. CORS (before routes)
  .UseAuthentication      // 4. Auth
  .UseRateLimiting(...)   // 5. Rate limiting
  .UseCompression         // 6. Compression
  .MapEndpoints(...)      // 7. Routes
  .UseSwagger(...)        // 8. Swagger (always last)
```

## Custom Middleware

### Inline

```pascal
App.Builder.Use(procedure(Ctx: IHttpContext; Next: TRequestDelegate)
  begin
    // Before endpoint
    WriteLn('Request: ', Ctx.Request.Path);
    Next(Ctx);
    // After endpoint
    WriteLn('Response: ', Ctx.Response.StatusCode.ToString);
  end);
```

### Class-Based

```pascal
type
  TMyMiddleware = class(TInterfacedObject, IMiddleware)
  private
    FLogger: ILogger;
  public
    constructor Create(Logger: ILogger);
    procedure Invoke(Ctx: IHttpContext; Next: TRequestDelegate);
  end;

// Register
App.Builder.UseMiddleware<TMyMiddleware>;
```

### Short-Circuit (Stop Pipeline)

```pascal
App.Builder.Use(procedure(Ctx: IHttpContext; Next: TRequestDelegate)
  begin
    if Ctx.Request.Header('X-API-Key') = '' then
    begin
      Ctx.Response.StatusCode := 401;
      Ctx.Response.Json('{"error":"API key required"}');
      Exit;  // Do NOT call Next
    end;
    Next(Ctx);
  end);
```

### Conditional Middleware

```pascal
App.Builder.UseWhen(
  function(Ctx: IHttpContext): Boolean
  begin
    Result := Ctx.Request.Path.StartsWith('/api');
  end,
  procedure(App: IApplicationBuilder)
  begin
    App.UseRateLimiting(ApiOptions);
  end);
```

## CORS

```pascal
// Development (open)
App.Builder.UseCors(
  CorsOptions.AllowAnyOrigin.AllowAnyMethod.AllowAnyHeader);

// Production (restrictive)
App.Builder.UseCors(
  TCorsOptions.Create
    .AllowOrigins(['https://myapp.com'])
    .AllowMethods(['GET', 'POST', 'PUT', 'DELETE'])
    .AllowHeaders(['Content-Type', 'Authorization'])
    .AllowCredentials
    .MaxAge(3600));
```

> `AllowAnyOrigin` + `AllowCredentials` is invalid — use specific origins when credentials are needed.
> CORS must be registered **before** route mapping.

Per-endpoint override:
```pascal
Builder.MapGet<IResult>('/public', ...).Cors(
  TCorsOptions.Create.AllowAnyOrigin.AllowMethods(['GET']));
Builder.MapGet<IResult>('/internal', ...).DisableCors;
```

## Rate Limiting

```pascal
// Fixed window
App.Builder.UseRateLimiting(
  TRateLimitOptions.Create.Limit(100).PerMinute);

// Token bucket
App.Builder.UseRateLimiting(
  TRateLimitOptions.Create.TokenBucket.BucketSize(100).RefillRate(10));

// By key
TRateLimitOptions.Create.ByIP.Limit(100).PerMinute
TRateLimitOptions.Create.ByUser.Limit(1000).PerHour
TRateLimitOptions.Create.ByHeader('X-API-Key').Limit(5000).PerDay
TRateLimitOptions.Create.ByKey(function(Ctx): string
  begin Result := Ctx.Request.QueryParam('tenant'); end)
  .Limit(100).PerMinute
```

Per-endpoint override:
```pascal
Builder.MapPost<IResult>('/expensive', ...).RateLimit(
  TRateLimitOptions.Create.Limit(10).PerMinute);
```

Exceeded requests return `429 Too Many Requests` with headers:
`X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

## Response Caching

### Minimal API

```pascal
Builder.MapGet<IResult>('/api/news', ...).Cache(60); // 60 seconds
```

### Controller

```pascal
[HttpGet]
[ResponseCache(Duration := 60)]
function GetAll: IResult;
```

### Cache Profiles

```pascal
// ConfigureServices
Services.AddResponseCaching(procedure(Options: TResponseCachingOptions)
  begin
    Options.AddProfile('Default', procedure(P: TCacheProfile)
      begin
        P.Duration := 300;
        P.Location := clAny;
      end);
  end);

// Usage
[ResponseCache(Profile := 'Default')]
```

Adds `Cache-Control: public, max-age=N` and `Expires` headers.

## Health Checks

```pascal
// Simple liveness
Builder.MapGet<IResult>('/health/live',
  function: IResult
  begin
    Result := Results.Ok('OK');
  end);

// Detailed readiness
Builder.MapGet<IResult>('/health/ready',
  function(Db: TAppDbContext): IResult
  begin
    var Status := 200;
    var DbOk := True;
    try
      Db.Connection.Execute('SELECT 1');
    except
      DbOk := False;
      Status := 503;
    end;
    Result := Results.StatusCode(Status,
      Format('{"status":"%s","db":%s}',
        [IfThen(DbOk,'healthy','unhealthy'), BoolToStr(DbOk,'true','false')]));
  end);
```

Standard: `200 OK` = healthy, `503 Service Unavailable` = unhealthy.

## OpenAPI / Swagger

### Setup

```pascal
App.Builder
  .MapControllers
  .UseSwagger(Swagger.Title('My API').Version('v1').AddBearerAuth);
```

`AddBearerAuth` adds the JWT "Authorize" button to the Swagger UI.

### Minimal API Metadata

```pascal
Builder.MapGet<IResult>('/api/users', ...)
  .WithTags('Users')
  .WithSummary('List all users')
  .WithDescription('Returns all registered users.')
  .RequireAuthorization;
```

### Controller Swagger Attributes

```pascal
type
  [ApiController('/api/users')]
  [SwaggerTag('Users', 'User management')]
  TUsersController = class
  public
    [HttpGet]
    [SwaggerSummary('List all users')]
    [SwaggerResponse(200, 'Success', TArray<TUser>)]
    function GetAll: IResult;

    [HttpGet('/{id}')]
    [SwaggerSummary('Get user by ID')]
    [SwaggerParam('id', 'User ID', True)]
    [SwaggerResponse(200, 'Found', TUser)]
    [SwaggerResponse(404, 'Not found')]
    function GetById(Id: Integer): IResult;

    [HttpPost]
    [SwaggerBody(TCreateUserRequest)]
    [SwaggerResponse(201, 'Created', TUser)]
    function CreateUser([Body] Req: TCreateUserRequest): IResult;
  end;
```

### Swagger Attribute Reference

| Attribute | Description |
|-----------|-------------|
| `[SwaggerSummary('')]` | Short description |
| `[SwaggerDescription('')]` | Long description |
| `[SwaggerTag('Name')]` | Group in Swagger UI |
| `[SwaggerParam('name','desc', required)]` | Document parameter |
| `[SwaggerBody(TType)]` | Request body type |
| `[SwaggerResponse(code,'desc')]` | Response |
| `[SwaggerResponse(code,'desc',TType)]` | Response with type |

## Static Files

```pascal
App.Builder.UseStaticFiles('/public', './wwwroot');
```

## Compression

```pascal
App.Builder.UseCompression; // GZip by default
```

## Examples

| Example | What it shows |
|---------|---------------|
| `Web.CachingDemo` | Response caching middleware, configurable duration, vary-by-query |
| `Web.RateLimitDemo` | Fixed window rate limiting, rejection handling, rate-limit headers |
| `Web.SwaggerExample` | Swagger with Minimal API — fluent DSL, schema generation |
| `Web.SwaggerControllerExample` | Swagger with Controllers — attributes, security integration |
| `Web.SslDemo` | SSL/HTTPS with OpenSSL and Taurus TLS certificate configuration |
