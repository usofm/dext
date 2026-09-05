unit Dext.Web.Htmx.Tests;

interface

uses
  System.SysUtils,
  Dext.Testing.Attributes,
  Dext.Assertions,
  Dext.Web.Interfaces,
  Dext.Web.Htmx4,
  Dext.Web.Mocks,
  Dext.Collections,
  Dext.Collections.Dict;

type
  [TestFixture('HTMX Fluent Response Tests (S23 + HTMX 4)')]
  THtmxResponseTests = class
  public
    [Test('Should set HX-Trigger header')]
    procedure TestTrigger;
    [Test('Should set HX-Retarget header')]
    procedure TestRetarget;
    [Test('Should set HX-Reswap header')]
    procedure TestReswap;
    [Test('Should set HX-Redirect header')]
    procedure TestRedirect;
    [Test('Should set HX-Refresh header')]
    procedure TestRefresh;
    [Test('Should set HX-Push-Url header')]
    procedure TestPushUrl;
    [Test('Should set HX-Replace-Url header')]
    procedure TestReplaceUrl;
    [Test('Should set HX-Location header')]
    procedure TestLocation;
    [Test('Should allow chaining multiple HTMX headers')]
    procedure TestChaining;
    [Test('HTMX 4 should detect partial request metadata')]
    procedure TestHtmx4PartialRequest;
    [Test('HTMX 4 should detect full request metadata')]
    procedure TestHtmx4FullRequest;
    [Test('HTMX 4 should expose source target and current URL')]
    procedure TestHtmx4RequestMetadata;
    [Test('HTMX 4 should identify boosted and history restore requests')]
    procedure TestHtmx4RequestFlags;
    [Test('HTMX 4 partial builder should render multiple targets')]
    procedure TestHtmx4MultiplePartials;
    [Test('HTMX 4 partial builder should support id shorthand and swap')]
    procedure TestHtmx4PartialId;
    [Test('HTMX 4 partial builder should escape generated attributes only')]
    procedure TestHtmx4PartialAttributeEscaping;
  end;

implementation

function NewHeaders: IStringDictionary;
begin
  Result := TCollections.CreateStringDictionary(True);
end;

procedure THtmxResponseTests.TestTrigger;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  Response.Htmx.Trigger('myEvent');
  Should(Response.Headers['HX-Trigger']).Be('myEvent');
end;

procedure THtmxResponseTests.TestRetarget;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  Response.Htmx.Retarget('#target');
  Should(Response.Headers['HX-Retarget']).Be('#target');
end;

procedure THtmxResponseTests.TestReswap;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  Response.Htmx.Reswap('outerHTML');
  Should(Response.Headers['HX-Reswap']).Be('outerHTML');
end;

procedure THtmxResponseTests.TestRedirect;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  Response.Htmx.Redirect('/new-path');
  Should(Response.Headers['HX-Redirect']).Be('/new-path');
end;

procedure THtmxResponseTests.TestRefresh;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  Response.Htmx.Refresh;
  Should(Response.Headers['HX-Refresh']).Be('true');
end;

procedure THtmxResponseTests.TestPushUrl;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  Response.Htmx.PushUrl('/new-url');
  Should(Response.Headers['HX-Push-Url']).Be('/new-url');
end;

procedure THtmxResponseTests.TestReplaceUrl;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  Response.Htmx.ReplaceUrl('/replaced-url');
  Should(Response.Headers['HX-Replace-Url']).Be('/replaced-url');
end;

procedure THtmxResponseTests.TestLocation;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  Response.Htmx.Location('/location');
  Should(Response.Headers['HX-Location']).Be('/location');
end;

procedure THtmxResponseTests.TestChaining;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  Response.Htmx
    .Trigger('event1')
    .Retarget('#div1')
    .Reswap('innerHTML');
  Should(Response.Headers['HX-Trigger']).Be('event1');
  Should(Response.Headers['HX-Retarget']).Be('#div1');
  Should(Response.Headers['HX-Reswap']).Be('innerHTML');
end;

procedure THtmxResponseTests.TestHtmx4PartialRequest;
var
  Headers: IStringDictionary;
  Context: IHttpContext;
  Info: THtmxRequestInfo;
begin
  Headers := NewHeaders;
  Headers.AddOrSetValue('HX-Request', 'true');
  Headers.AddOrSetValue('HX-Request-Type', 'partial');
  Context := TMockFactory.CreateHttpContextWithHeaders('', Headers);
  Info := Htmx4.Request(Context);
  Should(Info.IsHtmx).BeTrue;
  Should(Info.IsPartial).BeTrue;
  Should(Info.IsFull).BeFalse;
  Should(Ord(Info.RequestType)).Be(Ord(hrtPartial));
