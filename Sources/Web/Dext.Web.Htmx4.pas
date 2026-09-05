{***************************************************************************}
{                                                                           }
{           Dext Framework                                                  }
{                                                                           }
{           HTMX 4 request metadata and multi-target partial helpers        }
{                                                                           }
{***************************************************************************}
unit Dext.Web.Htmx4;

interface

uses
  System.SysUtils,
  System.Classes,
  Dext.Web.Interfaces;

type
  /// <summary>
  ///   HTMX 4 request kind reported by the HX-Request-Type request header.
  /// </summary>
  THtmxRequestType = (hrtNone, hrtPartial, hrtFull);

  /// <summary>
  ///   Transport-independent HTMX request metadata reader built on Dext's
  ///   IHttpRequest abstraction.
  /// </summary>
  THtmxRequestInfo = record
  private
    FRequest: IHttpRequest;
    function Header(const AName: string): string;
    function HeaderIsTrue(const AName: string): Boolean;
  public
    constructor Create(const ARequest: IHttpRequest);
    function IsHtmx: Boolean;
    function RequestType: THtmxRequestType;
    function IsPartial: Boolean;
    function IsFull: Boolean;
    function IsBoosted: Boolean;
    function IsHistoryRestore: Boolean;
    function CurrentUrl: string;
    function Source: string;
    function Target: string;
  end;

  /// <summary>
  ///   Fluent builder for HTMX 4 multi-target responses using hx-partial.
  ///   Fragment bodies are already-rendered HTML. Builder-generated attribute
  ///   values are HTML-escaped.
  /// </summary>
  THtmxPartialBuilder = class
  private
    FBuilder: TStringBuilder;
    class function EscapeAttribute(const AValue: string): string; static;
    procedure AppendAttribute(const AName, AValue: string);
    procedure AppendPartial(const ATarget, AId, AHtml, ASwap: string);
  public
    constructor Create;
    destructor Destroy; override;
    function Target(const ASelector, AHtml: string;
      const ASwap: string = ''): THtmxPartialBuilder;
    function Id(const AId, AHtml: string;
      const ASwap: string = ''): THtmxPartialBuilder;
    function Clear: THtmxPartialBuilder;
    function ToHtml: string;
    function AsResult(AStatusCode: Integer = 200): IResult;
  end;

  /// <summary>HTMX 4 entry points that complement the existing Response.Htmx API.</summary>
  Htmx4 = class
  public
    class function Request(const ARequest: IHttpRequest): THtmxRequestInfo; overload; static;
    class function Request(const AContext: IHttpContext): THtmxRequestInfo; overload; static;
    class function Partials: THtmxPartialBuilder; static;
  end;

implementation

uses
  Dext.Collections.Dict,
  Dext.Web.Results;

{ THtmxRequestInfo }

constructor THtmxRequestInfo.Create(const ARequest: IHttpRequest);
begin
  FRequest := ARequest;
end;

function THtmxRequestInfo.Header(const AName: string): string;
var
  Headers: IStringDictionary;
begin
  Result := '';
  if FRequest = nil then
    Exit;
  Headers := FRequest.Headers;
  if Headers = nil then
    Exit;
  Headers.TryGetValue(AName, Result);
end;

function THtmxRequestInfo.HeaderIsTrue(const AName: string): Boolean;
begin
  Result := SameText(Trim(Header(AName)), 'true');
end;

function THtmxRequestInfo.IsHtmx: Boolean;
begin
  Result := HeaderIsTrue('HX-Request');
end;

function THtmxRequestInfo.RequestType: THtmxRequestType;
var
  Value: string;
begin
  Result := hrtNone;
  if not IsHtmx then
    Exit;
  Value := Trim(Header('HX-Request-Type'));
  if SameText(Value, 'partial') then
    Result := hrtPartial
  else if SameText(Value, 'full') then
    Result := hrtFull;
end;

