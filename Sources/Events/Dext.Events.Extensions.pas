unit Dext.Events.Extensions;

interface

uses
  System.SysUtils,
  System.TypInfo,
  Dext.Collections,
  Dext,
  Dext.DI.Interfaces,
  Dext.Core.Activator,
  Dext.Events.Types,
  Dext.Events.Interfaces,
  Dext.Events.Bus;

type
  THandlerRegistration = record
    EventType: PTypeInfo;
    HandlerClass: TClass;
  end;

  TBehaviorRegistration = record
    EventType: PTypeInfo;
    BehaviorClass: TClass;
  end;

  /// <summary>
  ///   Fluent builder for configuring the Dext Event Bus.
  ///   Returned by TEventBusServices.AddEventBus / AddScopedEventBus.
  ///   Call Build at the end to finalize DI registration.
  ///
  ///   <code>
  ///     TEventBusServices.AddEventBus(Services)
  ///       .AddHandler&lt;TOrderPlacedEvent, TOrderEmailHandler&gt;
  ///       .AddBehavior&lt;TEventExceptionBehavior&gt;
  ///       .AddBehaviorFor&lt;TOrderPlacedEvent, TOrderValidationBehavior&gt;
  ///       .AddPublisher&lt;TOrderPlacedEvent&gt;
  ///       .Build;
  ///   </code>
  /// </summary>
  TEventBusBuilder = record
  private
    FServices: IServiceCollection;
    FHandlers: IList<THandlerRegistration>;
    FBehaviors: IList<TBehaviorRegistration>;
    FCreateScope: Boolean;
  public
    function AddHandler<TEvent; THandler: class>: TEventBusBuilder;
    function AddBehavior<TBehavior: class>: TEventBusBuilder;
    function AddBehaviorFor<TEvent; TBehavior: class>: TEventBusBuilder;
    function AddPublisher<T>: TEventBusBuilder;
    function AddLifecycle: TEventBusBuilder;
    procedure Build;
  end;

  /// <summary>
  ///   Static entry point for Event Bus DI registration.
  ///   Returns a TEventBusBuilder for fluent configuration.
  ///
  ///   No record helper — works alongside TWebServicesHelper and
  ///   TDextPersistenceServicesHelper without Delphi's
  ///   single-record-helper-per-type limitation.
  /// </summary>
  TEventBusServices = class
    class function AddEventBus(
      const Services: TDextServices): TEventBusBuilder; static;
    class function AddScopedEventBus(
      const Services: TDextServices): TEventBusBuilder; static;

    /// <summary>
    ///   Registers IEventPublisher&lt;T&gt; independently of the builder.
    ///   Useful with TEventBusTracker in test setups where no builder is used.
    /// </summary>
    class procedure AddPublisher<T>(const Services: TDextServices); static;
  end;

implementation

uses
  Dext.Hosting.BackgroundService,
  Dext.Events.Lifecycle;

function MakeActivatorFactory(AClass: TClass): TFunc<IServiceProvider, TObject>;
begin
  Result :=
    function(P: IServiceProvider): TObject
    begin
      Result := TActivator.CreateInstance(P, AClass);
    end;
end;

{ TEventBusServices }

class function TEventBusServices.AddEventBus(
  const Services: TDextServices): TEventBusBuilder;
begin
  Result.FServices := Services.Unwrap;
  Result.FHandlers := TCollections.CreateList<THandlerRegistration>;
  Result.FBehaviors := TCollections.CreateList<TBehaviorRegistration>;
  Result.FCreateScope := True;
end;

class function TEventBusServices.AddScopedEventBus(
  const Services: TDextServices): TEventBusBuilder;
begin
  Result.FServices := Services.Unwrap;
  Result.FHandlers := TCollections.CreateList<THandlerRegistration>;
  Result.FBehaviors := TCollections.CreateList<TBehaviorRegistration>;
  Result.FCreateScope := False;
end;

class procedure TEventBusServices.AddPublisher<T>(const Services: TDextServices);
begin
  Services.Unwrap.AddTransient(
    TServiceType.FromInterface(TypeInfo(IEventPublisher<T>)),
    TEventPublisher<T>,
    function(P: IServiceProvider): TObject
    var
      Bus: IEventBus;
    begin
      Bus := TServiceProviderExtensions.GetRequiredService<IEventBus>(P);
      Result := TEventPublisher<T>.Create(Bus);
    end
  );
end;

{ TEventBusBuilder }

function TEventBusBuilder.AddHandler<TEvent, THandler>: TEventBusBuilder;
var
  Entry: THandlerRegistration;