end;

procedure THtmxResponseTests.TestHtmx4FullRequest;
var
  Headers: IStringDictionary;
  Context: IHttpContext;
  Info: THtmxRequestInfo;
begin
  Headers := NewHeaders;
  Headers.AddOrSetValue('HX-Request', 'TRUE');
  Headers.AddOrSetValue('HX-Request-Type', 'FULL');
  Context := TMockFactory.CreateHttpContextWithHeaders('', Headers);
  Info := Htmx4.Request(Context.Request);
  Should(Info.IsHtmx).BeTrue;
  Should(Info.IsFull).BeTrue;
  Should(Info.IsPartial).BeFalse;
  Should(Ord(Info.RequestType)).Be(Ord(hrtFull));
end;

procedure THtmxResponseTests.TestHtmx4RequestMetadata;
var
  Headers: IStringDictionary;
  Info: THtmxRequestInfo;
begin
  Headers := NewHeaders;
  Headers.AddOrSetValue('HX-Request', 'true');
  Headers.AddOrSetValue('HX-Source', 'button#save');
  Headers.AddOrSetValue('HX-Target', 'div#invoice-grid');
  Headers.AddOrSetValue('HX-Current-URL', 'https://example.test/invoices/42');
  Info := Htmx4.Request(TMockFactory.CreateHttpContextWithHeaders('', Headers));
  Should(Info.Source).Be('button#save');
  Should(Info.Target).Be('div#invoice-grid');
  Should(Info.CurrentUrl).Be('https://example.test/invoices/42');
end;

procedure THtmxResponseTests.TestHtmx4RequestFlags;
var
  Headers: IStringDictionary;
  Info: THtmxRequestInfo;
begin
  Headers := NewHeaders;
  Headers.AddOrSetValue('HX-Request', 'true');
  Headers.AddOrSetValue('HX-Boosted', 'true');
  Headers.AddOrSetValue('HX-History-Restore-Request', 'true');
  Info := Htmx4.Request(TMockFactory.CreateHttpContextWithHeaders('', Headers));
  Should(Info.IsBoosted).BeTrue;
  Should(Info.IsHistoryRestore).BeTrue;
end;

procedure THtmxResponseTests.TestHtmx4MultiplePartials;
var
  Builder: THtmxPartialBuilder;
  Html: string;
  DQ: Char;
begin
  DQ := Char(34);
  Builder := Htmx4.Partials;
  try
    Html := Builder
      .Target('#invoice-grid', '<tr><td>INV-42</td></tr>', 'beforeend')
      .Target('#invoice-count', '<span>42</span>')
      .ToHtml;
    Should(Html).Be(
      '<hx-partial hx-target=' + DQ + '#invoice-grid' + DQ +
      ' hx-swap=' + DQ + 'beforeend' + DQ + '>' +
      '<tr><td>INV-42</td></tr></hx-partial>' +
      '<hx-partial hx-target=' + DQ + '#invoice-count' + DQ + '>' +
      '<span>42</span></hx-partial>');
  finally
    Builder.Free;
  end;
end;

procedure THtmxResponseTests.TestHtmx4PartialId;
var
  Builder: THtmxPartialBuilder;
  DQ: Char;
begin
  DQ := Char(34);
  Builder := Htmx4.Partials;
  try
    Should(Builder.Id('#toast', '<b>Saved</b>', 'beforeend').ToHtml).Be(
      '<hx-partial id=' + DQ + 'toast' + DQ +
      ' hx-swap=' + DQ + 'beforeend' + DQ + '><b>Saved</b></hx-partial>');
  finally
    Builder.Free;
  end;
end;

procedure THtmxResponseTests.TestHtmx4PartialAttributeEscaping;
var
  Builder: THtmxPartialBuilder;
  Selector: string;
  DQ: Char;
begin
  DQ := Char(34);
  Selector := '[data-x=' + DQ + 'a&b' + DQ + ']';
  Builder := Htmx4.Partials;
  try
    Should(Builder.Target(Selector, '<em>A&B</em>').ToHtml).Be(
      '<hx-partial hx-target=' + DQ + '[data-x=&quot;a&amp;b&quot;]' + DQ + '>' +
      '<em>A&B</em></hx-partial>');
  finally
    Builder.Free;
  end;
end;

end.
