unit Dext.Logging.Telemetry.Tests;

interface

uses
  Dext.Testing,
  Dext.Logging.Telemetry,
  System.SysUtils,
  System.JSON;

type
  [TestFixture]
  TTelemetryTests = class
  private
    type
      TTestObserver = class(TInterfacedObject, ITelemetryObserver)
      private
        FOnEvent: TProc<TTelemetryEvent>;
      public
        constructor Create(AOnEvent: TProc<TTelemetryEvent>);
        procedure OnEvent(const AEvent: TTelemetryEvent);
      end;
  public
    [Test]
    procedure Test_Observer_Notification;
  end;

implementation

{ TTelemetryTests.TTestObserver }

constructor TTelemetryTests.TTestObserver.Create(AOnEvent: TProc<TTelemetryEvent>);
begin
  inherited Create;
  FOnEvent := AOnEvent;
end;

procedure TTelemetryTests.TTestObserver.OnEvent(const AEvent: TTelemetryEvent);
begin
  if Assigned(FOnEvent) then
    FOnEvent(AEvent);
end;

{ TTelemetryTests }

procedure TTelemetryTests.Test_Observer_Notification;
var
  EventName: string;
  EventPayload: TJSONObject;
  Observer: ITelemetryObserver;
  Data: TJSONObject;
begin
  EventName := '';
  EventPayload := nil;
  
  // Use a weak reference or manual cleanup to avoid issues with JSON ownership if the framework frees it
  // In TDiagnosticSource.Write, Ev.Data.Free is called in the finally block, 
  // so we must CLONE it if we want to inspect it after the event.
  
  Observer := TTestObserver.Create(procedure(AEvent: TTelemetryEvent)
    begin
      EventName := AEvent.Name;
      if AEvent.Data <> nil then
        EventPayload := AEvent.Data.Clone as TJSONObject;
    end);
    
  TDiagnosticSource.Instance.Subscribe(Observer);
  try
    Data := TJSONObject.Create;
    Data.AddPair('test', 'value');
    
    TDiagnosticSource.Instance.Write('test.event', Data);
    
    Should(EventName).Be('test.event');
    Should(EventPayload).NotBeNull;
    if EventPayload <> nil then
      Should(EventPayload.Values['test'].Value).Be('value');
  finally
    TDiagnosticSource.Instance.Unsubscribe(Observer);
    EventPayload.Free;
  end;
end;

end.
