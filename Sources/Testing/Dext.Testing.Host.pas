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
{  Created: 2026-04-07                                                      }
{                                                                           }
{  Dext.Testing.Host - Application Host for Test Execution (GUI/Console)    }
{***************************************************************************}
{$I Dext.inc}

unit Dext.Testing.Host;

interface

uses
  System.Classes,
  System.SyncObjs,
  System.SysUtils,
  Dext.Testing.Fluent,
  Dext.Testing.Runner;

type
  /// <summary>Manages the lifecycle and execution environment during tests (Console, IDE, or CI).</summary>
  TTestHost = class
  public
    /// <summary>Executes the test suite with a specific configuration.</summary>
    class procedure Execute(const Config: TTestConfigurator); overload;
    /// <summary>Executes the tests using the detected default settings.</summary>
    class procedure Execute; overload;
  end;

procedure RunTests(const Config: TTestConfigurator); overload;
procedure RunTests; overload;

implementation

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.IOUtils,
  Dext.Utils,
  {$IFDEF DEXT_TESTINSIGHT}
  TestInsight.Client,
  Dext.Testing.TestInsight,
  {$ENDIF}
  Dext.Core.Writers;

procedure RunTests(const Config: TTestConfigurator);
begin
  TTestHost.Execute(Config);
end;

procedure RunTests; overload;
begin
  TTestHost.Execute;
end;

{ TTestHost }

class procedure TTestHost.Execute;
begin
  Execute(TTest.Configure);
end;

class procedure TTestHost.Execute(const Config: TTestConfigurator);
var
  IsUI: Boolean;
  Index: Integer;
  LogFile: string;
  LogStrings: TStringList;
  IsLogEnabled: Boolean;
  ParentProcess: string;
  P: string;
  {$IFDEF DEXT_TESTINSIGHT}
  Listener: ITestListener;
  Selected: TArray<string>;
  StartTime: DWORD;
  ListenerObj: TTestInsightListener;
  InsightOptions: TTestInsightOptions;
  {$ENDIF}
begin
  ParentProcess := GetParentProcessName;
  
  // 1. Detect parameters first
  IsLogEnabled := False;
  LogFile := '';
  IsUI := False;
  
  for Index := 1 to ParamCount do
  begin
    P := ParamStr(Index);
    // Detect Log
    if (CompareText(P, '/log') = 0) or (CompareText(P, '-log') = 0) then
    begin
      IsLogEnabled := True;
      LogFile := ChangeFileExt(ParamStr(0), '.log');
    end;
    // Detect TestInsight
    if (CompareText(P, '/X') = 0) or (CompareText(P, '-X') = 0) or 
       (CompareText(P, '/TestInsight') = 0) then
    begin
      TTestRunner.SetTestInsightActive(True);
      IsUI := True;
    end;
  end;

  // 2. Decide if we need UI or Console and Setup Environment
  {$IFDEF MSWINDOWS}
  // Auto-detect UI if configured and running inside IDE
  if (not IsUI) and Config.IsTestInsightActive and (ParentProcess = 'bds.exe') then
  begin
    IsUI := True;
    TTestRunner.SetTestInsightActive(True);
  end;

  if not IsUI then
    SafeAttachConsole;
  {$ENDIF}

  // 3. Setup Logging if requested
  LogStrings := TStringList.Create;
  try
    if IsLogEnabled then
    begin
      InitializeDextWriter(TStringsWriter.Create(LogStrings));
      SafeWriteLn('--- DEXT TEST HOST LOG STARTED: ' + DateTimeToStr(Now) + ' ---');
      SafeWriteLn('CmdLine: ' + GetCommandLine);
    end;
    
    {$IFDEF MSWINDOWS}
    {$IFDEF DEXT_TESTINSIGHT}
    if IsUI then
    begin
      ListenerObj := TTestInsightListener.Create;
      Listener := ListenerObj; 
      TTestRunner.RegisterListener(Listener);
      
      if not ListenerObj.Enabled then
      begin
        SafeAttachConsole;
        SafeWriteLn('Dext Test Host - Console Fallback Mode');
        Config.Run;
      end
      else
      begin
        InsightOptions := ListenerObj.GetOptions;
        if not InsightOptions.ExecuteTests then
        begin
          TTestRunner.SetDiscoveryMode(True);
          Config.Run;
        end
        else
        begin
          Selected := ListenerObj.GetSelectedTests;
          if (Length(Selected) > 0) then
          begin
            TTestRunner.SetSelectedTests(Selected);
            Config.Run;
          end
          else if TTestRunner.IsTestInsightActive then
            TTestRunner.RunAll
          else
            Config.Run;
        end;

        // Wait for completion
        StartTime := GetTickCount;
        while (ListenerObj.WaitForCompletion(100) = wrTimeout) and (GetTickCount - StartTime < 30000) do
          Sleep(10); 
      end;
    end
    else
    {$ELSE}
    if IsUI then
    begin
       SafeWriteLn('Warning: TestInsight support is disabled in this build.');
       SafeAttachConsole;
       Config.Run;
    end
    else
    {$ENDIF}
    {$ENDIF}
    begin
      SafeWriteLn('Dext Test Host - Console Mode');
      Config.Run;
    end;
    
    // Set exit code based on failure
    if TTestRunner.Summary.Failed > 0 then
      ExitCode := 1
    else
      ExitCode := 0;

    if IsLogEnabled and (LogFile <> '') then
    begin
      SafeWriteLn('--- DEXT TEST HOST LOG FINISHED (Summary: Fixtures=' + 
        TTestRunner.FixtureCount.ToString + ', Tests=' + TTestRunner.TestCount.ToString + ') ---');
      try
        LogStrings.SaveToFile(LogFile, TEncoding.UTF8);
      except
      end;
    end;
  finally
    // Pause if not CI/No-Wait
    if IsConsoleAvailable and not FindCmdLineSwitch('no-wait', ['-', '\'], True) then
      ConsolePause;
    
    // Crucial: Set writer to Nil before freeing the memory it points to!
    InitializeDextWriter(Nil);
    LogStrings.Free;
  end;
end;

end.
