# Dext + HTMX 4

Dext already has native HTMX response support through `IHttpResponse.Htmx`. HTMX 4 support therefore extends the current Web API instead of introducing another middleware or result stack.

## What was added

The new unit is:

```text
Sources/Web/Dext.Web.Htmx4.pas
```

It adds the HTMX 4 pieces that were missing from the existing Dext API:

- request detection through `HX-Request`;
- `HX-Request-Type` (`partial` / `full`);
- `HX-Source`;
- `HX-Target` and `HX-Current-URL` access;
- boosted and history-restore request flags;
- an `<hx-partial>` builder for multi-target responses;
- conversion to the normal Dext `IResult` through `Results.Html`.

The helpers depend on `IHttpRequest`, `IHttpContext`, `IHttpResponse` and `IResult`, so they remain independent of Indy, WebBroker, HttpSys, IOCP or other Dext hosting adapters.

## Request metadata

```pascal
uses
  Dext.Web,
  Dext.Web.Htmx4;

var
  Hx: THtmxRequestInfo;
begin
  Hx := Htmx4.Request(Context);

  if Hx.IsPartial then
  begin
    // Render a fragment.
  end;
end;
```

Available helpers:

```pascal
Hx.IsHtmx;
Hx.RequestType;      // hrtNone / hrtPartial / hrtFull
Hx.IsPartial;
Hx.IsFull;
Hx.IsBoosted;
Hx.IsHistoryRestore;
Hx.Source;           // HX-Source, e.g. button#save
Hx.Target;           // HX-Target, e.g. div#invoice-grid
Hx.CurrentUrl;       // HX-Current-URL
```

`RequestType` is intentionally `hrtNone` when `HX-Request-Type` is absent. `IsHtmx` can still be true, which keeps gradual HTMX 2 to HTMX 4 migration possible.

## Existing Dext response API stays canonical

Continue using the existing API for response headers:

```pascal
Context.Response.Htmx
  .Trigger('invoice-saved')
  .Retarget('#invoice-grid')
  .Reswap('innerHTML')
  .PushUrl('/invoices/42');
```

Dext already supports the response headers that remain useful in HTMX 4, including `HX-Trigger`, `HX-Retarget`, `HX-Reswap`, `HX-Redirect`, `HX-Refresh`, `HX-Reselect`, `HX-Push-Url`, `HX-Replace-Url` and `HX-Location`.

`Dext.Web.Htmx4` does not duplicate those methods.

## Multi-target responses with `<hx-partial>`

A single Dext endpoint can update several DOM regions:

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
        '<div class=''notification is-success''>Saved</div>',
        'beforeend')
      .AsResult;
  finally
    Parts.Free;
  end;
end;
```

Generated response:

```html
<hx-partial hx-target='#invoice-grid' hx-swap='beforeend'>
  <tr><td>INV-42</td><td>12,500.00</td></tr>
</hx-partial>
<hx-partial hx-target='#invoice-count'>
  <span>347</span>
</hx-partial>
<hx-partial hx-target='#toast-area' hx-swap='beforeend'>
  <div class='notification is-success'>Saved</div>
</hx-partial>
```

The actual builder emits standard double-quoted HTML attributes; single quotes are used in this documentation block only to keep the example visually simple.

`AsResult` delegates to `Results.Html`, so the existing Dext result execution pipeline remains authoritative.

## `id` shorthand

HTMX 4 allows `id` on `<hx-partial>` as shorthand for targeting the DOM element with that id.

```pascal
Parts.Id('toast', '<b>Saved</b>', 'beforeend');
Parts.Id('#toast', '<b>Saved</b>'); // leading # is accepted by the Dext helper
```

Equivalent HTMX response concept:

```html
<hx-partial id='toast'>...</hx-partial>
```

## HTML safety

The builder HTML-escapes the attribute values it creates (`hx-target`, `id`, `hx-swap`).

The fragment body is deliberately not escaped because it represents already-rendered HTML. Application values must therefore be encoded by the Dext view/template layer before being inserted into fragment HTML. Do not concatenate untrusted user data directly into HTML.

## Caching

HTMX 4 distinguishes full and partial requests with `HX-Request-Type`. When the same cacheable URL can return either representation, return:

```http
Vary: HX-Request-Type
```

This prevents a cached fragment from being served as a full document, or the reverse.

## ERP usage pattern

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

One invoice save can therefore update the grid row, totals, counters, document status and toast area without introducing a client-side SPA state store.

## Migration from HTMX 2

For new request-side logic prefer:

```text
HX-Request-Type
HX-Source
```

`HX-Source` replaces the old request-side trigger metadata. This is separate from the response-side `HX-Trigger` header, which remains supported by HTMX 4 and by Dext's existing `Response.Htmx` API.

## Tests

The existing Web test suite is extended instead of creating a second test project:

```text
Tests/Web/Dext.Web.Htmx.Tests.pas
Tests/Web/Dext.Web.UnitTests.dpr
```

Coverage includes request-type detection, case-insensitive header values, source/target/current-URL metadata, boosted/history flags, multiple partials, id shorthand, attribute escaping, and the existing `IHtmxResponse` tests.

## Delphi 13 package

The helper is included in the existing package:

```text
Packages/d13/Dext.Web.Core.dpk
```

No additional HTMX package is required.

## Compiler gate

Before merging, perform a clean Delphi 13 build of the Web unit tests and the `Dext.Web.Core` package for Win32/Win64, then run a browser smoke test against HTMX 4. The test DPR explicitly references `Dext.Web.Htmx4.pas`, so the compile cannot accidentally use a stale DCU.
