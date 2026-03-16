unit Bench.HttpRequest;

interface

type
  TBenchHttpRequest = class
  public
    class procedure Run;
  end;

implementation

uses
  System.SysUtils,
  System.Diagnostics,
  System.Classes,
  Dext.Collections.Dict,
  Bench.Utils;

type
  // Old behavior (Pre Phase 4): instantiates dictionaries unconditionally
  TOldHttpRequest = class
  private
    FHeaders: TDictionary<string, string>;
    FCookies: TDictionary<string, string>;
    FItems: TDictionary<string, TObject>;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  // New behavior (Phase 4): interface driven lazy-load
  TNewHttpRequest = class
  private
    FHeaders: IStringDictionary;
    FCookies: IStringDictionary;
  public
    constructor Create;
    destructor Destroy; override;
    
    function GetHeaders: IStringDictionary;
  end;

{ TOldHttpRequest }

constructor TOldHttpRequest.Create;
begin
  inherited;
  FHeaders := TDictionary<string, string>.Create;
  FCookies := TDictionary<string, string>.Create;
  FItems := TDictionary<string, TObject>.Create;
end;

destructor TOldHttpRequest.Destroy;
begin
  FHeaders.Free;
  FCookies.Free;
  FItems.Free;
  inherited;
end;

{ TNewHttpRequest }

constructor TNewHttpRequest.Create;
begin
  inherited;
  // Dictionaries are nil by default
end;

destructor TNewHttpRequest.Destroy;
begin
  FHeaders := nil;
  FCookies := nil;
  inherited;
end;

function TNewHttpRequest.GetHeaders: IStringDictionary;
begin
  if FHeaders = nil then
    FHeaders := TDextStringDictionary.Create as IStringDictionary;
  Result := FHeaders;
end;

{ TBenchHttpRequest }

class procedure TBenchHttpRequest.Run;
const
  ITERATIONS = 50000;
var
  SW: TStopwatch;
  I: Integer;
  AllocCountStart: Int64;
  AllocDelta: Int64;
  OldReq: TOldHttpRequest;
  NewReq: TNewHttpRequest;
begin
  Writeln('--- HTTP Request Pipeline Benchmark ---');
  Writeln('Iterations: ', ITERATIONS);

  // 1. Default request pre-instantiation (Old Pipeline)
  SW := TStopwatch.StartNew;
  AllocCountStart := GetAllocatedBytes;
  
  for I := 1 to ITERATIONS do
  begin
    OldReq := TOldHttpRequest.Create;
    OldReq.Free;
  end;
  SW.Stop;
  
  AllocDelta := GetAllocatedBytes - AllocCountStart;

  Writeln('1. Request Instance (Pre-Instantiating Dicts - Old)');
  Writeln(Format('   Time: %.2f ms', [SW.Elapsed.TotalMilliseconds]));
  Writeln(Format('   Allocations (approx bytes): %d', [AllocDelta])); 
  Writeln('--------------------------------');

  // 2. Default request lazy-loading (New Zero-Alloc Pipeline)
  SW := TStopwatch.StartNew;
  AllocCountStart := GetAllocatedBytes;
  
  for I := 1 to ITERATIONS do
  begin
    NewReq := TNewHttpRequest.Create;
    // GetHeaders not explicitly called by the route
    NewReq.Free;
  end;
  SW.Stop;
  
  AllocDelta := GetAllocatedBytes - AllocCountStart;

  Writeln('2. Request Instance (Lazy Loading / Zero-Alloc - New)');
  Writeln(Format('   Time: %.2f ms', [SW.Elapsed.TotalMilliseconds]));
  Writeln(Format('   Allocations (approx bytes): %d', [AllocDelta])); 
  Writeln('--------------------------------');
end;

end.
