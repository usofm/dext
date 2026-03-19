unit EventBusWebDemo.EventBusConfig;

interface

uses
  Dext;

procedure ConfigureEventBus(const Services: TDextServices);

implementation

uses
  Dext.Events.Extensions,
  Dext.Events.Behaviors,
  EventBusWebDemo.Events;

procedure ConfigureEventBus(const Services: TDextServices);
begin
  TEventBusServices.AddScopedEventBus(Services)
    .AddHandler<TTaskCreatedEvent, TTaskCreatedHandler>
    .AddHandler<TTaskCompletedEvent, TTaskCompletedHandler>
    .AddHandler<TTaskCancelledEvent, TTaskCancelledHandler>
    .AddBehavior<TEventExceptionBehavior>
    .Build;
end;

end.