function THtmxRequestInfo.IsPartial: Boolean;
begin
  Result := RequestType = hrtPartial;
end;

function THtmxRequestInfo.IsFull: Boolean;
begin
  Result := RequestType = hrtFull;
end;

function THtmxRequestInfo.IsBoosted: Boolean;
begin
  Result := HeaderIsTrue('HX-Boosted');
end;

function THtmxRequestInfo.IsHistoryRestore: Boolean;
begin
  Result := HeaderIsTrue('HX-History-Restore-Request');
end;

function THtmxRequestInfo.CurrentUrl: string;
begin
  Result := Header('HX-Current-URL');
end;

function THtmxRequestInfo.Source: string;
begin
  Result := Header('HX-Source');
end;

function THtmxRequestInfo.Target: string;
begin
  Result := Header('HX-Target');
end;

{ THtmxPartialBuilder }

constructor THtmxPartialBuilder.Create;
begin
  inherited Create;
  FBuilder := TStringBuilder.Create;
end;

destructor THtmxPartialBuilder.Destroy;
begin
  FBuilder.Free;
  inherited;
end;

class function THtmxPartialBuilder.EscapeAttribute(const AValue: string): string;
begin
  Result := StringReplace(AValue, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, Char(34), '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
end;

procedure THtmxPartialBuilder.AppendAttribute(const AName, AValue: string);
begin
  FBuilder.Append(' ').Append(AName).Append('=').Append(Char(34));
  FBuilder.Append(EscapeAttribute(AValue));
  FBuilder.Append(Char(34));
end;

procedure THtmxPartialBuilder.AppendPartial(const ATarget, AId, AHtml,
  ASwap: string);
begin
  FBuilder.Append('<hx-partial');
  if ATarget <> '' then
    AppendAttribute('hx-target', ATarget);
  if AId <> '' then
    AppendAttribute('id', AId);
  if ASwap <> '' then
    AppendAttribute('hx-swap', ASwap);
  FBuilder.Append('>');
  FBuilder.Append(AHtml);
  FBuilder.Append('</hx-partial>');
end;

function THtmxPartialBuilder.Target(const ASelector, AHtml,
  ASwap: string): THtmxPartialBuilder;
begin
  if Trim(ASelector) = '' then
    raise EArgumentException.Create('HTMX partial target must not be empty');
  AppendPartial(ASelector, '', AHtml, ASwap);
  Result := Self;
end;

function THtmxPartialBuilder.Id(const AId, AHtml,
  ASwap: string): THtmxPartialBuilder;
var
  IdValue: string;
begin
  IdValue := Trim(AId);
  if (IdValue <> '') and (IdValue[1] = '#') then
    Delete(IdValue, 1, 1);
  if IdValue = '' then
    raise EArgumentException.Create('HTMX partial id must not be empty');
  AppendPartial('', IdValue, AHtml, ASwap);
  Result := Self;
end;

function THtmxPartialBuilder.Clear: THtmxPartialBuilder;
begin
  FBuilder.Clear;
  Result := Self;
end;

function THtmxPartialBuilder.ToHtml: string;
begin
  Result := FBuilder.ToString;
end;

function THtmxPartialBuilder.AsResult(AStatusCode: Integer): IResult;
begin
  Result := Results.Html(ToHtml, AStatusCode);
end;

{ Htmx4 }

class function Htmx4.Request(const ARequest: IHttpRequest): THtmxRequestInfo;
begin
  Result := THtmxRequestInfo.Create(ARequest);
end;

class function Htmx4.Request(const AContext: IHttpContext): THtmxRequestInfo;
begin
  if AContext = nil then
    Result := THtmxRequestInfo.Create(nil)
  else
    Result := THtmxRequestInfo.Create(AContext.Request);
end;

class function Htmx4.Partials: THtmxPartialBuilder;
begin
  Result := THtmxPartialBuilder.Create;
end;

end.
