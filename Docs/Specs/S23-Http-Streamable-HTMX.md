# Specification S23: HTTP Streamable Sessions & Native HTMX Integration

## 1. Overview
This specification details the addition of **Streamable Sessions** and **Native HTMX Support** to the core HTTP stack of the Dext Framework. Inspired by the Model Context Protocol (MCP 2025-03-26) Streamable pattern, this feature provides a robust, connection-independent way to manage state across requests and seamlessly broadcast Server-Sent Events (SSE) containing HTML fragments.

While this feature will fundamentally redesign the **Dext Sidecar / Dashboard** communication protocol (replacing complex, fragile SSE pipelines with HTMX), it is built as a core capability available to *any* Dext web application.

## 2. Motivation & Problems Solved
Historically, building real-time or stateful web dashboards involved heavy JavaScript frameworks and misusing SSE or WebSockets as bidirectional tunnels.
- **Proxy and Firewall drops:** Load balancers (NGINX, ALB) frequently drop long-lived SSE connections.
- **State Loss:** When an SSE connection drops, the server loses the client's context.
- **Asynchronous Command Hell:** Sending a command over a stream and waiting for an asynchronous response requires messy correlation IDs.

**The Dext Solution:**
We implement "Streamable Sessions" at the `Dext.WebHost` layer.
1. **Commands/Actions:** Executed via standard synchronous `POST` requests.
2. **Session State:** Maintained across stateless POST requests using a `Dext-Session-Id` HTTP header.
3. **Unidirectional Telemetry:** Handled via a read-only SSE stream that exclusively broadcasts HTML fragments, native to HTMX (`htmx.ext.sse`).

## 3. Core Architecture (Dext.WebHost)

### 3.1. IStreamableSession & Session Manager
The framework will introduce a session management abstraction independent of the transport connection.

```pascal
type
  IStreamableSession = interface
    ['{GUID}']
    function GetId: string;
    procedure SetState(const Key: string; const Value: TValue);
    function GetState(const Key: string): TValue;
    procedure SendSseEvent(const EventName, HtmlFragment: string);
  end;

  IStreamableSessionManager = interface
    ['{GUID}']
    function CreateSession: IStreamableSession;
    function GetSession(const SessionId: string): IStreamableSession;
    procedure DestroySession(const SessionId: string);
  end;
```

When a request arrives with the `Dext-Session-Id` header (or cookie), the HTTP context (`IHttpContext`) will automatically resolve the `IStreamableSession`.

### 3.2. Native HTMX Integration
Dext's HTTP stack will natively recognize HTMX requests by inspecting the `HX-Request` header.
- The `IHttpResponse` will have helpers like `Res.Htmx.TriggerEvent('cache-cleared')` or `Res.Htmx.Retarget('#toast')`.
- The View Engine will support rendering partial fragments tailored for HTMX swapping.

### 3.3. Session Lifecycle & Memory Management
In a multi-threaded HTTP server environment (like Dext WebHost based on Indy), proper lifecycle management is critical to prevent memory leaks and ensure thread safety.

1. **Thread-Safety:** `IStreamableSessionManager` must use a highly concurrent structure (e.g., locking via `TMonitor` or a `TThreadDictionary`) to ensure that multiple incoming HTMX requests can safely read/write to the same session state simultaneously.
2. **Idle Timeouts (Garbage Collection):** Since HTMX sessions do not rely on an always-open WebSocket, we cannot rely on the TCP connection closing to destroy the session. 
   - Every time a session is accessed via the `Dext-Session-Id` header, its `LastAccessed` timestamp is updated.
   - The session manager runs a lightweight background task (or sweeps during request allocation) to destroy sessions idle for more than `N` minutes (e.g., 30 minutes).
3. **SSE Connection Binding:** 
   - A session may have zero or one active `IHttpResponse` associated with the SSE stream. 
   - When `Session.SendSseEvent` is called:
     - If the SSE connection is alive, it streams the HTML immediately.
     - If the SSE connection is dead (e.g., dropped by NGINX), the event is simply dropped. HTMX relies on eventual consistency, meaning the next polling or the next user action will fetch the latest state anyway. We do *not* buffer HTML fragments indefinitely, saving RAM.

