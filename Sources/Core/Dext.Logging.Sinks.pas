{***************************************************************************}
{           Dext Framework                                                  }
{           Copyright (C) 2025 Cesar Romero & Dext Contributors             }
{***************************************************************************}
unit Dext.Logging.Sinks;

interface

uses
  System.SysUtils,
  System.Classes,
  System.TypInfo,
  System.IOUtils,
  System.SyncObjs,
  Dext.Types.UUID,
  Dext.Logging,
  Dext.Logging.Async,
  Dext.Logging.RingBuffer;

type
  /// <summary>
  ///   Sink that writes to Standard Output (Console).
  /// </summary>
  TConsoleSink = class(TInterfacedObject, ILogSink)
  public
    procedure Emit(const Entry: TLogEntry);
    procedure Flush;
  end;

  TFileSink = class(TInterfacedObject, ILogSink)
  private
    FFileName: string;
    FBuffer: TStringBuilder;
    FLock: TObject;
    procedure FlushInternal;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    procedure Emit(const Entry: TLogEntry);
    procedure Flush;
  end;

  /// <summary>
  ///   Logger that writes to a file using TFileSink.
  /// </summary>
  TFileLogger = class(TAbstractLogger)
  private
    FCategoryName: string;
    FSink: ILogSink;
  protected
    procedure Log(ALevel: TLogLevel; const AMessage: string; const AArgs: array of const); override;
    procedure Log(ALevel: TLogLevel; const AException: Exception; const AMessage: string; const AArgs: array of const); override;
    function IsEnabled(ALevel: TLogLevel): Boolean; override;
    function BeginScope(const AMessage: string; const AArgs: array of const): IDisposable; override;
    function BeginScope(const AState: TObject): IDisposable; override;
  public
    constructor Create(const ACategoryName: string; const ASink: ILogSink);
  end;

  /// <summary>
  ///   Provider for file logging.
  /// </summary>
  TFileLoggerProvider = class(TInterfacedObject, ILoggerProvider)
  private
    FSink: ILogSink;
  public
    constructor Create(const AFileName: string);
    function CreateLogger(const ACategoryName: string): ILogger;
    procedure Dispose;
  end;

implementation

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.StrUtils,
  Dext.Utils;

{ TConsoleSink }

procedure TConsoleSink.Emit(const Entry: TLogEntry);
var
  Lvl: string;

begin
  // Simple color coding (ANSI)
  case Entry.Level of
    TLogLevel.Trace: Lvl := 'TRC';
    TLogLevel.Debug: Lvl := 'DBG';
    TLogLevel.Information: Lvl := 'INF';
    TLogLevel.Warning: Lvl := 'WRN';
    TLogLevel.Error: Lvl := 'ERR';
    TLogLevel.Critical: Lvl := 'CRT';
    else Lvl := 'UNK';
  end;
  
  // Format: [HH:MM:SS INF] Message
  // Format with TraceId: [HH:MM:SS INF] [TraceId] Message
  
  if not Entry.TraceId.IsEmpty then
    SafeWriteLn(Format('[%s %s] [%s] %s', [FormatDateTime('HH:nn:ss.zzz', Entry.TimeStamp), Lvl, Entry.TraceId.ToString, Entry.FormattedMessage]))
  else
    SafeWriteLn(Format('[%s %s] %s', [FormatDateTime('HH:nn:ss.zzz', Entry.TimeStamp), Lvl, Entry.FormattedMessage]));
end;

procedure TConsoleSink.Flush;
begin
  // Flush stdout?
end;

{ TFileSink }

constructor TFileSink.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  FBuffer := TStringBuilder.Create;
  FLock := TObject.Create;
  
  // Ensure dir exists
  TDirectory.CreateDirectory(TPath.GetDirectoryName(FFileName));
end;

destructor TFileSink.Destroy;
begin
  FlushInternal;
  FBuffer.Free;
  FLock.Free;
  inherited;
end;

procedure TFileSink.Emit(const Entry: TLogEntry);
begin
  TMonitor.Enter(FLock);
  try
    // Switching to JSON Lines for better machine readability
    // {"ts":"...", "lvl":"INF", "traceId":"...", "msg":"..."}
    FBuffer.Append('{');
    FBuffer.Append('"ts":"').Append(FormatDateTime('yyyy-mm-dd HH:nn:ss.zzz', Entry.TimeStamp)).Append('",');
    FBuffer.Append('"lvl":"').Append(GetEnumName(TypeInfo(TLogLevel), Integer(Entry.Level))).Append('",');
    
    if not Entry.TraceId.IsEmpty then
      FBuffer.Append('"traceId":"').Append(Entry.TraceId.ToString).Append('",');
      
    if not Entry.SpanId.IsEmpty then
      FBuffer.Append('"spanId":"').Append(Entry.SpanId.ToString).Append('",');
      
    FBuffer.Append('"msg":"').Append(Entry.FormattedMessage.Replace('"', '\"').Replace(#13, '\r').Replace(#10, '\n')).Append('"');
    FBuffer.Append('}').AppendLine;
           
    if FBuffer.Length > 4096 then
      FlushInternal;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TFileSink.Flush;
begin
  TMonitor.Enter(FLock);
  try
    FlushInternal;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TFileSink.FlushInternal;
begin
  if FBuffer.Length = 0 then Exit;
  
  try
    TFile.AppendAllText(FFileName, FBuffer.ToString, TEncoding.UTF8);
    FBuffer.Clear;
  except
    // ignore file errors
  end;
end;

{ TFileLogger }

constructor TFileLogger.Create(const ACategoryName: string; const ASink: ILogSink);
begin
  inherited Create;
  FCategoryName := ACategoryName;
  FSink := ASink;
end;

function TFileLogger.IsEnabled(ALevel: TLogLevel): Boolean;
begin
  Result := ALevel <> TLogLevel.None;
end;

procedure TFileLogger.Log(ALevel: TLogLevel; const AMessage: string; const AArgs: array of const);
var
  LEntry: TLogEntry;
begin
  if not IsEnabled(ALevel) then Exit;

  LEntry := Default(TLogEntry);
  LEntry.TimeStamp := Now;
  LEntry.Level := ALevel;
  LEntry.FormattedMessage := TLogFormatter.FormatMessage(AMessage, AArgs);
  
  FSink.Emit(LEntry);
end;

procedure TFileLogger.Log(ALevel: TLogLevel; const AException: Exception; const AMessage: string; const AArgs: array of const);
begin
  if not IsEnabled(ALevel) then Exit;
  if AException <> nil then
    Log(ALevel, AMessage + ' [Ex: ' + AException.Message + ']', AArgs)
  else
    Log(ALevel, AMessage, AArgs);
end;

function TFileLogger.BeginScope(const AMessage: string; const AArgs: array of const): IDisposable;
begin
  Result := TNullDisposable.Create;
end;

function TFileLogger.BeginScope(const AState: TObject): IDisposable;
begin
  Result := TNullDisposable.Create;
end;

{ TFileLoggerProvider }

constructor TFileLoggerProvider.Create(const AFileName: string);
begin
  inherited Create;
  FSink := TFileSink.Create(AFileName);
end;

function TFileLoggerProvider.CreateLogger(const ACategoryName: string): ILogger;
begin
  Result := TFileLogger.Create(ACategoryName, FSink);
end;

procedure TFileLoggerProvider.Dispose;
begin
  if FSink <> nil then
    FSink.Flush;
  FSink := nil;
end;

end.
