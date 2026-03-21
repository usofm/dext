---
description: >-
  Expert skill for the SSR layer, View Engines (Web Stencils), HTMX integration,
  session management, and advanced template features of the Dext Framework.
---

<skill>

# Dext Framework — View Engine & SSR (Web Stencils)

You are an expert in building server-side rendered (SSR) applications and HTMX integrations using the Dext Framework. You have deep knowledge of the Dext abstracted `IViewEngine` architecture, its primary implementation via Web Stencils (Delphi 12.2+), the complete Web Stencils template syntax, layout system, session/auth components, and advanced features like scaffolding and expression evaluation.

---

## 1. Core Architecture (from source: `Dext.Web.View.pas`, `Dext.Web.View.WebStencils.pas`)

### 1.1 Agnostic View Engine — `IViewEngine`

Dext defines a single interface that any template engine must implement:

```pascal
IViewEngine = interface
  function Render(AContext: IHttpContext; const AViewName: string; AViewData: IViewData): string;
end;
```

The Web Stencils implementation is `TWebStencilsViewEngine` (in `Dext.Web.View.WebStencils`). It creates a `TWebStencilsEngine` + `TWebStencilsProcessor` per render call, wires up `OnValue` and `HandleLookup` handlers, and returns the processed HTML.

### 1.2 View Data Pipeline — `IViewData`

Data flows from route handlers to the view engine via `IViewData`:

```pascal
IViewData = interface
  procedure SetValue(const AName: string; const AValue: TValue);   // Scalars
  function GetValue(const AName: string): TValue;
  procedure SetData(const AName: string; AData: TObject; AOwns: Boolean = False);  // Objects
  function GetData(const AName: string): TObject;
  property Values: IDictionary<string, TValue>;
  property Objects: IDictionary<string, TObject>;
end;
```

Both dictionaries are **case-insensitive** (created via `TCollections.CreateDictionaryIgnoreCase`).

### 1.3 View Result — `IViewResult`

Route handlers return `IViewResult`, which is a fluent builder:

```pascal
IViewResult = interface(IResult)
  function WithValue(const AName: string; const AValue: TValue): IViewResult;
  function WithData(const AName: string; AData: TObject; AOwns: Boolean = False): IViewResult;
  function WithQuery(const AName: string; AQuery: TObject): IViewResult;
  function WithLayout(const ALayout: string): IViewResult;
  function Render(AContext: IHttpContext): string;
end;
```

There is also **`TDextViewResult`** — a record wrapper that adds a generic method:

```pascal
function WithQuery<T: class>(const AName: string; const AQuery: TFluentQuery<T>): TDextViewResult;
```

This is the bridge to the streaming engine — it calls `AQuery.GetStreamingEnumerator` and wraps it in `TStreamingListWrapper<T>`.

### 1.4 HTMX Auto-Detection

In `TViewResult.Render`, Dext checks for the `HX-Request` header:

```pascal
if not FViewData.Values.ContainsKey('Layout') then
begin
  if AContext.Request.GetHeader('HX-Request') <> '' then
    FViewData.SetValue('Layout', '');
end;
```

This means: **if no layout was explicitly set** (via `.WithLayout(...)`) **and** the request is an HTMX request, the layout is automatically suppressed. You do NOT need to call `.WithLayout('')` for HTMX partials — it happens automatically.

### 1.5 Flyweight Streaming — `TStreamingListWrapper<T>`

When an ORM query is passed via `WithQuery<T>`, Dext wraps it in `TStreamingListWrapper<T>`:

- **`GetEnumerator`**: Returns a `TStreamingEnumeratorProxy<T>` that iterates row-by-row
- **`IsEmpty`**: Lazy-evaluated — calls `MoveNext` once on first access to check emptiness
- **O(1) memory**: The same object is reused during the loop; no `TObjectList` is allocated

This means `Model.IsEmpty` and `@foreach (var item in Model)` work correctly with streaming data.

### 1.6 SmartProp Auto-Unwrap — `HandleLookup` + `OnValue`

On Delphi 13+ (CompilerVersion >= 37.0), the `TWebStencilsRenderContext` installs a **HandleLookup** callback on every `AddVar` call:

```pascal
AProcessor.AddVar(ObjPair.Key, ObjPair.Value, False, HandleLookup);
```

This callback calls `TReflection.TryUnwrapProp(Value, Unwrapped)` to automatically extract the inner value from SmartProp types (`IntType`, `StringType`, etc.). The `OnValue` fallback does the same unwrapping.

Additionally, the `Prop()` template function is registered via `TBindingMethodsFactory.RegisterMethod` for explicit use in `@()` expressions.

**Practical effect**: On Delphi 13+, simple property access like `@item.Name` may work for some contexts because HandleLookup auto-unwraps. However, inside `@()` expression blocks you still need `@(Prop(item.Name))`. **Always use `@(Prop(...))` for consistency and safety.**

### 1.7 Web Stencils RAD Studio Components

Web Stencils (from `Web.Stencils` unit) has two main components:

- **TWebStencilsEngine** — The orchestrator. Manages configuration, path templates, root directory, shared variables (`AddVar`), module scanning (`AddModule`).
- **TWebStencilsProcessor** — The worker. Processes individual HTML files. Key: `InputFileName`, `Content` (output), `AddVar`, `OnValue`, `OnScaffolding` events.

