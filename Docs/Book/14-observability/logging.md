# Logging and Diagnostics

Dext features a robust logging system, inspired by the .NET ecosystem, which allows you to record structured messages and direct them to different destinations (Sinks).

## Basic Configuration

Logging is configured in the `ConfigureServices` method of your `Startup` class using the fluent builder:

```pascal
procedure TStartup.ConfigureServices(const Services: TDextServices; const Configuration: IConfiguration);
begin
  Services.AddLogging(
    procedure(Builder: ILoggingBuilder)
    begin
      Builder
        .SetMinimumLevel(TLogLevel.Information)
        .AddConsole
        .AddTelemetry; // Routes telemetry events to the log
    end);
end;
```

## Log Levels

The following levels are available (in order of severity):

| Level | Description |
| :--- | :--- |
| `Trace` | Detailed logs for deep diagnostics. |
| `Debug` | Logs useful during development. |
| `Information` | Normal application flows (startup, requests). |
| `Warning` | Anomalous events that do not interrupt the flow. |
| `Error` | Failures that prevent a specific operation. |
| `Critical` | Critical failures requiring immediate attention. |

## File Logging

Dext includes a native provider for recording logs to files. Files are recorded in **JSON Lines** format by default, making them easy to consume by analysis tools.

```pascal
Builder.AddFile('logs/app.log');
```

The provider automatically manages the creation of necessary directories.

## Using ILogger

To record messages, you should request the `ILogger` interface via Dependency Injection in your controllers or services:

```pascal
type
  TMyController = class(TWebController)
  private
    FLogger: ILogger;
  public
    constructor Create(const ALogger: ILogger);
    
    function Get: IWebResponse;
  end;

function TMyController.Get: IWebResponse;
begin
  FLogger.Info('Processing request for {Path}', [Request.Path]);
  // ...
end;
```

### Structured Messages

Dext supports structured messages using the `{}` brace syntax. This allows advanced providers (like the Telemetry Bridge) to capture parameters independently of the formatted message.

```pascal
FLogger.LogInformation('Order {Id} processed successfully in {Duration}ms', [LOrderId, LDuration]);
```

## HTTP Request Logging

To automatically record all HTTP requests (URL, Method, Status Code, Time), add the middleware in the `Configure` method:

```pascal
procedure TStartup.Configure(const App: IWebApplication);
begin
  App.Builder.UseHttpLogging;
  // ...
end;
```

---

[← Telemetry](telemetry.md)
