// Dext.Web.Mocks.pas
unit Dext.Web.Mocks;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  Dext.Collections,
  Dext.Collections.Dict,
  Dext.DI.Interfaces,
  Dext.Web.Indy,
  Dext.Web.Interfaces,
  Dext.Auth.Identity,
  Dext.Json;

type
  TMockHttpRequest = class(TInterfacedObject, IHttpRequest)
  private
    FMethod: string;
    FPath: string;
    FQueryParams: IStringDictionary;
    FBodyStream: TStream;
    FRouteParams: TRouteValueDictionary;
    FHeaders: IStringDictionary;
    FCookies: IStringDictionary;
    FFiles: IFormFileCollection;
    FRemoteIpAddress: string;
  public
    constructor Create(const AQueryString: string; const AMethod: string = 'GET'; const APath: string = '/api/test');
    destructor Destroy; override;

    // IHttpRequest
    function GetMethod: string;
    function GetPath: string;
    function GetQuery: IStringDictionary;
    function GetBody: TStream;
    function GetRouteParams: TRouteValueDictionary;
    function GetHeaders: IStringDictionary; virtual;
    function GetRemoteIpAddress: string;
    function GetHeader(const AName: string): string;
    function GetQueryParam(const AName: string): string;
    function GetCookies: IStringDictionary;
    function GetFiles: IFormFileCollection;

    property RemoteIpAddress: string read FRemoteIpAddress write FRemoteIpAddress;
    property Cookies: IStringDictionary read GetCookies;
    property Files: IFormFileCollection read GetFiles;
  end;

  TMockHttpResponse = class(TInterfacedObject, IHttpResponse)
  private
    FStatusCode: Integer;
    FContentType: string;
    FContentText: string;
    FCustomHeaders: IDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;

    // IHttpResponse
    function GetStatusCode: Integer;
    function GetContentType: string;
    function Status(AValue: Integer): IHttpResponse;
    procedure SetStatusCode(AValue: Integer);
    procedure SetContentType(const AValue: string);
    procedure SetContentLength(const AValue: Int64);
    procedure Write(const AContent: string); overload;
    procedure Write(const ABuffer: TBytes); overload;
    procedure Write(const AStream: TStream); overload;
    procedure Json(const AJson: string); overload;
    procedure Json(const AValue: TValue); overload;
    procedure AddHeader(const AName, AValue: string);
    procedure AppendCookie(const AName, AValue: string; const AOptions: TCookieOptions); overload;
    procedure AppendCookie(const AName, AValue: string); overload;
    procedure DeleteCookie(const AName: string);

    // Propriedades para teste
    property StatusCode: Integer read GetStatusCode write SetStatusCode;
    property ContentText: string read FContentText;
  end;

  TMockHttpContext = class(TInterfacedObject, IHttpContext)
  private
    FRequest: IHttpRequest;
    FResponse: IHttpResponse;
    FServices: IServiceProvider;
    FUser: IClaimsPrincipal;
    FItems: IDictionary<string, TValue>;
  public
    constructor Create(ARequest: IHttpRequest; AResponse: IHttpResponse;
      AServices: IServiceProvider = nil);
    destructor Destroy; override;

    // IHttpContext
    function GetRequest: IHttpRequest;

    function GetResponse: IHttpResponse;
    procedure SetResponse(const AValue: IHttpResponse);

    function GetServices: IServiceProvider; virtual;
    procedure SetServices(const AValue: IServiceProvider);

    function GetUser: IClaimsPrincipal;
    procedure SetUser(const AValue: IClaimsPrincipal);

    function GetItems: IDictionary<string, TValue>;

    procedure SetRouteParams(const AParams: TRouteValueDictionary);
  end;

  TMockHttpRequestWithHeaders = class(TMockHttpRequest)
  private
    FCustomHeaders: IStringDictionary;
  public
    constructor CreateWithHeaders(const AQueryString: string;
      const AHeaders: IStringDictionary);
    destructor Destroy; override;
    function GetHeaders: IStringDictionary; override;
  end;

  TMockHttpContextWithServices = class(TMockHttpContext)
  private
    FCustomServices: IServiceProvider;
  public
    constructor CreateWithServices(ARequest: IHttpRequest;
      AResponse: IHttpResponse; AServices: IServiceProvider);
    function GetServices: IServiceProvider; override;
  end;

  TMockFactory = class
  public
    class function CreateHttpContextWithHeaders(const AQueryString: string; const
      AHeaders: IStringDictionary): IHttpContext;
    class function CreateHttpContextWithServices(const AQueryString: string; const
      AServices: IServiceProvider): IHttpContext;
    class function CreateHttpContext(const AQueryString: string): IHttpContext; static;
    class function CreateHttpContextWithRoute(const AQueryString: string; const
      ARouteParams: TRouteValueDictionary): IHttpContext; static;
  end;

