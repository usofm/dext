# Telemetry & Live Tracing

Dext provides a powerful, decoupled observability system based on the **Diagnostic Source** pattern. This allows you to monitor database performance, web request lifecycles, and custom events with minimal performance overhead.

## The Diagnostic Source

The central point for telemetry is the `TDiagnosticSource`. It acts as a publisher where framework components and your own code can "write" events that observers can "subscribe" to.

### Subscribing to Events

To monitor events, you subscribe an observer (a callback) to the source.

```pascal
uses Dext.Logging.Telemetry, System.JSON;

initialization
  TDiagnosticSource.Instance.Subscribe(procedure(const AName: string; const APayload: TJSONObject)
    begin
      if AName.StartsWith('SQL.') then
        LogSQL(APayload);
    end);
```

## The ILogger Bridge

Dext comes with a built-in "bridge" that automatically routes telemetry events to the logging system (`ILogger`). This is extremely useful during development to see what is happening without needing an external dashboard.

To activate it, ensure that telemetry is enabled in your configuration:

```json
{
  "Logging": {
    "CaptureTelemetry": true
  }
}
```

In the console, you will see output like:
```text
info: Telemetry
      [SQL] SELECT "Id", "Name" FROM "Customers" (2ms)
info: Telemetry
      [HTTP] GET /api/orders - 200 (15ms)
```

## Built-in Instrumentation

### Database (ORM)
The `TDbSet<T>` automatically publishes the following events:

| Event Name | Description | Payload Data |
| :--- | :--- | :--- |
| `SQL.Query` | Executed a SELECT | `SQL`, `DurationMs`, `Rows`, `Error` |
| `SQL.Insert` | Executed an INSERT | `SQL`, `DurationMs`, `Id`, `Error` |
| `SQL.Update` | Executed an UPDATE | `SQL`, `DurationMs`, `Rows`, `Error` |
| `SQL.Delete` | Executed a DELETE | `SQL`, `DurationMs`, `Rows`, `Error` |

### Web Framework
The `TDextPipeline` publishes HTTP lifecycle events:

| Event Name | Description | Payload Data |
| :--- | :--- | :--- |
| `HTTP.Request` | Full request execution | `Method`, `Path`, `StatusCode`, `DurationMs` |

## Writing Custom Events

You can instrument your own business logic using the `Write` method.

```pascal
var Payload := TJSONObject.Create;
Payload.AddPair('OrderId', LOrderId);
Payload.AddPair('Amount', LAmount);

TDiagnosticSource.Instance.Write('Business.OrderProcessed', Payload);
```

## Performance Note
If there are no subscribers for a specific event, the payload generation and dispatch are skipped, ensuring that telemetry has **near-zero cost** when not in use.

---
 
 [← Next: Advanced Features](../10-advanced/README.md) | [Next: Logging →](logging.md)
