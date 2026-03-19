unit Dext.Events.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Delegate representing the continuation in the event handling pipeline.
  ///   Call ANext() to pass execution to the next behavior (or the handler).
  ///   Omitting the call short-circuits the pipeline for the current handler.
  /// </summary>
  TEventNextDelegate = reference to procedure;

  /// <summary>
  ///   Carries the result of a Publish call.
  ///   HandlersInvoked counts all handlers that were started, including those
  ///   that raised — use HandlersFailed to distinguish successes.
  /// </summary>
  TPublishResult = record
    HandlersInvoked: Integer;
    HandlersFailed: Integer;
    EventTypeName: string;
    function HandlersSucceeded: Integer; inline;
  end;

  EEventBusException = class(Exception);

  /// <summary>
  ///   Raised by TEventExceptionBehavior when a single handler fails.
  ///   Carries the event type name for diagnosing dispatch failures.
  /// </summary>
  EEventDispatchException = class(EEventBusException)
  public
    EventTypeName: string;
  end;

  /// <summary>
  ///   Raised by IEventBus.Dispatch when one or more handlers raise an
  ///   exception. All handlers are always invoked before this is raised.
  ///   Errors contains one entry per failed handler (ClassName + Message).
  /// </summary>
  EEventDispatchAggregate = class(EEventBusException)
  public
    Errors: TArray<string>;
    constructor Create(const AMessage: string; const AErrors: TArray<string>);
  end;

implementation

{ TPublishResult }

function TPublishResult.HandlersSucceeded: Integer;
begin
  Result := HandlersInvoked - HandlersFailed;
end;

{ EEventDispatchAggregate }

constructor EEventDispatchAggregate.Create(const AMessage: string;
  const AErrors: TArray<string>);
begin
  inherited Create(AMessage);
  Errors := AErrors;
end;

end.
