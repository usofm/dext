unit Dext.Events.Interfaces;

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  Dext.DI.Interfaces,
  Dext.Events.Types;

type
  /// <summary>
  ///   Marker base interface for all event handlers.
  ///   Internal — implement IEventHandler&lt;T&gt; in application code.
  /// </summary>
  IEventHandler = interface
    ['{A1E74C28-3F9D-4B5A-8C0E-2D6F1A7B3C9E}']
  end;

  /// <summary>
  ///   Type-safe event handler. Implement this interface to handle event type T.
  ///   Handlers are resolved from the DI container on every Publish call, so
  ///   constructor injection of all service lifetimes is fully supported.
  /// </summary>
  IEventHandler<T> = interface(IEventHandler)
    ['{B2F85D39-4E0A-5C6B-9D1F-3E7A2B8C4D0F}']
    procedure Handle(const AEvent: T);
  end;

  /// <summary>
  ///   Cross-cutting behavior applied around every handler invocation.
  ///   Behaviors form an ordered pipeline — each must call ANext() to continue.
  ///   Registered globally (all events) or per event type.
  ///
  ///   Named Intercept (not Handle) to clearly distinguish middleware from
  ///   the final IEventHandler&lt;T&gt;.Handle call.
  /// </summary>
  IEventBehavior = interface
    ['{C3A96E4A-5F1B-6D7C-0E2A-4F8B3C9D5E1A}']
    procedure Intercept(AEventType: PTypeInfo; const AEvent: TValue;
      const ANext: TEventNextDelegate);
  end;

  /// <summary>
  ///   Typed single-event publisher facade. Narrower dependency than IEventBus —
  ///   inject IEventPublisher&lt;TOrderCreatedEvent&gt; instead of IEventBus in
  ///   components that only ever publish one specific event type.
  ///   Follows the Interface Segregation Principle.
  /// </summary>
  IEventPublisher<T> = interface
    ['{A7B3C9D1-E5F4-4B2A-9E0D-1C8F7A6B5D3E}']
    function Publish(const AEvent: T): TPublishResult;
    procedure PublishBackground(const AEvent: T);
  end;

  /// <summary>
  ///   The central event bus.
  ///   Register as singleton via TEventBusServices.AddEventBus() or as scoped
  ///   (shares the request DI scope) via TEventBusServices.AddScopedEventBus().
  ///
  ///   IEventBus intentionally uses TValue-based methods — Delphi interfaces
  ///   cannot declare generic methods (E2535). For generic call-site sugar use
  ///   TEventBusExtensions.Publish&lt;T&gt; / PublishBackground&lt;T&gt;, or inject the
  ///   narrow IEventPublisher&lt;T&gt; (preferred).
  /// </summary>
  IEventBus = interface
    ['{D4B07F5B-6A2C-7E8D-1F3B-5A9C4D0E6F2B}']
    function Dispatch(AEventType: PTypeInfo;
      const AEvent: TValue): TPublishResult;
    procedure DispatchBackground(AEventType: PTypeInfo; const AEvent: TValue);
  end;

  /// <summary>
  ///   Internal registry: maps event TypeInfo to handler factory lists and
  ///   manages global + per-event behavior factory lists.
  ///   Populated at startup. Do not consume directly — use IEventBus.
  /// </summary>
  IEventHandlerRegistry = interface
    ['{E5C18A6C-7B3D-8F9E-2A4C-6B0D5E1F7A3C}']
    procedure RegisterHandler(AEventType: PTypeInfo;
      const AFactory: TFunc<IServiceProvider, TObject>);
    procedure RegisterBehavior(
      const AFactory: TFunc<IServiceProvider, TObject>);
    procedure RegisterEventBehavior(AEventType: PTypeInfo;
      const AFactory: TFunc<IServiceProvider, TObject>);
    function GetHandlerFactories(AEventType: PTypeInfo):
      TArray<TFunc<IServiceProvider, TObject>>;
    function GetBehaviorFactories:
      TArray<TFunc<IServiceProvider, TObject>>;
    function GetEventBehaviorFactories(AEventType: PTypeInfo):
      TArray<TFunc<IServiceProvider, TObject>>;
  end;

  /// <summary>
  ///   Typed call-site sugar over IEventBus.
  ///   Delphi E2535 prevents generic methods on interfaces, so these static
  ///   helpers box the event to TValue and delegate to IEventBus.Dispatch.
  /// </summary>
  TEventBusExtensions = record
    class function Publish<T>(const ABus: IEventBus;
      const AEvent: T): TPublishResult; static; inline;
    class procedure PublishBackground<T>(const ABus: IEventBus;
      const AEvent: T); static; inline;
  end;

implementation

{ TEventBusExtensions }

class function TEventBusExtensions.Publish<T>(const ABus: IEventBus;
  const AEvent: T): TPublishResult;
var
  V: TValue;
begin
  TValue.Make(@AEvent, TypeInfo(T), V);
  Result := ABus.Dispatch(TypeInfo(T), V);
end;

class procedure TEventBusExtensions.PublishBackground<T>(const ABus: IEventBus;
  const AEvent: T);
var
  V: TValue;
begin
  TValue.Make(@AEvent, TypeInfo(T), V);
  ABus.DispatchBackground(TypeInfo(T), V);
end;

end.
