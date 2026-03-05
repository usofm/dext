---
name: dext-auth
description: Secure Dext Web APIs with JWT authentication — setup, login endpoints, protecting routes, and working with claims.
---

# Dext Authentication (JWT)

## Core Import

```pascal
uses
  Dext.Web.Auth;      // TJwtHelper, TClaimsBuilder, TAuthenticationOptions
  Dext.Web.Auth.JWT;  // IJwtTokenHandler (for DI factory registration)
```

## JWT Flow

1. Client sends credentials to `/api/auth/login`
2. Server validates and returns a JWT token
3. Client includes `Authorization: Bearer <token>` header on protected requests
4. Middleware validates the token automatically

## 1. Configure Authentication in Startup

```pascal
procedure TStartup.ConfigureServices(
  const Services: TDextServices;
  const Configuration: IConfiguration);
begin
  Services
    .AddAuthentication(procedure(Options: TAuthenticationOptions)
      begin
        Options.SecretKey := 'your-secret-key-must-be-at-least-32-characters';
        Options.Issuer := 'your-app-name';
        Options.Audience := 'your-api-name';
        Options.ExpirationMinutes := 60;
      end)
    .AddScoped<IAuthService, TAuthService>
    .AddControllers;
end;

procedure TStartup.Configure(const App: IWebApplication);
begin
  App.Builder
    .UseExceptionHandler
    .UseAuthentication  // MUST come before routes
    .MapControllers
    .UseSwagger(Swagger.Title('My API').Version('v1'));
end;
```

> `UseAuthentication` middleware **must be added before** route mapping.

## 2. Alternative: DI Factory for JwtTokenHandler

For finer control, register `IJwtTokenHandler` via factory:

```pascal
const
  JWT_SECRET = 'your-secret-key-must-be-at-least-32-characters';
  JWT_ISSUER = 'my-app';
  JWT_AUDIENCE = 'my-api';
  JWT_EXPIRATION = 60; // minutes

Services.AddSingleton<IJwtTokenHandler, TJwtTokenHandler>(
  function(Provider: IServiceProvider): TObject
  begin
    Result := TJwtTokenHandler.Create(JWT_SECRET, JWT_ISSUER, JWT_AUDIENCE, JWT_EXPIRATION);
  end);
```

## 3. Login Endpoint

### With Minimal API

```pascal
type
  TLoginRequest = record
    Username: string;
    Password: string;
  end;

  TLoginResponse = record
    Token: string;
  end;

Builder.MapPost<TLoginRequest, IAuthService, IResult>('/api/auth/login',
  function(Req: TLoginRequest; Auth: IAuthService): IResult
  begin
    if not Auth.ValidateCredentials(Req.Username, Req.Password) then
      Exit(Results.StatusCode(401));

    var Claims := TClaimsBuilder.Create
      .AddSub(Auth.GetUserId(Req.Username))
      .AddName(Req.Username)
      .AddEmail(Auth.GetEmail(Req.Username))
      .AddRole('user')
      .Build;

    var Token := TJwtHelper.GenerateToken(JWT_SECRET, Claims, JWT_EXPIRATION);

    var Response: TLoginResponse;
    Response.Token := Token;
    Result := Results.Ok(Response);
  end);
```

### With Controller

```pascal
type
  [ApiController('/api/auth')]
  TAuthController = class
  private
    FAuthService: IAuthService;
  public
    constructor Create(AuthService: IAuthService);

    [HttpPost('/login')]
    function Login([Body] Request: TLoginRequest): IResult;
  end;

function TAuthController.Login(Request: TLoginRequest): IResult;
begin
  if not FAuthService.ValidateCredentials(Request.Username, Request.Password) then
    Exit(Results.StatusCode(401));

  var Claims := TClaimsBuilder.Create
    .AddSub(FAuthService.GetUserId(Request.Username))
    .AddName(Request.Username)
    .AddRole('user')
    .Build;

  var Token := TJwtHelper.GenerateToken(JWT_SECRET, Claims, JWT_EXPIRATION);
  Result := Results.Ok(TLoginResponse.Create(Token));
end;
```

## 4. Claims Builder

`TClaimsBuilder` provides a fluent API for building JWT claims:

```pascal
var Claims := TClaimsBuilder.Create
  .AddSub('user-id-123')         // Subject — user's unique ID
  .AddName('Alice Smith')         // Full name
  .AddEmail('alice@example.com')  // Email
  .AddRole('user')                // Single role
  .AddRoles(['admin', 'editor'])  // Multiple roles
  .AddClaim('department', 'IT')   // Custom claim
  .AddClaim('tenant', 'acme')     // Another custom claim
  .Build;                         // Returns TArray<TClaim>
```

## 5. Protect Endpoints

### Minimal API — `.RequireAuthorization`

```pascal
Builder.MapGet<IOrderService, IResult>('/api/orders',
  function(Svc: IOrderService): IResult
  begin
    Result := Results.Ok(Svc.GetAll);
  end)
  .RequireAuthorization;  // Requires any authenticated user

Builder.MapDelete<IOrderService, Integer, IResult>('/api/orders/{id}',
  function(Svc: IOrderService; Id: Integer): IResult
  begin
    Svc.Delete(Id);
    Result := Results.NoContent;
  end)
  .RequireAuthorization('Admin');  // Requires 'Admin' role
```

### Controller — `[Authorize]` / `[AllowAnonymous]`

```pascal
type
  [ApiController('/api/orders')]
  [Authorize]                        // All actions require auth
  TOrdersController = class
  public
    [HttpGet]
    [AllowAnonymous]                 // Public — override class-level [Authorize]
    function GetPublicOrders: IResult;

    [HttpGet('/{id}')]
    function GetById(Id: Integer): IResult;  // Requires auth

    [HttpDelete('/{id}')]
    [Authorize('Admin')]             // Requires 'Admin' role
    function DeleteOrder(Id: Integer): IResult;
  end;
```

## 6. Accessing Claims in Handlers

### Minimal API — via `IHttpContext`

Only use `IHttpContext` when you genuinely need it (e.g., to read claims):

```pascal
Builder.MapGet<IOrderService, IHttpContext, IResult>('/api/orders/my',
  function(Svc: IOrderService; Ctx: IHttpContext): IResult
  begin
    var UserId := Ctx.User.FindFirst('sub');
    Result := Results.Ok(Svc.GetByUserId(UserId));
  end)
  .RequireAuthorization;
```

### Controller — via `HttpContext`

```pascal
function TOrdersController.GetMyOrders: IResult;
begin
  var UserId := HttpContext.User.FindFirst('sub');
  var UserName := HttpContext.User.FindFirst('name');
  Result := Results.Ok(FOrderService.GetByUserId(UserId));
end;
```

### Claims API

```pascal
// Get single claim value
var UserId := Ctx.User.FindFirst('sub');
var Email := Ctx.User.FindFirst('email');
var Name := Ctx.User.FindFirst('name');

// Get all values for a claim type (e.g., multiple roles)
var Roles := Ctx.User.FindAll('role');

// Check role membership
if Ctx.User.IsInRole('admin') then
  // Admin logic...
```

## 7. Token Validation

`UseAuthentication` middleware validates automatically:
- Signature (HMAC-SHA256 by default)
- Expiration (`exp` claim)
- Issuer (`iss`) — if `Options.Issuer` is set
- Audience (`aud`) — if `Options.Audience` is set

## Standard JWT Claim Names

| Method | Claim key |
|--------|-----------|
| `.AddSub('id')` | `sub` |
| `.AddName('name')` | `name` |
| `.AddEmail('email')` | `email` |
| `.AddRole('role')` | `role` |
| `.AddClaim('key', 'val')` | `key` (custom) |

## Common Mistakes

| Wrong | Correct |
|-------|---------|
| `Results.Unauthorized` | `Results.StatusCode(401)` |
| `UseAuthentication` after routes | `UseAuthentication` before routes |
| Secret key shorter than 32 chars | Must be at least 32 characters |
| Manual token parsing in handler | Use `Ctx.User.FindFirst('sub')` |
| Not adding `.RequireAuthorization` | Endpoints are public by default |

## Examples

| Example | What it shows |
|---------|---------------|
| `Web.JwtAuthDemo` | JWT token generation, role-based authorization, claims builder, protected routes |
| `Web.DextStore` | Auth integrated in a full e-commerce API with `[Authorize]` controllers |
| `Web.ControllerExample` | `[Authorize]`, `[AllowAnonymous]`, JWT middleware setup |