implementation

{ TMockHttpRequest }

constructor TMockHttpRequest.Create(const AQueryString: string; const AMethod: string = 'GET'; const APath: string = '/api/test');
var
  I, PosEqual: Integer;
  ParamList: TStringList;
  Key, Value: string;
begin
  inherited Create;
  FMethod := AMethod;
  FPath := APath;

  FRouteParams.Clear;
  FQueryParams := TCollections.CreateStringDictionary;

  if AQueryString <> '' then
  begin
    // ✅ SEPARAR path de query string
    var QueryPart := AQueryString;
    var PosQuery := Pos('?', AQueryString);
    if PosQuery > 0 then
      QueryPart := Copy(AQueryString, PosQuery + 1, MaxInt);

    ParamList := TStringList.Create;
    try
      ParamList.Delimiter := '&';
      ParamList.StrictDelimiter := True;
      ParamList.DelimitedText := QueryPart; // ✅ Só a parte depois do ?

      for I := 0 to ParamList.Count - 1 do
      begin
        PosEqual := Pos('=', ParamList[I]);
        if PosEqual > 0 then
        begin
          Key := Copy(ParamList[I], 1, PosEqual - 1);
          Value := Copy(ParamList[I], PosEqual + 1, MaxInt);
          FQueryParams.AddOrSetValue(Key, Value);
        end;
      end;
    finally
      ParamList.Free;
    end;
  end;

  // Inicializar outros campos
  FHeaders := TCollections.CreateStringDictionary;
  FCookies := TCollections.CreateStringDictionary;
  FFiles := TFormFileCollection.Create(TCollections.CreateList<IFormFile>);
  FBodyStream := TMemoryStream.Create;
  FRemoteIpAddress := '127.0.0.1'; // Default mock IP

  // ✅ DEBUG: Log do que foi parseado
  Writeln('Mock Request Created:');
  Writeln('  QueryString: ', AQueryString);
  Writeln('  Parsed params: ', FQueryParams.Count);
  for var Pair in FQueryParams.ToArray do
    Writeln('    ', Pair.Key, ' = ', Pair.Value);
end;

destructor TMockHttpRequest.Destroy;
begin
    FCookies := nil;
  FBodyStream.Free;
  inherited Destroy;
end;

function TMockHttpRequest.GetMethod: string;
begin
  Result := FMethod;
end;

function TMockHttpRequest.GetPath: string;
begin
  Result := FPath;
end;

function TMockHttpRequest.GetQuery: IStringDictionary;
begin
  Result := FQueryParams; 
end;

function TMockHttpRequest.GetBody: TStream;
begin
  Result := FBodyStream;
end;

function TMockHttpRequest.GetRouteParams: TRouteValueDictionary;
begin
  Result := FRouteParams;
end;

function TMockHttpRequest.GetHeaders: IStringDictionary;
begin
  Result := FHeaders;
end;

function TMockHttpRequest.GetRemoteIpAddress: string;
begin
  Result := FRemoteIpAddress;
end;

function TMockHttpRequest.GetHeader(const AName: string): string;
begin
  if not FHeaders.TryGetValue(AName, Result) then
    Result := '';
end;

function TMockHttpRequest.GetQueryParam(const AName: string): string;
begin
  if not FQueryParams.TryGetValue(AName, Result) then
    Result := '';
end;

function TMockHttpRequest.GetCookies: IStringDictionary;
begin
  Result := FCookies;
end;

function TMockHttpRequest.GetFiles: IFormFileCollection;
begin
  Result := FFiles;
end;

{ TMockHttpResponse }

constructor TMockHttpResponse.Create;
begin
  inherited Create;
  FStatusCode := 200;
  FContentType := 'text/plain';
  FCustomHeaders := TCollections.CreateDictionary<string, string>;
end;

destructor TMockHttpResponse.Destroy;
begin
  // FCustomHeaders.Free;
  inherited Destroy;
