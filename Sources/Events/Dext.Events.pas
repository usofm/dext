unit Dext.Events;

interface

uses
  Dext.Events.Types,
  Dext.Events.Interfaces,
  Dext.Events.Behaviors,
  Dext.Events.Extensions,
  Dext.Events.Lifecycle;

type
  // --- Types (Dext.Events.Types) ---
  TEventNextDelegate      = Dext.Events.Types.TEventNextDelegate;
  TPublishResult          = Dext.Events.Types.TPublishResult;
  EEventBusException      = Dext.Events.Types.EEventBusException;
  EEventDispatchException = Dext.Events.Types.EEventDispatchException;
  EEventDispatchAggregate = Dext.Events.Types.EEventDispatchAggregate;

  // --- Interfaces (Dext.Events.Interfaces) ---
  IEventHandler  = Dext.Events.Interfaces.IEventHandler;
  IEventBehavior = Dext.Events.Interfaces.IEventBehavior;
  IEventBus      = Dext.Events.Interfaces.IEventBus;

  // --- Behaviors (Dext.Events.Behaviors) ---
  TEventExceptionBehavior = Dext.Events.Behaviors.TEventExceptionBehavior;
  TEventLoggingBehavior   = Dext.Events.Behaviors.TEventLoggingBehavior;
  TEventTimingBehavior    = Dext.Events.Behaviors.TEventTimingBehavior;

  // --- DI Extensions (Dext.Events.Extensions) ---
  TEventBusServices = Dext.Events.Extensions.TEventBusServices;
  TEventBusBuilder  = Dext.Events.Extensions.TEventBusBuilder;

  // --- Lifecycle (Dext.Events.Lifecycle) ---
  TApplicationStartedEvent  = Dext.Events.Lifecycle.TApplicationStartedEvent;
  TApplicationStoppingEvent = Dext.Events.Lifecycle.TApplicationStoppingEvent;
  TApplicationStoppedEvent  = Dext.Events.Lifecycle.TApplicationStoppedEvent;

implementation

end.