### 3.4. Distributed Environments (Horizontal Scaling)
While the `TInMemoryStreamableSessionManager` is perfect for a single-node setup (like the Sidecar embedded in a monolith), Dext applications often scale horizontally.

The framework will foresee a provider architecture for the manager:
- `TRedisStreamableSessionManager`: Backed by Dext's existing Redis client. State is stored in Redis hashes (`HSET dext:session:ID`), allowing a load-balanced cluster to handle any HTMX request.
- *Note on SSE with Redis:* To support `SendSseEvent` across multiple nodes, the manager will use Redis Pub/Sub to broadcast the HTMX fragment to the specific node that currently holds the active SSE connection for that session.

## 4. Application: Dext Sidecar Redesign
The primary consumer of this new core feature is the Dext Sidecar. The Dashboard is now built purely with **HTML, Tailwind CSS, and HTMX** (no Node.js/Vue.js dependencies).

### 4.1. Session Initialization
The dashboard requests a Session ID on page load.
**Endpoint:** `POST /sidecar/initialize`
**Response:** `{"sessionId": "a1b2c3d4-e5f6-7890"}`

The frontend configures HTMX to attach this ID to every subsequent request:
```javascript
document.body.addEventListener('htmx:configRequest', function(evt) {
    const sessionId = localStorage.getItem('dext_sidecar_session_id');
    if (sessionId) {
        evt.detail.headers['Dext-Session-Id'] = sessionId;
    }
});
```

### 4.2. Synchronous Commands (HTMX POST)
All Sidecar actions (e.g., trigger GC, clear cache) are standard REST `POST` requests using the Streamable Session.
```html
<button 
  hx-post="/sidecar/commands/clear-cache" 
  hx-target="#toast-container" 
  hx-swap="beforeend"
  class="bg-blue-500 text-white px-4 py-2 rounded">
  Clear Cache
</button>
```

**Delphi Server Side:**
```pascal
[HttpPost('/sidecar/commands/clear-cache')]
procedure ClearCache(const Ctx: IHttpContext);
begin
  // The Session is already resolved via the Dext-Session-Id header
  SystemCache.Clear;
  
  // Return an HTML fragment for HTMX to swap into the toast container
  Ctx.Response.Html(
    '<div class="toast toast-success" hx-trigger="load delay:3s" hx-swap="delete">Cache cleared!</div>'
  );
end;
```

### 4.3. Unidirectional Telemetry (SSE + HTMX)
The SSE connection becomes a "dumb" broadcast pipe. If a firewall drops it, HTMX simply reconnects. No critical commands depend on it.

**HTMX Client:**
```html
<div hx-ext="sse" sse-connect="/sidecar/stream">
  <!-- Server sends an event named "cpu-update" with an HTML fragment -->
  <div sse-swap="cpu-update" hx-target="#cpu-gauge" hx-swap="innerHTML"></div>
</div>
```

**Delphi Server Side:**
```pascal
procedure BroadcastMetrics(const Session: IStreamableSession; CpuUsage: Double);
var
  HtmlFragment: string;
begin
  // Using Dext View Engine to generate the HTMX fragment
  HtmlFragment := FViewEngine.Render('Sidecar/Partials/CpuGauge', ['Cpu', CpuUsage]);
  
  // Streamable Session manages pushing this to the active SSE tunnel (if connected)
  Session.SendSseEvent('cpu-update', HtmlFragment);
end;
```

## 5. Summary of Benefits
1. **Core Framework Capability:** Every Dext application can now build resilient, real-time HTMX dashboards out-of-the-box.
2. **Zero Node.js/Build Step:** Emitting HTML fragments from Delphi allows complex UIs to be served directly from the Dext executable.
3. **Extreme Resilience:** Commands are decoupled from fragile SSE connections. A flaky proxy might delay the metrics stream, but core actions (like "Restart Node") execute flawlessly via standard HTTP POSTs.