end;

function TMockHttpResponse.GetContentType: string;
begin
  Result := FContentType;
end;

function TMockHttpResponse.GetStatusCode: Integer;
begin
  Result := FStatusCode;
end;

procedure TMockHttpResponse.Json(const AValue: TValue);
begin
  var JsonStr := TDextJson.Serialize(AValue);
  FContentText := JsonStr;
  FContentType := 'application/json';
end;

function TMockHttpResponse.Status(AValue: Integer): IHttpResponse;
begin
  FStatusCode := AValue;
  Result := Self;
end;

procedure TMockHttpResponse.SetStatusCode(AValue: Integer);
begin
  FStatusCode := AValue;
end;

procedure TMockHttpResponse.SetContentType(const AValue: string);
begin
  FContentType := AValue;
end;

procedure TMockHttpResponse.SetContentLength(const AValue: Int64);
begin
  // Mock implementation - ignore
end;

procedure TMockHttpResponse.Write(const AContent: string);
begin
  FContentText := AContent;
end;

procedure TMockHttpResponse.Write(const ABuffer: TBytes);
begin
  FContentText := TEncoding.UTF8.GetString(ABuffer);
end;

procedure TMockHttpResponse.Write(const AStream: TStream);
begin
  // Mock implementation
end;

procedure TMockHttpResponse.Json(const AJson: string);
begin
  FContentText := AJson;
  FContentType := 'application/json';
end;

procedure TMockHttpResponse.AddHeader(const AName, AValue: string);
begin
  FCustomHeaders.AddOrSetValue(AName, AValue);
end;

procedure TMockHttpResponse.AppendCookie(const AName, AValue: string; const AOptions: TCookieOptions);
begin
  // Mock implementation - ignore or store if needed for tests
end;

procedure TMockHttpResponse.AppendCookie(const AName, AValue: string);
begin
  // Mock implementation - ignore
end;

procedure TMockHttpResponse.DeleteCookie(const AName: string);
begin
  // Mock implementation - ignore
end;

{ TMockHttpContext }

constructor TMockHttpContext.Create(ARequest: IHttpRequest; AResponse: IHttpResponse;
  AServices: IServiceProvider);
begin
  inherited Create;
  FRequest := ARequest;
  FResponse := AResponse;
  FServices := AServices;
  FItems := TCollections.CreateDictionary<string, TValue>;
end;

destructor TMockHttpContext.Destroy;
begin
  // FItems.Free;
  inherited;
end;

function TMockHttpContext.GetRequest: IHttpRequest;
begin
  Result := FRequest;
end;

function TMockHttpContext.GetResponse: IHttpResponse;
begin
  Result := FResponse;
end;

procedure TMockHttpContext.SetResponse(const AValue: IHttpResponse);
begin
  FResponse := AValue;
end;

function TMockHttpContext.GetServices: IServiceProvider;
begin
  Result := FServices;
end;

function TMockHttpContext.GetUser: IClaimsPrincipal;
begin
  Result := FUser;
end;

procedure TMockHttpContext.SetUser(const AValue: IClaimsPrincipal);
begin
  FUser := AValue;
end;

procedure TMockHttpContext.SetRouteParams(const AParams: TRouteValueDictionary);
var
  MockRequest: TMockHttpRequest;
begin
  // ✅ CORREÇÃO SIMPLES: Cast direto já que sabemos que é TMockHttpRequest
  try
    MockRequest := TMockHttpRequest(FRequest);
    MockRequest.FRouteParams := AParams;

    Writeln('  ✅ After injection - FRouteParams count: ', MockRequest.FRouteParams.Count);
  except
    on E: Exception do
    begin
      Writeln('❌ ERROR in SetRouteParams: ', E.Message);
    end;
  end;
end;

procedure TMockHttpContext.SetServices(const AValue: IServiceProvider);
begin
  FServices := AValue;
end;

function TMockHttpContext.GetItems: IDictionary<string, TValue>;
begin
  Result := FItems;
end;

//procedure TMockHttpContext.SetRouteParams(const AParams: IDictionary<string, string>);
//var
//  Param: TPair<string, string>;
//begin
//  if FRequest is TMockHttpRequest then
//  begin
//    var MockRequest := TMockHttpRequest(FRequest);
//    MockRequest.FRouteParams.Clear;
//    for Param in AParams do
//      MockRequest.FRouteParams.Add(Param.Key, Param.Value);
//  end;
//end;

