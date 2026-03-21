---
description: >-
  HTMX integration patterns, partial rendering, and interactive UI recipes for
  Dext Framework SSR applications using Web Stencils.
---

<skill>

# Dext Framework — HTMX Integration Patterns

You are an expert in building interactive, HTMX-powered server-side rendered applications with Dext and Web Stencils. You know how to structure partial views, manage swap targets, handle search/filter/sort/pagination patterns, and build rich UIs without client-side JavaScript frameworks.

**Prerequisite**: Load `dext-view-engine` first for Web Stencils syntax and Dext `Results.View` API.

---

## 1. How Dext + HTMX Works (from source: `TViewResult.Render`)

1. The browser sends a request with the `HX-Request: true` header.
2. In `TViewResult.Render`, Dext checks: if `'Layout'` key is NOT already set in ViewData AND `HX-Request` header is present → sets Layout to `''` (empty string).
3. The `TWebStencilsViewEngine` sees the empty layout and renders ONLY the partial template content.
4. HTMX swaps the returned HTML fragment into the designated `hx-target`.

**Key insight from source**: Layout suppression is **automatic** for HTMX requests. You do NOT need `.WithLayout('')` unless you want to force layout suppression on a non-HTMX request, or if you explicitly set a layout and want to override it.

```pascal
// NOT needed for HTMX — auto-detected:
Result := Results.View<TCustomer>('customers_list', query);

// Only needed for non-HTMX partial rendering:
Result := Results.View<TCustomer>('customers_list', query).WithLayout('');
```

---

## 2. Pattern Catalog

### 2.1 Live Search with Debounce

**Route:**

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

**Full page template (customers.html):**

```html
@LayoutPage _Layout.html

<div class="space-y-8">
  <div class="flex justify-between items-end">
    <h2>Customers</h2>
    <div class="w-96 relative">
      <input type="text" id="search-input" name="SearchTerm"
          placeholder="Search..."
          hx-get="/customers/search"
          hx-trigger="keyup changed delay:300ms"
          hx-target="#results-tbody"
          hx-indicator="#search-indicator">
    </div>
  </div>

  <table>
    <thead>
      <tr>
        <th>ID</th><th>Name</th><th>Email</th><th>Actions</th>
      </tr>
    </thead>
    <tbody id="results-tbody">
      @Import customers_list
    </tbody>
  </table>

  <div id="search-indicator" class="htmx-indicator">
    <span class="animate-pulse">Searching...</span>
  </div>
</div>
```

**Partial template (customers_list.html):**

```html
@foreach (var item in Model) {
<tr>
    <td>@(Prop(item.Id))</td>
    <td>@(Prop(item.Name))</td>
    <td>@(Prop(item.Email))</td>
    <td><button class="text-blue-400">Edit</button></td>
</tr>
}
@if Model.IsEmpty {
<tr>
    <td colspan="4" class="text-center italic">No results found.</td>
</tr>
}
```

**Key points:**
- `hx-trigger="keyup changed delay:300ms"` — debounces 300ms after typing stops
- `hx-target="#results-tbody"` — replaces only the table body
- `hx-indicator` — shows a loading spinner during the request
- The `name="SearchTerm"` attribute maps to the `TSearchDTO.SearchTerm` field

### 2.2 Click-to-Load Detail Panel

```html
<button hx-get="/customers/@(Prop(item.Id))/detail"
        hx-target="#detail-panel"
        hx-swap="innerHTML">
  View Details
</button>

<div id="detail-panel"></div>
```

Route:

```pascal
.MapGet<TAppDbContext, IResult>('/customers/{id}/detail',
  function(Db: TAppDbContext; [FromRoute] Id: Integer): IResult
  begin
    Result := Results.View<TCustomer>('customer_detail',
      Db.Customers.Find(Id)
    );
  end)
```

### 2.3 Inline Edit

**Display row:**

```html
<tr id="customer-row-@(Prop(item.Id))">
    <td>@(Prop(item.Name))</td>
    <td>@(Prop(item.Email))</td>
    <td>
        <button hx-get="/customers/@(Prop(item.Id))/edit"
                hx-target="#customer-row-@(Prop(item.Id))"
                hx-swap="outerHTML">
          Edit
        </button>
    </td>
</tr>
```

**Edit row (customer_edit_row.html):**

```html
<tr id="customer-row-@(Prop(Model.Id))">
    <td>
      <input type="text" name="Name" value="@(Prop(Model.Name))">
    </td>
    <td>
      <input type="email" name="Email" value="@(Prop(Model.Email))">
    </td>
    <td>
        <button hx-put="/customers/@(Prop(Model.Id))"
                hx-target="#customer-row-@(Prop(Model.Id))"
                hx-swap="outerHTML"
                hx-include="closest tr">
          Save
        </button>
        <button hx-get="/customers/@(Prop(Model.Id))/row"
                hx-target="#customer-row-@(Prop(Model.Id))"
                hx-swap="outerHTML">
          Cancel
        </button>
    </td>
</tr>
```

### 2.4 Delete with Confirmation

```html
<button hx-delete="/customers/@(Prop(item.Id))"
        hx-target="#customer-row-@(Prop(item.Id))"
        hx-swap="outerHTML swap:500ms"
        hx-confirm="Are you sure you want to delete this customer?">
  Delete
</button>
```

Route returns an empty response or a fade-out element:

```pascal
.MapDelete<TAppDbContext, IResult>('/customers/{id}',
  function(Db: TAppDbContext; [FromRoute] Id: Integer): IResult
  begin
    var customer := Db.Customers.Find(Id);
    if customer <> nil then
    begin
      Db.Customers.Remove(customer);
      Db.SaveChanges;
    end;
    Result := Results.Content('');  // Empty = row disappears
  end)
```