In Dext, these are created and managed internally by `TWebStencilsViewEngine` — you do NOT place them on a WebModule manually (that's the WebBroker approach). Dext's `AddWebStencils` service registration handles everything.

---

## 2. Dext App Configuration

### 2.1 Startup — ConfigureServices

The View Engine is registered in the DI container during `ConfigureServices`.

**Simplest form** (uses all defaults):

```pascal
procedure TStartup.ConfigureServices(const Services: TDextServices; const Configuration: IConfiguration);
begin
  Services
    .AddDbContext<TAppDbContext>(
      procedure(Opts: TDbContextOptions)
      begin
        Opts.UseSqlite('myapp.db');
      end)
    .AddWebStencils;  // Uses TViewOptions defaults
end;
```

**`TViewOptions` defaults** (from source):
- `TemplateRoot` = `TPath.GetFullPath('wwwroot/views')`
- `DefaultLayout` = `'_Layout.html'`
- `AutoReload` = `True`
- `WhitelistEntities` = `True` (auto-whitelists ALL entity classes from ModelBuilder)

**Advanced configuration** (custom template root, layout, explicit whitelist):

```pascal
Services
  .AddWebStencils(
    procedure(Opts: TViewOptions)
    begin
      Opts.TemplateRoot  := TPath.GetFullPath('wwwroot/views');
      Opts.DefaultLayout := '_Layout.html';
      Opts.WhitelistEntities := True;  // default; auto-whitelists all entities
    end);
```

**`TViewOptionsBuilder`** — a fluent record alternative for service registration:

```pascal
Services.AddWebStencils(
  TViewOptionsBuilder.Create
    .TemplateRoot('wwwroot/templates')
    .DefaultLayout('_Master.html')
    .AutoReload(True)
    .WhiteListEntities            // auto-whitelist all ORM entities
    .WhiteList(TCustomer)         // explicit additional class
    .WhiteList([TProduct, TOrder]) // batch whitelist
);
```

**Important**: `WhitelistEntities = True` (the default) scans ALL entity maps from `TModelBuilder.Instance` and from each registered `TDbContext`'s model cache. You usually do NOT need manual whitelist calls unless you're exposing non-entity objects to templates.

### 2.2 Startup — Configure (Middleware Pipeline)

```pascal
procedure TStartup.Configure(const App: IWebApplication);
begin
  JsonDefaultSettings(JsonSettings.CamelCase.CaseInsensitive.ISODateFormat);

  App.Builder
    .UseDeveloperExceptionPage   // Dev-mode error pages
    .UseHttpLogging              // Request/response logging
    .UseViewEngine               // Activates the pre-configured ViewEngine
    .UseStaticFiles('wwwroot')   // Serve CSS, JS, images from wwwroot/
    // ... route mappings follow
end;
```

### 2.3 Uses Clause Order (CRITICAL)

Due to Delphi's single class-helper limitation, the `uses` order **MUST** be:

```
Dext → Dext.Entity → Dext.Web
```

The last unit always wins and ensures Web methods (`MapGet`, `AddWebStencils`, `Results.View`) are visible.

Required units for a typical Startup unit:

```pascal
uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Dext,
  Dext.DI.Interfaces,
  Dext.Configuration.Interfaces,
  Dext.Entity,            // Entity Facade
  Dext.Entity.Core,       // IDbSet<T>
  Dext.Entity.Query,
  Dext.Core.SmartTypes,
  Dext.Collections,       // IList<T>
  MyEntityUnit,           // Your entity classes
  Dext.Web.Interfaces,    // IResult, IWebApplication
  Dext.Web.Results,
  Dext.Web.View,
  {$IFDEF DEXT_ENABLE_WEB_STENCILS}
  Web.Stencils,
  {$ENDIF}
  Dext.Web.View.WebStencils,
  Dext.Web;               // Web HELPERS — ALWAYS LAST
```

---

## 3. Route Handlers — Results.View (from source: `TViewResult`, `TDextViewResult`)

All view-returning endpoints return `IResult` (which `IViewResult` extends).

### 3.1 Simple View (No Data)

```pascal
.MapGet<IResult>('/',
  function: IResult
  begin
    Result := Results.View('index');
  end)
```

### 3.2 View with Scalar Variables — `WithValue`

Passes `TValue` scalars accessible as `@VariableName` in templates:

```pascal
Result := Results.View('dashboard')
  .WithValue('PageTitle', 'Dashboard')
  .WithValue('Version', '2.0.1');
```

### 3.3 View with Object Data — `WithData`

Passes a Delphi object whose published/public properties are accessible:

```pascal
Result := Results.View('profile')
  .WithData('user', CurrentUser, False);  // False = caller manages lifetime
```

With ownership:
```pascal
Result := Results.View('report')
  .WithData('summary', TSummary.Create, True);  // True = ViewData frees it
```

### 3.4 View with ORM Streaming Query — `WithQuery<T>`

This is the key generic method on `TDextViewResult`. It calls `AQuery.GetStreamingEnumerator` and wraps it in `TStreamingListWrapper<T>`, enabling O(1) memory rendering:

```pascal
.MapGet<TAppDbContext, IResult>('/customers',
  function(Db: TAppDbContext): IResult
  begin
    Result := Results.View<TCustomer>('customers', Db.Customers.QueryAll);
  end)
```

> `Results.View<TCustomer>('customers', query)` is syntactic sugar that calls `.WithQuery<TCustomer>('Model', query)` internally. The object is accessible as `Model` in templates.

### 3.5 View with Filtered Query

```pascal
.MapGet<TAppDbContext, TSearchDTO, IResult>('/customers/search',
  function(Db: TAppDbContext; Query: TSearchDTO): IResult
  begin
    var c := Prototype.Entity<TCustomer>;
    Result := Results.View<TCustomer>('customers_list',
      Db.Customers.Where(
        (c.Name.Contains(Query.SearchTerm)) or
        (c.Email.Contains(Query.SearchTerm))
      )
    );
  end)
```

### 3.6 Override Layout — `WithLayout`

Sets the `'Layout'` key in ViewData.Values. Pass an empty string to suppress the master page wrapper:

```pascal
Result := Results.View<TCustomer>('user_list', UserQuery)
  .WithLayout('');
```

**Note**: For HTMX requests, layout suppression is **automatic** (see Section 1.4). You only need `.WithLayout('')` to force it for non-HTMX requests.

### 3.7 Multiple Named Queries

You can pass multiple streaming queries with different names:

```pascal
Result := Results.View('dashboard')
  .WithQuery<TCustomer>('Customers', Db.Customers.QueryAll)
  .WithQuery<TOrder>('RecentOrders', Db.Orders.Where(o.Date > Yesterday));
```

Template:
```html
@foreach (var c in Customers) { <p>@(Prop(c.Name))</p> }
@foreach (var o in RecentOrders) { <p>@(Prop(o.Total))</p> }
```

---

## 4. Entity Models

Entities use Smart Properties (`IntType`, `StringType`, `DoubleType`, `BoolType`) from `Dext.Core.SmartTypes`. **Never** use raw `Integer`, `string`, etc. in entity properties.

```pascal
unit Customer;

interface

uses
  Dext.Entity,
  Dext.Core.SmartTypes;

type
  [Table('Customers')]
  TCustomer = class
  private
    FId: IntType;
    FName: StringType;
    FEmail: StringType;
  public
    [PK, AutoInc]
    property Id: IntType read FId write FId;
    property Name: StringType read FName write FName;
    property Email: StringType read FEmail write FEmail;
  end;

implementation
end.
```

---

## 5. Project Entry Point (.dpr)

```pascal
program MyWebApp;
{$APPTYPE CONSOLE}

uses
  Dext.MM,
  System.SysUtils,
  Dext,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Utils,
  Startup in 'Startup.pas',
  Customer in 'Models\Customer.pas';

begin
  SetConsoleCharset;   // REQUIRED for all console projects
  try
    var App: IWebApplication := WebApplication;
    App.UseStartup(TStartup.Create);

    var Provider := App.BuildServices;
    TStartup.SeedData(Provider);

    App.Run(5000);
  except
    on E: Exception do
    begin
      Writeln('Error: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  ConsolePause;
end.
```

---

## 6. Web Stencils Template Syntax — Complete Reference

### 6.1 The `@` Symbol

The `@` symbol is the template marker. It can be followed by:
- An object/dataset name: `@user.name`
- A keyword: `@if`, `@foreach`, `@switch`, `@page`, `@query`
- Another `@` to escape: `support@@example.com`

### 6.2 Curly Braces `{ }`

Delimit conditional or repeated blocks. Only processed after a Web Stencils keyword.

### 6.3 Dot Notation

```html
<p>Name: @user.name</p>
<p>Email: @user.email</p>

<!-- Chained (RAD Studio 12.3+) -->
<p>City: @order.customer.address.city</p>
```

### 6.4 Comments

```html
@* This is a server-side comment — never sent to the browser *@
```

Unlike `<!-- HTML comments -->`, Web Stencils comments are stripped on the server.

### 6.5 @page — Request Properties

Access current request metadata:

| Property | Description |
|---|---|
| `@page.pagename` | Current page name (filename without ext) |
| `@page.filename` | Full filename of template |
| `@page.request_path` | Full request path from URL |
| `@page.request_segment` | Last segment of request path |
| `@page.referer` | Referring page URL |
| `@page.browser` | User agent string |
| `@page.address` | Client IP address |

```html
<p>Current page: @page.pagename</p>
<p>Path: @page.request_path</p>
```

### 6.6 @query — URL Query Parameters

Read HTTP query parameters directly:

```html
<!-- URL: /search?searchTerm=delphi -->
<p>You searched for: @query.searchTerm</p>
```

Returns empty string if parameter does not exist.

### 6.7 @if / @else / @if not

```html
@if (user.isLoggedIn) {
  <p>Welcome, @user.name!</p>
}
@else {
  <p>Please log in.</p>
}

@if not(cart.isEmpty) {
  <p>You have @cart.itemCount items.</p>
}
@else {
  <p>Your cart is empty.</p>
}
```

Conditions are evaluated on the server; only the matching block is included in output.

### 6.8 @switch / @case / @default (RAD Studio 13+)

```html
@switch(user.role) {
  @case "admin" {
    <div class="admin-panel">
      <h2>Admin Dashboard</h2>
    </div>
  }
  @case "moderator" {
    <div class="mod-tools">
      <h2>Moderator Tools</h2>
    </div>
  }
  @default {
    <div class="guest-content">
      <h2>Welcome, Guest!</h2>
    </div>
  }
}
```

Especially useful for generating forms based on database field types:

```html
@switch(field.dataType) {
  @case "ftString"  { <input type="text" name="@field.FieldName"> }
  @case "ftInteger" { <input type="number" name="@field.FieldName"> }
  @case "ftDate"    { <input type="date" name="@field.FieldName"> }
  @case "ftBoolean" { <input type="checkbox" name="@field.FieldName"> }
  @default          { <input type="text" name="@field.FieldName"> }
}
```

### 6.9 @ForEach — Iteration

**Declarative form (preferred):**

```html
<ul>
@ForEach (var product in productList) {
  <li>@product.name - @product.price</li>
}
</ul>
```

**Shorthand form (uses `@loop`):**

```html
<ul>
@ForEach productList {
  <li>@loop.name - @loop.price</li>
}
</ul>
```

Works with any Delphi collection that has `GetEnumerator` returning an object value: `TList<T>`, `TObjectList<T>`, `TArray<T>`, datasets.

**Dext Flyweight with `@(Prop(...))`:**

When iterating over Dext ORM entities with Smart Properties, you **MUST** use the `@(Prop(...))` binding:

```html
@foreach (var item in Model) {
  <tr>
    <td>@(Prop(item.Id))</td>
    <td>@(Prop(item.Name))</td>
    <td>@(Prop(item.Email))</td>
  </tr>
}

@if Model.IsEmpty {
  <tr>
    <td colspan="3">No records found.</td>
  </tr>
}
```

**CORRECT:** `@(Prop(item.Name))`
**INCORRECT:** `@item.Name` — will display `(record)` or the wrong value.

### 6.10 Expression Evaluation — @()

Uses Delphi's LiveBindings expression evaluator for complex expressions:

**Method calls:**

```html
<p>@(FormatDateTime('yyyy-mm-dd', order.Date))</p>
<p>@(UpperCase(customer.FirstName))</p>
<p>@(Round(product.SalePrice))</p>
<p>@(customer.GetFullName)</p>
```

**Arithmetic:**

```html
<p>Price with VAT: $@(product.Price * product.VatPercentage)</p>
<p>Previous page: @(pagination.PageNumber - 1)</p>
```

**Array / list indexing:**

```html
<!-- TStringList -->
<p>@(categories.Strings[0])</p>

<!-- TList<T> -->
<p>@(products.Items[2].Name)</p>
```

> `@()` has slight runtime overhead vs plain `@object.property` — negligible for most apps.

---

## 7. Layout System

### 7.1 @RenderBody

Used in the **layout template** to mark where child page content is injected:

```html
<!-- _Layout.html -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>My App</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/htmx.org@1.9.10"></script>
    @RenderHeader
</head>
<body>
    <nav><!-- shared navigation --></nav>

    <main>
        @RenderBody
    </main>

    <footer><!-- shared footer --></footer>
</body>
</html>
```

### 7.2 @LayoutPage

Used in **content pages** to specify which layout to use. Place at the top of the file:

```html
@LayoutPage _Layout.html

<h2>Welcome</h2>
<p>This content replaces @RenderBody in the layout.</p>
```

The layout file name can omit the extension if `DefaultFileExt` is configured. Nested layouts are supported (RAD Studio 13+).

### 7.3 @Import

Merges another template into the current template — for reusable partial components:

```html
@Import Sidebar.html

@* Extension can be omitted *@
@Import Sidebar

@* Nested folders *@
@Import components/Sidebar

@* Inline within a parent template *@
<tbody id="results-tbody">
    @Import customers_list
</tbody>
```

This is essential for DRY (Don't Repeat Yourself) templates.

### 7.4 @ExtraHeader / @RenderHeader

Allows child pages to inject page-specific CSS/JS into the layout's `<head>`:

**Layout:**
```html
<head>
    <link rel="stylesheet" href="/css/main.css">
    @RenderHeader
</head>
```

**Content page:**
```html
@LayoutPage _Layout
@ExtraHeader {
    <link rel="stylesheet" href="/css/product-page.css">
    <script src="/js/product-details.js"></script>
}

<h1>Product Details</h1>
```

Nested `@ExtraHeader` blocks are supported (RAD Studio 13+) for complex layout hierarchies.

---

## 8. HTMX Integration Patterns

### 8.1 Search with Debounce

```html
<input type="text" name="SearchTerm" placeholder="Search..."
    hx-get="/customers/search"
    hx-trigger="keyup changed delay:300ms"
    hx-target="#results-tbody"
    hx-indicator="#search-indicator">

<tbody id="results-tbody">
    @Import customers_list
</tbody>

<div id="search-indicator" class="htmx-indicator">
    <span>Searching...</span>
</div>
```

### 8.2 HTMX Partial Route (No Layout)

The server route returns a partial (layout-less) fragment:

```pascal
.MapGet<TAppDbContext, TSearchDTO, IResult>('/customers/search',
  function(Db: TAppDbContext; Query: TSearchDTO): IResult
  begin
    var c := Prototype.Entity<TCustomer>;
    Result := Results.View<TCustomer>('customers_list',
      Db.Customers.Where(
        (c.Name.Contains(Query.SearchTerm)) or
        (c.Email.Contains(Query.SearchTerm))
      )
    );
    // Dext auto-detects HX-Request header and strips layout.
    // For manual control: Result := Result.WithLayout('');
  end)
```

### 8.3 Core HTMX Attributes Reference

| Attribute | Purpose |
|---|---|
| `hx-get` | GET request to URL |
| `hx-post` | POST request to URL |
| `hx-put` | PUT request to URL |
| `hx-patch` | PATCH request to URL |
| `hx-delete` | DELETE request to URL |
| `hx-target` | CSS selector for element to update |
| `hx-swap` | How content is swapped: `innerHTML` (default), `outerHTML`, `beforebegin`, `afterbegin`, `beforeend`, `afterend` |
| `hx-trigger` | Event that triggers the request (default: `click` or `submit`) |
| `hx-indicator` | Element to show as loading indicator |
| `hx-push-url` | Push new URL into browser history |
| `hx-boost` | Boost normal anchors/forms with AJAX |
| `hx-params` | Control submitted parameters |
| `hx-headers` | Add custom headers |
| `hx-vals` | Add additional values to request |
| `hx-select` | Select parts of server response |
| `hx-include` | Include additional data in requests |

---

## 9. How Rendering Works Internally (from source: `TWebStencilsViewEngine.Render`)

Understanding the render pipeline helps debug template issues:

1. **Path resolution**: `TPath.Combine(TemplateRoot, AViewName)` + `.html` extension if missing
2. **Processor creation**: A fresh `TWebStencilsProcessor` is created per render call
3. **Engine linking**: `Processor.Engine := FEngine` (inherits root directory)
4. **OnValue handler**: `Processor.OnValue := RenderCtx.OnValue` — fallback for unresolved variables
5. **Variable setup** (`SetupProcessor`): Iterates `IViewData.Objects` and calls:
   - **Delphi 13+**: `AProcessor.AddVar(name, obj, False, HandleLookup)` — with SmartProp auto-unwrap
   - **Delphi 12.x**: `AProcessor.AddVar(name, obj, False)` — plain RTTI only
6. **Input**: `Processor.InputFileName := ViewPath`
7. **Output**: `Result := Processor.Content` — the fully rendered HTML

The **OnValue** handler fires for any `@objectName.propName` that Web Stencils can't resolve via RTTI:
1. Looks up `objectName` in `IViewData.Objects`
2. Falls back to `IViewData.Values` for scalar values
3. Falls back to the `'Model'` object (the default query object)
4. Resolves the property via `TReflection.GetValue` + auto-unwraps SmartProps

---

## 10. Adding Data — WithValue, WithData, WithQuery, AddVar, OnValue

### 10.1 WithValue — Scalar Variables

Passes `TValue` scalars. In templates, access directly as `@VariableName`:

```pascal
Result := Results.View('dashboard')
  .WithValue('PageTitle', 'My Dashboard')
  .WithValue('ItemCount', 42);
```

```html
<h1>@PageTitle</h1>
<p>Items: @ItemCount</p>
```

### 10.2 WithData — Object Variables

Passes a Delphi object whose properties are accessible via `@objectName.propertyName`:

```pascal
Result := Results.View('profile')
  .WithData('user', UserObject, False)   // False = caller manages lifetime
  .WithData('stats', TStats.Create, True); // True = ViewData frees it
```

```html
<p>@user.Name</p>
<p>@stats.TotalRevenue</p>
```

### 10.3 WithQuery / WithQuery\<T\> — Streaming Queries

`WithQuery(name, TObject)` passes any object with ownership. The generic `WithQuery<T>(name, TFluentQuery<T>)` on `TDextViewResult` creates the streaming wrapper:

```pascal
// Generic — creates TStreamingListWrapper<T> with O(1) memory
Result := Results.View('orders')
  .WithQuery<TOrder>('Orders', Db.Orders.QueryAll);
```

In the template, use `@foreach` and `Model.IsEmpty`:

```html
@foreach (var item in Orders) {
  <p>@(Prop(item.Total))</p>
}
@if Orders.IsEmpty {
  <p>No orders found.</p>
}
```

### 10.4 AddVar — WebBroker/Direct Approach

For non-Dext (WebBroker) apps, or when accessing the Engine/Processor directly:

```pascal
WebStencilsProcessor.AddVar('user', UserObject);
```

With ownership:
```pascal
WebStencilsEngine.AddVar('config', ConfigObj, True);
```

### 10.5 AddVar with Lookup Function (Delphi 13+)

Custom property resolution for dictionaries or dynamic sources:

```pascal
var LDict := TDictionary<string, string>.Create;
LDict.Add('APP_VERSION', '1.0.0');
LDict.Add('APP_NAME', 'My Application');

WebStencilsEngine.AddVar('env', LDict, True,
  function(AVar: TWebStencilsDataVar; const APropName: string;
    var AValue: string): Boolean
  begin
    Result := TDictionary<string,string>(AVar.TheObject)
      .TryGetValue(APropName.ToUpper, AValue);
  end);
```

Template: `@env.APP_NAME — @env.APP_VERSION`

### 10.6 AddModule — Attribute-Based Registration

```pascal
type
  TMyDataModule = class(TDataModule)
    [WebStencilsVar]
    FCustomers: TFDMemTable;
    [WebStencilsVar]
    Users: TObjectList<TUser>;
  end;

WebStencilsProcessor.AddModule(MyDataModule);
```

### 10.7 OnValue — Dynamic Value Resolution (WebBroker)

Fires when Web Stencils cannot resolve a property via RTTI. Acts as a fallback:

```pascal
procedure TMyWebModule.ProcessorOnValue(Sender: TObject;
  const ObjectName, FieldName: string; var ReplaceText: string;
  var Handled: Boolean);
begin
  if SameText(ObjectName, 'stats') then
  begin
    Handled := True;
    if SameText(FieldName, 'TotalRevenue') then
      ReplaceText := FormatFloat('$#,##0.00', CalculateTotalRevenue)
    else
      Handled := False;
  end;
end;
```

**Use WithValue/WithData/WithQuery** (Dext API) when possible.
**Use AddVar/OnValue** for WebBroker apps or advanced scenarios like localization, feature flags, computed values.

### 10.8 @Scaffolding — Dynamic HTML Generation

Server-side HTML generation based on class structure:

```html
<form>
  @Scaffolding User
</form>
```

Handle the `OnScaffolding` event:

```pascal
procedure TMyWebModule.ProcessorScaffolding(Sender: TObject;
  const AQualifClassName: string; var AReplaceText: string);
begin
  if SameText(AQualifClassName, 'User') then
    AReplaceText := GenerateFormFieldsForClass('TUser');
end;
```

Best for repetitive/dynamic HTML. For hand-crafted UIs, prefer `@Import` with regular templates.

---

## 10. Session Management & Authentication (RAD Studio 13+)

### 10.1 Three Components

| Component | Purpose |
|---|---|
| `TWebSessionManager` | Session lifecycle: creation, storage, expiration, cleanup |
| `TWebFormsAuthenticator` | HTML form-based auth: login redirect, credential validation, post-login redirect |
| `TWebAuthorizer` | Role-based access control via authorization zones |

### 10.2 Configuration

```pascal
WebFormsAuthenticator.LoginURL   := '/login';
WebFormsAuthenticator.HomeURL    := '/';
WebFormsAuthenticator.FailedURL  := '/login?error=1';
```

### 10.3 Credential Validation (OnAuthenticate)

```pascal
procedure TWebModule1.WebFormsAuthenticatorAuthenticate(
  Sender: TCustomWebAuthenticator;
  Request: TWebRequest;
  const UserName, Password: string;
  var Roles: string; var Success: Boolean);
begin
  Success := False;
  Roles := '';
  if ValidateUserCredentials(UserName, Password) then
  begin
    Success := True;
    Roles := GetUserRoles(UserName);  // e.g. 'user,admin'
  end;
end;
```

### 10.4 @session Object in Templates

| Property | Description |
|---|---|
| `@session.username` | Current user's username |
| `@session.role` | Comma-separated roles |
| `@session.isAuthenticated` | Boolean — is user logged in |
| `@session.id` | Session identifier |

```html
@if (session.isAuthenticated) {
  <p>Welcome, @session.username!</p>
  <a href="/logout">Sign Out</a>
}
@else {
  <a href="/login">Sign In</a>
}
```

### 10.5 Authorization Zones

```pascal
// Protect /admin/* — require "admin" role
WebAuthorizer.AddZone('/admin', 'admin');

// Protect /user/* — require "user" role
WebAuthorizer.AddZone('/user', 'user');

// Multiple roles (comma-separated)
WebAuthorizer.AddZone('/reports', 'admin,analyst');
```

### 10.6 Session Configuration Options

- **Session ID Storage**: Cookies (default), headers, query parameters
- **Session Scope**: Per request, per user, per user+IP
- **Session Timeout**: Configurable expiration
- **Shared Secret**: Cryptographic signing of session IDs

### 10.7 Login Form Template

```html
@LayoutPage _Layout

<div class="login-container">
  <h1>Sign In</h1>

  @if query.error {
    <div class="alert alert-danger">
      Invalid username or password.
    </div>
  }

  <form method="post" action="/login">
    <div class="form-group">
      <label for="username">Username</label>
      <input type="text" id="username" name="username" required autofocus>
    </div>
    <div class="form-group">
      <label for="password">Password</label>
      <input type="password" id="password" name="password" required>
    </div>
    <button type="submit">Sign In</button>
  </form>
</div>
```

The form posts to `/login`, which is automatically handled by `TWebFormsAuthenticator`.

---

## 11. Security — The Whitelist System (from source: `TWebStencilsViewEngine.ApplyWhitelist`)

Web Stencils uses a whitelist to control which Delphi classes can be accessed from templates. The `ApplyWhitelist` method in `TWebStencilsViewEngine` runs during engine creation.

**Automatic behavior** (`WhitelistEntities = True`, the default):

1. Whitelists all classes in `TViewOptions.WhitelistedClasses` array
2. Scans **`TModelBuilder.Instance.GetMaps`** — all globally registered entity maps
3. Scans **every registered `TDbContext`'s `FModelCache`** — entities from each context

This means: if you registered `TCustomer` as a `[Table]` entity in any DbContext, it is **automatically whitelisted**. You do NOT need manual `TWebStencilsProcessor.Whitelist.Configure` calls for ORM entities.

**When you DO need manual whitelisting** (via `TViewOptionsBuilder.WhiteList`):

- Non-entity classes exposed to templates (DTOs, view models, helper objects)
- Classes added via `WithData` that aren't ORM entities

```pascal
Services.AddWebStencils(
  TViewOptionsBuilder.Create
    .WhiteListEntities             // auto-whitelist ORM entities (default)
    .WhiteList(TDashboardSummary)  // explicit: non-entity class
    .WhiteList([TDTO1, TDTO2])     // batch: multiple non-entity classes
);
```

**Delphi version note**: The whitelist feature requires Delphi 13+ (CompilerVersion >= 37.0). On older versions, `ApplyWhitelist` is a no-op.

---

## 12. CSS Framework Integration

Web Stencils is **CSS and JS agnostic**. Use any framework:

```html
<!-- Tailwind CSS -->
<script src="https://cdn.tailwindcss.com"></script>

<!-- Bootstrap -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5/dist/css/bootstrap.min.css">

<!-- HTMX (always include for HTMX features) -->
<script src="https://unpkg.com/htmx.org@1.9.10"></script>
```

For Tailwind in production, use the **Standalone CLI** to generate optimized CSS.

---

## 13. Project Structure

```
MyWebApp/
├── MyWebApp.dpr              # Entry point (SetConsoleCharset, App.Run)
├── Startup.pas               # ConfigureServices + Configure + SeedData
├── Models/
│   ├── Customer.pas          # [Table] entity with SmartTypes
│   └── Product.pas
└── wwwroot/
    ├── views/
    │   ├── _Layout.html      # Master layout (@RenderBody, @RenderHeader)
    │   ├── index.html        # Home page (@LayoutPage _Layout)
    │   ├── customers.html    # Full page with @Import
    │   ├── customers_list.html  # Partial for HTMX swap
    │   ├── login.html
    │   └── components/
    │       ├── sidebar.html
    │       └── pagination.html
    ├── css/
    │   └── app.css
    └── js/
        └── app.js
```

---

## 14. Architectural Guidelines

1. **Avoid `ToList` with large datasets**: Pass the ORM query directly via `WithQuery<T>` / `Results.View<T>` to leverage the `TStreamingListWrapper<T>` flyweight pipeline.
2. **HTMX partials are automatic**: Layout is stripped when `HX-Request` header is present — you do NOT need `.WithLayout('')` for HTMX. Use it only to force layout suppression on non-HTMX routes.
3. **Component Reusability**: Break large layout pages into partial templates via `@Import`.
4. **WhitelistEntities defaults to True**: All ORM entities are auto-whitelisted. Only use `WhiteList(TClass)` for non-entity objects.
5. **Always use `@(Prop(item.Property))`** for Dext Smart Property entities in `@()` expression blocks. Simple access may work on Delphi 13+ via `HandleLookup`, but `@(Prop(...))` is always safe.
6. **Uses clause order**: `Dext` → `Dext.Entity` → `Dext.Web` — always. The last unit wins.
7. **`SetConsoleCharset`** is REQUIRED in all console projects.
8. **Always `.WithPooling(True)`** for Web API DbContexts.
9. **Entity properties**: Use `IntType`, `StringType`, `DoubleType`, `BoolType` — never raw types.
10. **Records cannot be used** from Web Stencils templates (no RTTI for enumerator values).
11. **ViewData dictionaries are case-insensitive**: `@PageTitle` and `@pagetitle` resolve the same value.
12. **One Processor per render**: Dext creates a fresh `TWebStencilsProcessor` per `Render()` call — no state leaks between requests.
13. **WithData ownership**: Pass `True` only if ViewData should free the object. For DI-managed objects, always pass `False`.

---

## 15. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `EFileNotFoundException: View template not found` | Template path wrong | Verify `TemplateRoot` + view name matches; file must have `.html` extension |
| Error during loop mapping | Non-entity class not whitelisted | Add via `TViewOptionsBuilder.WhiteList(TMyClass)`. ORM entities are auto-whitelisted. |
| `(record)` displayed on screen | Missing `Prop()` wrapper in `@()` block | Use `@(Prop(item.PropertyName))` not `@item.PropertyName` in expression blocks |
| Layout still renders in HTMX response | `HX-Request` header not reaching server | Check HTMX sends the header; or call `.WithLayout('')` manually |
| Properties not accessible | Wrong uses clause order | Ensure `Dext.Web` is last in uses |
| Missing `MapGet`/`AddWebStencils` | Class helper not active | Ensure `Dext.Web` is last in uses |
| Blank page | No `IViewEngine` registered | Add `.AddWebStencils` in `ConfigureServices` and `.UseViewEngine` in pipeline |
| `@object.property` shows literal text | Object not passed to view | Use `.WithValue`, `.WithData`, or `.WithQuery<T>` to register the variable |
| `No IViewEngine registered in services` | `UseViewEngine` missing from pipeline | Add `App.Builder.UseViewEngine` before route mappings |
| Session not persisting | Session manager missing | Add `TWebSessionManager` component (WebBroker) or configure session middleware |
| SmartProp shows type name instead of value | Delphi 12.x without `HandleLookup` | Use `@(Prop(item.Prop))` — always required in `@()` blocks, and on Delphi 12.x for any access |
| Object freed prematurely | Wrong ownership flag | Use `WithData(name, obj, False)` for DI-managed objects; `True` only for locally created ones |

---

## 16. Complete Example — Customers CRUD

### 16.1 Entity

```pascal
[Table('Customers')]
TCustomer = class
private
  FId: IntType;
  FName: StringType;
  FEmail: StringType;
public
  [PK, AutoInc]
  property Id: IntType read FId write FId;
  property Name: StringType read FName write FName;
  property Email: StringType read FEmail write FEmail;
end;
```

### 16.2 DbContext

```pascal
TAppDbContext = class(TDbContext)
private
  function GetCustomers: IDbSet<TCustomer>;
public
  constructor Create; overload;
  property Customers: IDbSet<TCustomer> read GetCustomers;
end;

function TAppDbContext.GetCustomers: IDbSet<TCustomer>;
begin
  Result := Entities<TCustomer>;
end;
```

### 16.3 Routes

```pascal
App.Builder
  .UseViewEngine
  .UseStaticFiles('wwwroot')
  .MapGet<IResult>('/',
    function: IResult
    begin
      Result := Results.View('index');
    end)
  .MapGet<TAppDbContext, IResult>('/customers',
    function(Db: TAppDbContext): IResult
    begin
      Result := Results.View<TCustomer>('customers', Db.Customers.QueryAll);
    end)
  .MapGet<TAppDbContext, TSearchDTO, IResult>('/customers/search',
    function(Db: TAppDbContext; Query: TSearchDTO): IResult
    begin
      var c := Prototype.Entity<TCustomer>;
      Result := Results.View<TCustomer>('customers_list',
        Db.Customers.Where(
          (c.Name.Contains(Query.SearchTerm)) or
          (c.Email.Contains(Query.SearchTerm))
        )
      );
    end);
```

### 16.4 Layout Template (_Layout.html)

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My App</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/htmx.org@1.9.10"></script>
    @RenderHeader
</head>
<body class="bg-slate-900 text-slate-100">
    <nav class="bg-slate-800 p-4">
        <a href="/">Home</a>
        <a href="/customers">Customers</a>
    </nav>
    <main class="container mx-auto py-12 px-4">
        @RenderBody
    </main>
    <footer class="text-center py-8 text-slate-500">
        <p>&copy; 2026 My App</p>
    </footer>
</body>
</html>
```

### 16.5 Customers Page (customers.html)

```html
@LayoutPage _Layout.html

<h2>Customers</h2>

<input type="text" name="SearchTerm" placeholder="Search..."
    hx-get="/customers/search"
    hx-trigger="keyup changed delay:300ms"
    hx-target="#results-tbody"
    hx-indicator="#search-indicator">

<table>
    <thead>
        <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Email</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody id="results-tbody">
        @Import customers_list
    </tbody>
</table>

<div id="search-indicator" class="htmx-indicator">
    <span>Searching...</span>
</div>
```

### 16.6 Customers List Partial (customers_list.html)

```html
@foreach (var item in Model) {
<tr>
    <td>@(Prop(item.Id))</td>
    <td>@(Prop(item.Name))</td>
    <td>@(Prop(item.Email))</td>
    <td>
        <button>Edit</button>
    </td>
</tr>
}
@if Model.IsEmpty {
<tr>
    <td colspan="4">No customers found.</td>
</tr>
}
```

---

## 17. Database Seeding

```pascal
class procedure TStartup.SeedData(const Services: IServiceProvider);
var
  DB: TAppDbContext;
begin
  DB := Services.GetService(TAppDbContext) as TAppDbContext;
  if DB = nil then Exit;

  DB.EnsureCreated;

  if DB.Customers.QueryAll.Count = 0 then
  begin
    var C := TCustomer.Create;
    C.Name := 'John Doe';
    C.Email := 'john@example.com';
    DB.Customers.Add(C);

    DB.SaveChanges;
  end;
end;
```

---

## 18. WebBroker Integration (Non-Dext)

For traditional WebBroker applications (without Dext), Web Stencils works via:

1. **TWebStencilsEngine** linked to `TWebFileDispatcher` for automatic template routing
2. **PathTemplates** for URL-to-file mapping:
   - `/ -> /home.html` — Root redirect
   - `/{filename}` — Auto-map URI to template file
   - `/examples/{filename}` — Nested path mapping
3. Manual `AddVar` calls in `TWebActionItem` handlers
4. `TWebSessionManager` + `TWebFormsAuthenticator` + `TWebAuthorizer` components on `TWebModule`

The Dext framework abstracts all of this behind `Services.AddWebStencils` and `Results.View`.

</skill>
