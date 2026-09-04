# Dext + HTMX 4

This document describes the HTMX 4 helpers added on top of Dext's existing native HTMX response support.

## Design principle

Dext already exposes HTMX response headers through:

```pascal
Context.Response.Htmx
  .Trigger('invoice-saved')
  .Retarget('#invoice-grid')
  .Reswap('innerHTML');
```

HTMX 4 support therefore does **not** introduce a second response abstraction, middleware stack, or host-specific adapter.

The new unit:

```text
Sources/Web/Dext.Web.Htmx4.pas
```

adds only the HTMX 4 functionality that was missing from the existing Dext Web API:

- HTMX request detection through `HX-Request`;
- HTMX 4 `HX-Request-Type` (`partial` / `full`);
- HTMX 4 `HX-Source`;
- `HX-Target`, `HX-Current-URL`, boosted and history-restore helpers;
- the HTMX 4 `<hx-partial>` multi-target response format;
- direct conversion of a partial response to Dext `IResult` through `Results.Html`.

This keeps the feature transport-independent and compatible with the current Dext `IHttpRequest`, `IHttpContext`, `IHttpResponse` and `IResult` abstractions.

---

## Request metadata

Add:

```pascal
uses
  Dext.Web,
  Dext.Web.Htmx4;
```

Then inspect the request without coupling application code to Indy, WebBroker or another server adapter:

```pascal
var
  Hx: THtmxRequestInfo;
begin
  Hx := Htmx4.Request(Context);

  if Hx.IsPartial then
  begin
    // Return a fragment or an hx-partial response.
  end;
end;
```

Available request helpers:

```pascal
Hx.IsHtmx;
Hx.RequestType;      // hrtNone / hrtPartial / hrtFull
Hx.IsPartial;
Hx.IsFull;
Hx.IsBoosted;
Hx.IsHistoryRestore;
Hx.Source;           // HX-Source (HTMX 4)
Hx.Target;           // HX-Target
Hx.CurrentUrl;       // HX-Current-URL
```

### HTMX 4 request headers

The helper follows the HTMX 4 request model:

```text
HX-Request: true
HX-Request-Type: partial | full
HX-Source: <source descriptor>
HX-Target: <target descriptor>
HX-Boosted: true
HX-History-Restore-Request: true
HX-Current-URL: <url>
```

`HX-Request-Type` is intentionally not guessed when the header is absent. In that case `RequestType` returns `hrtNone`, while `IsHtmx` can still be true. This makes the helper usable during gradual HTMX 2 -> HTMX 4 migration.

---

## Existing Dext response headers remain valid

Do not replace the existing response API. Continue using it:

```pascal
Context.Response.Htmx
  .Trigger('invoice-saved')
  .PushUrl('/invoices/42');
```

The existing Dext `IHtmxResponse` API already covers the response headers that remain useful in HTMX 4:

```text
HX-Trigger
HX-Retarget
HX-Reswap
HX-Redirect
HX-Refresh
HX-Reselect
HX-Push-Url
HX-Replace-Url
HX-Location
```

The new HTMX 4 unit deliberately does not duplicate these methods.

---

## Multi-target responses with `<hx-partial>`

HTMX 4 can update several areas of the page from one HTTP response.

Dext usage:

```pascal
var
  Parts: THtmxPartialBuilder;
begin
  Parts := Htmx4.Partials;
  try
    Result := Parts
      .Target('#invoice-grid',
        '<tr><td>INV-42</td><td>12,500.00</td></tr>',
        'beforeend')
      .Target('#invoice-count', '<span>347</span>')
      .Target('#toast-area',
        '<div class="notification is-success">Saved</div>',
        'beforeend')
      .AsResult;
  finally
    Parts.Free;
  end;
end;
```

The response body is:

```html
<hx-partial hx-target="#invoice-grid" hx-swap="beforeend">
  <tr><td>INV-42</td><td>12,500.00</td></tr>
</hx-partial>
<hx-partial hx-target="#invoice-count">
  <span>347</span>
</hx-partial>
<hx-partial hx-target="#toast-area" hx-swap="beforeend">
  <div class="notification is-success">Saved</div>
</hx-partial>
```

`AsResult` returns the normal Dext `Results.Html(...)` result. No special response writer is required.

---

## `id` shorthand

For a simple id target:

```pascal
Parts
  .Id('toast', '<b>Saved</b>', 'beforeend');
```

A leading `#` is accepted as well:

```pascal
Parts.Id('#toast', '<b>Saved</b>');
```

Both generate an `id="toast"` partial.

---

## HTML safety model

The builder escapes **generated attribute values** such as `hx-target`, `id` and `hx-swap`.

The fragment body itself is not escaped because it is expected to contain already-rendered HTML from Dext views/templates.

Therefore application values must be escaped by the view/template engine before they are inserted into fragment HTML. Do not concatenate untrusted user input directly into HTML.

---

## ERP pattern

A useful server-driven ERP pattern is:

```text
Browser + HTMX 4
        |
        v
Dext endpoint/controller
        |
        v
Manager / domain service
        |
        v
PostgreSQL
        |
        v
Dext View / fragment rendering
        |
        v
<hx-partial> response
        |
        v
multiple DOM updates
```

For example, one invoice save can update:

- the invoice row/grid;
- totals;
- badge counters;
- the active document status;
- a toast/notification area;

without introducing a client-side SPA state store.

---

## Migration notes from HTMX 2

For request-side code, prefer the HTMX 4 headers exposed by `THtmxRequestInfo`:

```text
HX-Request-Type
HX-Source
```

Do not build new request logic around the old HTMX 2 trigger request headers when HTMX 4 metadata is available.

Existing Dext response-side `HX-Trigger` support remains valid; request-side source metadata and response-side trigger events are different concepts.

---

## Tests

The existing Dext web test suite is extended rather than creating a parallel project:

```text
Tests/Web/Dext.Web.Htmx.Tests.pas
Tests/Web/Dext.Web.UnitTests.dpr
```

Coverage includes:

- partial/full request classification;
- case-insensitive header values;
- `HX-Source`, `HX-Target`, `HX-Current-URL`;
- boosted/history flags;
- multiple `<hx-partial>` output;
- id shorthand;
- attribute escaping;
- all existing `IHtmxResponse` tests.

## Compiler gate

Run the current Dext Web unit-test project with Delphi 13 and perform a clean rebuild. The new source unit is explicitly included by the test DPR so the test does not rely on a previously-built DCU.