### 2.5 Modal Dialog

**Trigger:**

```html
<button hx-get="/customers/new"
        hx-target="#modal-container"
        hx-swap="innerHTML">
  New Customer
</button>

<div id="modal-container"></div>
```

**Modal partial (customer_modal.html):**

```html
<div class="fixed inset-0 bg-black/50 flex items-center justify-center" id="modal-backdrop">
  <div class="bg-slate-800 rounded-2xl p-8 w-96">
    <h3>New Customer</h3>
    <form hx-post="/customers"
          hx-target="#results-tbody"
          hx-swap="beforeend">
      <input type="text" name="Name" placeholder="Name" required>
      <input type="email" name="Email" placeholder="Email" required>
      <div class="flex gap-4">
        <button type="submit">Create</button>
        <button type="button"
                onclick="document.getElementById('modal-backdrop').remove()">
          Cancel
        </button>
      </div>
    </form>
  </div>
</div>
```

### 2.6 Pagination

**Template:**

```html
<div class="flex gap-2">
  @if (pagination.HasPrevious) {
    <button hx-get="/customers?page=@(pagination.PageNumber - 1)"
            hx-target="#customer-table">
      Previous
    </button>
  }

  <span>Page @pagination.PageNumber of @pagination.TotalPages</span>

  @if (pagination.HasNext) {
    <button hx-get="/customers?page=@(pagination.PageNumber + 1)"
            hx-target="#customer-table">
      Next
    </button>
  }
</div>
```

### 2.7 Sortable Table Headers

```html
<th>
  <button hx-get="/customers?sort=name&dir=asc"
          hx-target="#results-tbody">
    Name ↑
  </button>
</th>
```

### 2.8 Tab Navigation

```html
<div class="flex border-b">
  <button hx-get="/dashboard/overview"
          hx-target="#tab-content"
          class="tab-btn">
    Overview
  </button>
  <button hx-get="/dashboard/analytics"
          hx-target="#tab-content"
          class="tab-btn">
    Analytics
  </button>
</div>
<div id="tab-content">
  @Import dashboard_overview
</div>
```

### 2.9 Form Submission with Validation Feedback

```html
<form hx-post="/customers"
      hx-target="#form-container"
      hx-swap="outerHTML">
  <div id="form-container">
    <input type="text" name="Name" required>
    <input type="email" name="Email" required>
    <button type="submit">Create</button>
  </div>
</form>
```

On validation error, return the form with error messages:

```pascal
Result := Results.View('customer_form')
  .WithValue('Errors', ValidationErrors)
  .WithValue('Name', SubmittedName)
  .WithValue('Email', SubmittedEmail);
```

### 2.10 Infinite Scroll

```html
@foreach (var item in Model) {
<div class="card">
  <h3>@(Prop(item.Name))</h3>
  <p>@(Prop(item.Description))</p>
</div>
}

@if (pagination.HasNext) {
<div hx-get="/items?page=@(pagination.NextPage)"
     hx-trigger="revealed"
     hx-swap="outerHTML">
  <span class="animate-pulse">Loading more...</span>
</div>
}
```

---

## 3. Request/Response DTO Pattern

Define a record for query string binding:

```pascal
type
  TSearchDTO = record
    SearchTerm: string;
  end;

  TPaginationDTO = record
    Page: Integer;
    PageSize: Integer;
    Sort: string;
    Dir: string;
  end;
```

Dext auto-binds query parameters to record fields by name.

---

## 4. HTMX Response Headers

For advanced control, set response headers:

| Header | Purpose |
|---|---|
| `HX-Redirect` | Force client-side redirect |
| `HX-Refresh` | Force full page refresh |
| `HX-Retarget` | Change target element |
| `HX-Reswap` | Change swap strategy |
| `HX-Trigger` | Trigger client-side event |
| `HX-Push-Url` | Update browser URL |

---

## 5. Loading Indicators

HTMX shows elements with class `htmx-indicator` during requests:

```html
<!-- Spinner -->
<div id="my-indicator" class="htmx-indicator">
  <svg class="animate-spin h-5 w-5" viewBox="0 0 24 24">
    <circle cx="12" cy="12" r="10" stroke="currentColor"
            stroke-width="4" fill="none" opacity="0.25"/>
    <path fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/>
  </svg>
</div>
```

Reference it with `hx-indicator="#my-indicator"`.

---

## 6. Clear Search with JavaScript Reset

```html
<div class="relative">
  <input type="text" id="search-input" name="SearchTerm"
      hx-get="/customers/search"
      hx-trigger="keyup changed delay:300ms"
      hx-target="#results-tbody"
      oninput="this.nextElementSibling.classList.toggle('hidden', !this.value)">

  <button type="button" class="absolute right-2 top-1/2 -translate-y-1/2 hidden"
      onclick="let inp = document.getElementById('search-input');
               inp.value = '';
               inp.dispatchEvent(new Event('input'));
               htmx.trigger('#search-input', 'keyup');
               this.classList.add('hidden')">
    ✕
  </button>
</div>
```

---

## 7. Extending with AlpineJS or Hyperscript

For lightweight client-side interactivity alongside HTMX:

**AlpineJS:**

```html
<script src="https://cdn.jsdelivr.net/npm/alpinejs@3"></script>

<div x-data="{ open: false }">
  <button @click="open = !open">Toggle</button>
  <div x-show="open" x-transition>
    Dropdown content
  </div>
</div>
```

**Hyperscript:**

```html
<script src="https://unpkg.com/hyperscript.org@0.9"></script>

<button _="on click toggle .hidden on #panel">
  Toggle Panel
</button>
```

Both integrate cleanly with HTMX — Alpine for reactive state, Hyperscript for declarative event handling.

</skill>