begin
  Entry.EventType    := TypeInfo(TEvent);
  Entry.HandlerClass := THandler;
  FHandlers.Add(Entry);
  FServices.AddTransient(TServiceType.FromClass(THandler), THandler, nil);
  Result := Self;
end;

function TEventBusBuilder.AddBehavior<TBehavior>: TEventBusBuilder;
var
  Entry: TBehaviorRegistration;
begin
  Entry.EventType     := nil;
  Entry.BehaviorClass := TBehavior;
  FBehaviors.Add(Entry);
  FServices.AddTransient(TServiceType.FromClass(TBehavior), TBehavior, nil);
  Result := Self;
end;

function TEventBusBuilder.AddBehaviorFor<TEvent, TBehavior>: TEventBusBuilder;
var
  Entry: TBehaviorRegistration;
begin
  Entry.EventType     := TypeInfo(TEvent);
  Entry.BehaviorClass := TBehavior;
  FBehaviors.Add(Entry);
  FServices.AddTransient(TServiceType.FromClass(TBehavior), TBehavior, nil);
  Result := Self;
end;

function TEventBusBuilder.AddPublisher<T>: TEventBusBuilder;
begin
  FServices.AddTransient(
    TServiceType.FromInterface(TypeInfo(IEventPublisher<T>)),
    TEventPublisher<T>,
    function(P: IServiceProvider): TObject
    var
      Bus: IEventBus;
    begin
      Bus := TServiceProviderExtensions.GetRequiredService<IEventBus>(P);
      Result := TEventPublisher<T>.Create(Bus);
    end
  );
  Result := Self;
end;

function TEventBusBuilder.AddLifecycle: TEventBusBuilder;
var
  LifecycleClass: TClass;
begin
  LifecycleClass := TEventBusLifecycleService;

  FServices.AddSingleton(
    TServiceType.FromClass(TEventBusLifecycleService),
    TEventBusLifecycleService,
    function(P: IServiceProvider): TObject
    begin
      Result := TActivator.CreateInstance(P, TEventBusLifecycleService);
    end
  );

  FServices.AddSingleton(
    TServiceType.FromInterface(TypeInfo(IHostedServiceManager)),
    THostedServiceManager,
    function(P: IServiceProvider): TObject
    var
      Manager: THostedServiceManager;
      ServiceObj: TObject;
      HostedSvc: IHostedService;
    begin
      Manager := THostedServiceManager.Create;
      ServiceObj := P.GetService(TServiceType.FromClass(LifecycleClass));
      if Supports(ServiceObj, IHostedService, HostedSvc) then
        Manager.RegisterService(HostedSvc);
      Result := Manager;
    end
  );

  Result := Self;
end;

procedure TEventBusBuilder.Build;
var
  CapturedHandlers: IList<THandlerRegistration>;
  CapturedBehaviors: IList<TBehaviorRegistration>;
begin
  CapturedHandlers := FHandlers;
  CapturedBehaviors := FBehaviors;

  FServices.AddSingleton(
    TServiceType.FromInterface(TypeInfo(IEventHandlerRegistry)),
    TEventHandlerRegistry,
    function(AProvider: IServiceProvider): TObject
    var
      Registry: TEventHandlerRegistry;
      HEntry: THandlerRegistration;
      BEntry: TBehaviorRegistration;
    begin
      Registry := TEventHandlerRegistry.Create;

      for HEntry in CapturedHandlers do
        Registry.RegisterHandler(HEntry.EventType,
          MakeActivatorFactory(HEntry.HandlerClass));

      for BEntry in CapturedBehaviors do
      begin
        if BEntry.EventType = nil then
          Registry.RegisterBehavior(MakeActivatorFactory(BEntry.BehaviorClass))
        else
          Registry.RegisterEventBehavior(BEntry.EventType,
            MakeActivatorFactory(BEntry.BehaviorClass));
      end;

      Result := Registry;
    end
  );

  if FCreateScope then
    FServices.AddSingleton(
      TServiceType.FromInterface(TypeInfo(IEventBus)),
      TEventBus,
      function(AProvider: IServiceProvider): TObject
      var
        Registry: IEventHandlerRegistry;
      begin
        Registry :=
          TServiceProviderExtensions.GetRequiredService<IEventHandlerRegistry>(AProvider);
        Result := TEventBus.Create(AProvider, Registry, True);
      end
    )
  else
    FServices.AddScoped(
      TServiceType.FromInterface(TypeInfo(IEventBus)),
      TEventBus,
      function(AProvider: IServiceProvider): TObject
      var
        Registry: IEventHandlerRegistry;
      begin
        Registry :=
          TServiceProviderExtensions.GetRequiredService<IEventHandlerRegistry>(AProvider);
        Result := TEventBus.Create(AProvider, Registry, False);
      end
    );
end;

end.