//procedure TMockHttpContext.SetRouteParams(const AParams: IDictionary<string, string>);
//var
//  IndyRequest: TIndyHttpRequest;
//  Param: TPair<string, string>;
//begin
//  Writeln('🔍 SetRouteParams Debug:');
//  Writeln('  Input params count: ', AParams.Count);
//  for Param in AParams do
//    Writeln('  ', Param.Key, ' = ', Param.Value);
//
//  if FRequest is TIndyHttpRequest then
//  begin
//    IndyRequest := TIndyHttpRequest(FRequest);
//    IndyRequest.GetRouteParams.Clear;
//    for Param in AParams do
//    begin
//      IndyRequest.GetRouteParams.Add(Param.Key, Param.Value);
//    end;
//
//    Writeln('  After injection - FRouteParams count: ', IndyRequest.GetRouteParams.Count);
//  end
//  else
//  begin
//    Writeln('❌ ERROR: FRequest is not TIndyHttpRequest');
//  end;
//end;

{ TMockFactory }

class function TMockFactory.CreateHttpContext(const AQueryString: string): IHttpContext;
var
  Request: IHttpRequest;
  Response: IHttpResponse;
begin
  Request := TMockHttpRequest.Create(AQueryString);
  Response := TMockHttpResponse.Create;
  Result := TMockHttpContext.Create(Request, Response);
end;

//class function TMockFactory.CreateHttpContextWithRoute(const AQueryString: string;
//  const ARouteParams: IDictionary<string, string>): IHttpContext;
//begin
//  Result := CreateHttpContext(AQueryString);
//  (Result as TMockHttpContext).SetRouteParams(ARouteParams);
//end;

class function TMockFactory.CreateHttpContextWithRoute(const AQueryString: string;
  const ARouteParams: TRouteValueDictionary): IHttpContext;
var
  Request: IHttpRequest;
  Response: IHttpResponse;
begin
  Request := TMockHttpRequest.Create(AQueryString);
  Response := TMockHttpResponse.Create;
  Result := TMockHttpContext.Create(Request, Response);

  // Injeta os route params
  (Result as TMockHttpContext).SetRouteParams(ARouteParams);
end;

class function TMockFactory.CreateHttpContextWithHeaders(const AQueryString:
  string; const AHeaders: IStringDictionary): IHttpContext;
var
  Request: IHttpRequest;
  Response: IHttpResponse;
begin
  Request := TMockHttpRequestWithHeaders.CreateWithHeaders(AQueryString, AHeaders);
  Response := TMockHttpResponse.Create;
  Result := TMockHttpContext.Create(Request, Response);
end;

class function TMockFactory.CreateHttpContextWithServices(const AQueryString:
  string; const AServices: IServiceProvider): IHttpContext;
var
  Request: IHttpRequest;
  Response: IHttpResponse;
begin
  Request := TMockHttpRequest.Create(AQueryString);
  Response := TMockHttpResponse.Create;
  Result := TMockHttpContextWithServices.CreateWithServices(Request, Response, AServices);
end;

{ TMockHttpRequestWithHeaders }

constructor TMockHttpRequestWithHeaders.CreateWithHeaders(const AQueryString: string;
  const AHeaders: IStringDictionary);
begin
  inherited Create(AQueryString);

  // Clonar os headers fornecidos
  FCustomHeaders := TCollections.CreateStringDictionary;
  for var Pair in AHeaders.ToArray do
  begin
    // Headers são case-insensitive, normalizar para lowercase
    FCustomHeaders.AddOrSetValue(Pair.Key.ToLower, Pair.Value);
  end;
end;

destructor TMockHttpRequestWithHeaders.Destroy;
begin
  // FCustomHeaders.Free;
  inherited Destroy;
end;

function TMockHttpRequestWithHeaders.GetHeaders: IStringDictionary;
begin
  Result := FCustomHeaders;
end;

{ TMockHttpContextWithServices }

constructor TMockHttpContextWithServices.CreateWithServices(ARequest: IHttpRequest;
  AResponse: IHttpResponse; AServices: IServiceProvider);
begin
  inherited Create(ARequest, AResponse, AServices);
  FCustomServices := AServices;
end;

function TMockHttpContextWithServices.GetServices: IServiceProvider;
begin
  Result := FCustomServices;
end;

end.
