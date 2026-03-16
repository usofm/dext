unit Bench.Middleware;

interface

type
  TBenchMiddleware = class
  public
    class procedure Run;
  end;

implementation

uses
  System.SysUtils,
  System.Diagnostics,
  System.Classes,
  System.Rtti,
  Dext.DI.Interfaces,
  Dext.Auth.Identity,
  Dext.Web.Interfaces,
  Dext.Web.Pipeline,
  Dext.Web.Routing,
  Dext.Collections,
  Dext.Collections.Dict,
  Bench.Utils;

{ TMockHttpContext and others }

type
  TMockHttpRequest = class(TInterfacedObject, IHttpRequest)
  private
    FMethod: string;
    FPath: string;
    FQuery: IStringDictionary;
    FHeaders: IStringDictionary;
  public
    constructor Create(const AMethod, APath: string);
    destructor Destroy; override;

    function GetMethod: string;
    function GetPath: string;
    function GetQuery: IStringDictionary;
    function GetBody: TStream;
    function GetRouteParams: TRouteValueDictionary;
    function GetHeaders: IStringDictionary;
    function GetRemoteIpAddress: string;

    function GetHeader(const AName: string): string;
    function GetQueryParam(const AName: string): string;
    function GetProtocol: string;
    function GetCookies: IStringDictionary;
    function GetFiles: IFormFileCollection;
  end;

  TMockHttpContext = class(TInterfacedObject, IHttpContext)
  private
    FRequest: IHttpRequest;
  public
    constructor Create(const AMethod, APath: string);
    function GetRequest: IHttpRequest;
    function GetResponse: IHttpResponse;
    function GetItems: IDictionary<string, TValue>;
    function GetUser: IClaimsPrincipal;
    procedure SetUser(const AValue: IClaimsPrincipal);
    procedure SetResponse(const AValue: IHttpResponse);
    procedure SetServices(const AValue: IServiceProvider);
    function GetServices: IServiceProvider;
  end;

{ TMockHttpRequest }

constructor TMockHttpRequest.Create(const AMethod, APath: string);
begin
  inherited Create;
  FMethod := AMethod;
  FPath := APath;
  FQuery := TDextStringDictionary.Create;
  FHeaders := TDextStringDictionary.Create;
end;

destructor TMockHttpRequest.Destroy;
begin
  FQuery := nil;
  inherited;
end;

function TMockHttpRequest.GetBody: TStream; begin Result := nil; end;
function TMockHttpRequest.GetHeader(const AName: string): string; begin Result := ''; end;
function TMockHttpRequest.GetHeaders: IStringDictionary; begin Result := FHeaders; end;
function TMockHttpRequest.GetMethod: string; begin Result := FMethod; end;
function TMockHttpRequest.GetPath: string; begin Result := FPath; end;
function TMockHttpRequest.GetProtocol: string; begin Result := 'HTTP/1.1'; end;
function TMockHttpRequest.GetQuery: IStringDictionary; begin Result := FQuery; end;
function TMockHttpRequest.GetQueryParam(const AName: string): string; begin Result := ''; end;
function TMockHttpRequest.GetRemoteIpAddress: string; begin Result := '127.0.0.1'; end;
function TMockHttpRequest.GetRouteParams: TRouteValueDictionary; begin Result.Clear; end;
function TMockHttpRequest.GetCookies: IStringDictionary; begin Result := nil; end;
function TMockHttpRequest.GetFiles: IFormFileCollection; begin Result := nil; end;

{ TMockHttpContext }

constructor TMockHttpContext.Create(const AMethod, APath: string);
begin
  FRequest := TMockHttpRequest.Create(AMethod, APath);
end;

function TMockHttpContext.GetItems: IDictionary<string, TValue>; begin Result := nil; end;
function TMockHttpContext.GetRequest: IHttpRequest; begin Result := FRequest; end;
function TMockHttpContext.GetResponse: IHttpResponse; begin Result := nil; end;
procedure TMockHttpContext.SetResponse(const AValue: IHttpResponse); begin end;
function TMockHttpContext.GetServices: IServiceProvider; begin Result := nil; end;
procedure TMockHttpContext.SetServices(const AValue: IServiceProvider); begin end;
function TMockHttpContext.GetUser: IClaimsPrincipal; begin Result := nil; end;
procedure TMockHttpContext.SetUser(const AValue: IClaimsPrincipal); begin end;

{ TBenchMiddleware }

class procedure TBenchMiddleware.Run;
const
  ITERATIONS = 10000;
var
  SW: TStopwatch;
  I: Integer;
  AllocCountStart: Int64;
  AllocDelta: Int64;
  Context: IHttpContext;
  Pipeline: IDextPipeline;
  FixedRoutes: IDictionary<string, TRequestDelegate>;
  PatternRoutes: IDictionary<TRoutePattern, TRequestDelegate>;
  PipelineDelegate: TRequestDelegate;
begin
  Writeln('--- Middleware Pipeline Benchmark ---');
  Writeln('Iterations: ', ITERATIONS);

  FixedRoutes := TCollections.CreateDictionary<string, TRequestDelegate>;
  PatternRoutes := TCollections.CreateDictionary<TRoutePattern, TRequestDelegate>;
  PipelineDelegate := procedure(ctx: IHttpContext)
  begin
    // End of pipeline
  end;
  
  Pipeline := TDextPipeline.Create(FixedRoutes, PatternRoutes, PipelineDelegate);
  Context := TMockHttpContext.Create('GET', '/api/users');

  SW := TStopwatch.StartNew;
  AllocCountStart := GetAllocatedBytes;
  
  for I := 1 to ITERATIONS do
  begin
    Pipeline.Execute(Context);
  end;
  SW.Stop;

  AllocDelta := GetAllocatedBytes - AllocCountStart;

  Writeln('1. Pipeline Execution');
  Writeln(Format('   Time: %.2f ms', [SW.Elapsed.TotalMilliseconds]));
  Writeln(Format('   Allocations (approx bytes): %d', [AllocDelta])); 
  Writeln('--------------------------------');
end;

end.
