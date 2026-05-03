{***************************************************************************}
{                                                                           }
{           Dext Framework                                                  }
{                                                                           }
{           Copyright (C) 2025 Cesar Romero & Dext Contributors             }
{                                                                           }
{           Licensed under the Apache License, Version 2.0 (the "License"); }
{           you may not use this file except in compliance with the License.}
{           You may obtain a copy of the License at                         }
{                                                                           }
{               http://www.apache.org/licenses/LICENSE-2.0                  }
{                                                                           }
{           Unless required by applicable law or agreed to in writing,      }
{           software distributed under the License is distributed on an     }
{           "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,    }
{           either express or implied. See the License for the specific     }
{           language governing permissions and limitations under the        }
{           License.                                                        }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Author:  Cesar Romero                                                    }
{  Created: 2025-12-08                                                      }
{                                                                           }
{***************************************************************************}
unit Dext.Hosting.BackgroundService;

interface

uses
  System.SysUtils,
  System.Classes,
  Dext.Collections,
  Dext.DI.Interfaces,
  Dext.Logging,
  Dext.Threading.CancellationToken;

type
  /// <summary>Defines the contract for services managed by the application host.</summary>
  IHostedService = interface
    ['{8D4F5E6A-1B2C-4D3E-9F0A-7B8C9D0E1F2A}']
    /// <summary>Starts service execution.</summary>
    procedure Start;
    /// <summary>Requests graceful service shutdown.</summary>
    procedure Stop;
  end;

  // ✅ Interface for THostedServiceManager to enable ARC management
  /// <summary>Orchestrator responsible for managing startup and shutdown of all hosted services.</summary>
  IHostedServiceManager = interface
    ['{F1E2D3C4-B5A6-7890-1234-567890ABCDEF}']
    /// <summary>Registers a new service to be managed.</summary>
    procedure RegisterService(Service: IHostedService);
    /// <summary>Starts all registered services asynchronously.</summary>
    procedure StartAsync(Token: ICancellationToken = nil);
    /// <summary>Stops all registered services, respecting graceful shutdown.</summary>
    procedure StopAsync(Token: ICancellationToken = nil);
  end;

  TBackgroundService = class;

  /// <summary>
  ///   Thread execution wrapper for background services.
  /// </summary>
  TBackgroundServiceThread = class(TThread)
  private
    FService: TBackgroundService;
    FToken: ICancellationToken;
    FLogger: ILogger;
  protected
    procedure Execute; override;
  public
    constructor Create(Service: TBackgroundService; Token: ICancellationToken; Logger: ILogger = nil);
  end;

  /// <summary>
  ///   Base class for implementing long-running services (Workers).
  ///   Automatically manages thread creation and cancellation signal (CancellationToken).
  /// </summary>
  TBackgroundService = class(TInterfacedObject, IHostedService)
  private
    FThread: TBackgroundServiceThread;
    FCancellationTokenSource: TCancellationTokenSource;
  protected
    /// <summary>
    ///   Abstract method where worker logic should be implemented. 
    ///   Must monitor <paramref name="Token"/> to terminate execution loop.
    /// </summary>
    procedure Execute(Token: ICancellationToken); virtual; abstract;
  public
    FLogger: ILogger; // Used by thread if assigned
    /// <summary>Starts the background thread and cancellation management.</summary>
    procedure Start; virtual;
    /// <summary>Triggers the cancellation signal and waits for the thread to terminate (Graceful Shutdown).</summary>
    procedure Stop; virtual;
  end;

  /// <summary>
  ///   Manager that starts and stops all registered hosted services.
  /// </summary>
  THostedServiceManager = class(TInterfacedObject, IHostedServiceManager)
  private
    FServices: IList<IHostedService>;
    FLogger: ILogger;
  protected
    procedure LogInfo(const AMsg: string);
    procedure LogError(const AMsg: string);
  public
    constructor Create(ALogger: ILogger = nil);
    destructor Destroy; override;

    procedure RegisterService(Service: IHostedService);
    procedure StartAsync(Token: ICancellationToken = nil);
    procedure StopAsync(Token: ICancellationToken = nil);
  end;

  /// <summary>Builder used to register Background Services in the Dependency Injection container.</summary>
  TBackgroundServiceBuilder = record
    FServices: IServiceCollection;
    FHostedServices: IList<TClass>;
    FLoggerClass: TClass;
  public
    constructor Create(Services: IServiceCollection);
    function AddHostedService<T: class, constructor>: TBackgroundServiceBuilder; overload;
    function AddHostedService(AServiceClass: TClass): TBackgroundServiceBuilder; overload;
    /// <summary>Consolidates registrations and injects the Service Manager into the DI container.</summary>
    procedure Build;
  end;

  /// <summary>
  ///   Core extension methods for IServiceCollection.
  /// </summary>
  TDextServiceCollectionExtensions = class
  public
    /// <summary>
    ///   Adds background service infrastructure to the DI container.
    ///   Returns a builder for registering hosted services.
    /// </summary>
    class function AddBackgroundServices(Services: IServiceCollection): TBackgroundServiceBuilder;
  end;

  /// <summary>
  ///   Fluent extensions for TDextServices core features.
  /// </summary>
  TDextServiceExtensions = record helper for TDextServices
  public
    /// <summary>
    ///   Starts the Background Service builder chain.
    /// </summary>
    function AddBackgroundServices: TBackgroundServiceBuilder;
  end;

implementation

uses
  Dext.Utils;

{ TBackgroundServiceThread }

constructor TBackgroundServiceThread.Create(Service: TBackgroundService; Token: ICancellationToken; Logger: ILogger);
begin
  inherited Create(True); // Create suspended
  FService := Service;
  FToken := Token;
  FLogger := Logger;
  FreeOnTerminate := False;
end;

procedure TBackgroundServiceThread.Execute;
begin
  try
    FService.Execute(FToken);
  except
    on E: Exception do
    begin
      if FLogger <> nil then
        FLogger.LogError('BackgroundService thread error: {0}', [E.Message])
      else
        SafeWriteLn(Format('❌ Error in BackgroundService thread: %s', [E.Message]));
    end;
  end;
end;

{ TBackgroundService }

procedure TBackgroundService.Start;
begin
  FCancellationTokenSource := TCancellationTokenSource.Create;
  FThread := TBackgroundServiceThread.Create(Self, FCancellationTokenSource.Token, FLogger);
  FThread.Start;
end;

procedure TBackgroundService.Stop;
begin
  if Assigned(FCancellationTokenSource) then
  begin
    FCancellationTokenSource.Cancel;
  end;

  if Assigned(FThread) then
  begin
    // We don't terminate the thread abruptly, we wait for it to finish gracefully
    // The Execute method should check the token and exit.
    FThread.WaitFor;
    FThread.Free;
    FThread := nil;
  end;
  
  if Assigned(FCancellationTokenSource) then
  begin
    FCancellationTokenSource.Free;
    FCancellationTokenSource := nil;
  end;
end;

{ THostedServiceManager }

constructor THostedServiceManager.Create(ALogger: ILogger);
begin
  inherited Create;
  FServices := TCollections.CreateList<IHostedService>;
  FLogger := ALogger;
end;

procedure THostedServiceManager.LogInfo(const AMsg: string);
begin
  if FLogger <> nil then
    FLogger.LogInformation(AMsg)
  else
    SafeWriteLn(AMsg);
end;

procedure THostedServiceManager.LogError(const AMsg: string);
begin
  if FLogger <> nil then
    FLogger.LogError(AMsg)
  else
    SafeWriteLn('❌ ' + AMsg);
end;

destructor THostedServiceManager.Destroy;
begin
  FServices := nil;
  inherited;
end;

procedure THostedServiceManager.RegisterService(Service: IHostedService);
begin
  FServices.Add(Service);
end;

procedure THostedServiceManager.StartAsync(Token: ICancellationToken);
var
  Service: IHostedService;
  LObj: TObject;
begin
  for Service in FServices do
  begin
    if not Assigned(Service) then Continue;

    try
      LObj := Service as TObject;
      // If the service is TBackgroundService, we can inject our logger into it
      if (LObj <> nil) and (LObj is TBackgroundService) then
        TBackgroundService(LObj).FLogger := FLogger;
         
      Service.Start;
    except
      on E: Exception do
        LogError(Format('Failed to start service: %s', [E.Message]));
    end;
  end;
end;

procedure THostedServiceManager.StopAsync(Token: ICancellationToken);
var
  Service: IHostedService;
  I: Integer;
begin
  // Stop services in reverse order
  for I := FServices.Count - 1 downto 0 do
  begin
    Service := FServices[I];
    if not Assigned(Service) then Continue;

    try
      Service.Stop;
    except
      on E: Exception do
        LogError(Format('Failed to stop service: %s', [E.Message]));
    end;
  end;
end;

{ TBackgroundServiceBuilder }

constructor TBackgroundServiceBuilder.Create(Services: IServiceCollection);
begin
  FServices := Services;
  FHostedServices := TCollections.CreateList<TClass>;
  FLoggerClass := nil;
end;

function TBackgroundServiceBuilder.AddHostedService<T>: TBackgroundServiceBuilder;
begin
  // Register as singleton
  FServices.AddSingleton(TServiceType.FromClass(T), T);
  
  if not FHostedServices.Contains(T) then
    FHostedServices.Add(T);
    
  Result := Self;
end;

function TBackgroundServiceBuilder.AddHostedService(AServiceClass: TClass): TBackgroundServiceBuilder;
begin
  if not FHostedServices.Contains(AServiceClass) then
    FHostedServices.Add(AServiceClass);
  Result := Self;
end;

procedure TBackgroundServiceBuilder.Build;
var
  LServices: IServiceCollection;
  LHostedClasses: TArray<TClass>;
  LLoggerClass: TClass;
begin
  LServices := FServices;
  LHostedClasses := FHostedServices.ToArray;
  LLoggerClass := FLoggerClass;

  LServices.AddSingleton(
    TServiceType.FromInterface(TypeInfo(IHostedServiceManager)),
    THostedServiceManager,
    function(Provider: IServiceProvider): TObject
    var
      Manager: THostedServiceManager;
      SvcClass: TClass;
      ServiceObj: TObject;
      HostedService: IHostedService;
      Logger: ILogger;
      Intf: IInterface;
    begin
       // 1. Resolve Logger
       Logger := nil;
       if Assigned(LLoggerClass) then
       begin
         ServiceObj := Provider.GetService(TServiceType.FromClass(LLoggerClass));
         if Assigned(ServiceObj) then
           Supports(ServiceObj, ILogger, Logger);
       end
       else
       begin
         Intf := Provider.GetServiceAsInterface(TypeInfo(ILogger));
         if Assigned(Intf) then
           Supports(Intf, ILogger, Logger);
       end;

       // 2. Create Manager
       Manager := THostedServiceManager.Create(Logger);
       
       // 3. Resolve and Register Services from our CAPTURED array
       for SvcClass in LHostedClasses do
       begin
         ServiceObj := Provider.GetService(TServiceType.FromClass(SvcClass));
         if Assigned(ServiceObj) and Supports(ServiceObj, IHostedService, HostedService) then
           Manager.RegisterService(HostedService);
       end;
       
       Result := Manager;
    end
  );
end;

{ TDextServiceExtensions }

function TDextServiceExtensions.AddBackgroundServices: TBackgroundServiceBuilder;
begin
  Result := TDextServiceCollectionExtensions.AddBackgroundServices(Self.Collection);
end;

{ TDextServiceCollectionExtensions }

class function TDextServiceCollectionExtensions.AddBackgroundServices(
  Services: IServiceCollection): TBackgroundServiceBuilder;
begin
  Result := TBackgroundServiceBuilder.Create(Services);
end;

end.

