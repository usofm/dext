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
// Dext.Web.Injection.pas
unit Dext.Web.Injection;

interface

uses
  System.Rtti, System.SysUtils, System.TypInfo,
  Dext.Web.Interfaces, Dext.DI.Interfaces, Dext.Core.Activator, Dext.Core.Reflection;

type
  /// <summary>
  ///   Provides specialized injection for Minimal API handlers.
  ///   Automatically resolves IHttpContext and additional services from the DI container.
  /// </summary>
  THandlerInjector = class
  public
    /// <summary>Analyzes the handler signature and executes it injecting required dependencies.</summary>
    class procedure ExecuteHandler(AHandler: TValue; AContext: IHttpContext; AServiceProvider: IServiceProvider);
  end;

implementation

class procedure THandlerInjector.ExecuteHandler(AHandler: TValue;
  AContext: IHttpContext; AServiceProvider: IServiceProvider);
var
  Method: TRttiMethod;
  Parameters: TArray<TRttiParameter>;
  Arguments: TArray<TValue>;
  I: Integer;
  ParamType: TRttiType;
  Guid: TGUID;
  Service: IInterface;
begin
  // Get the anonymous method's 'Invoke' method via RTTI from communal context
  Method := TReflection.Context.GetType(AHandler.TypeInfo).GetMethod('Invoke');

  Parameters := Method.GetParameters;
  SetLength(Arguments, Length(Parameters));

  // The first parameter is always IHttpContext
  Arguments[0] := TValue.From<IHttpContext>(AContext);

  // Resolve additional parameters from the DI container
  for I := 1 to High(Parameters) do
  begin
    ParamType := Parameters[I].ParamType;
    if ParamType.TypeKind = tkInterface then
    begin
      Guid := GetTypeData(ParamType.Handle)^.Guid;
      Service := AServiceProvider.GetServiceAsInterface(
        TServiceType.FromInterface(Guid));
      Arguments[I] := TValue.From(Service);
    end;
  end;

  // Execute the handler
  Method.Invoke(AHandler, Arguments);
end;

end.

