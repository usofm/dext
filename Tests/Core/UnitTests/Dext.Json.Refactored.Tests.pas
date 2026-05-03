unit Dext.Json.Refactored.Tests;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
//  System.Generics.Collections,
  Dext.Testing.Attributes,
  Dext.Assertions,
  Dext.Json,
  Dext.Core.Activator;

type
  // Mock interface for TkInterface serialization test
  {$M+}
  IMockList = interface
    ['{1A09E5A8-EE5B-4FA3-8756-3FFCA04CB9DE}']
    function GetCount: Integer;
    function GetItem(Index: Integer): string;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: string read GetItem; default;
  end;
  {$M-}

  TMockList = class(TInterfacedObject, IMockList)
  private
    FItems: TArray<string>;
  public
    constructor Create(const AItems: TArray<string>);
    function GetCount: Integer;
    function GetItem(Index: Integer): string;
  end;

  [TestFixture('JSON Serialize Refactored Tests (Phase 3)')]
  TJsonInterfaceListTests = class
  public
    [Test('T.1 - Should serialize interface correctly using RTTI GetCount/GetItem fallback')]
    procedure TestSerializeInterfaceList;
    
    [Test('T.2 - Should resolve RTTI types massively via Activator without memory leaks')]
    procedure TestMassiveRttiContextResolution;
  end;

implementation

{ TMockList }

constructor TMockList.Create(const AItems: TArray<string>);
begin
  inherited Create;
  FItems := AItems;
end;

function TMockList.GetCount: Integer;
begin
  Result := Length(FItems);
end;

function TMockList.GetItem(Index: Integer): string;
begin
  Result := FItems[Index];
end;

{ TJsonInterfaceListTests }

procedure TJsonInterfaceListTests.TestSerializeInterfaceList;
var
  List: IMockList;
  Val: TValue;
  JsonStr: string;
begin
  List := TMockList.Create(['Item1', 'Item2', 'Item3']);

  // Wrap inside TValue as IMockList to force tkInterface route on Serializer
  Val := TValue.From<IMockList>(List);

  JsonStr := TDextJson.Serialize(Val);
  Should(JsonStr).NotBeEmpty;
  Should(JsonStr).Contain('Item1');
  Should(JsonStr).Contain('Item2');
  Should(JsonStr).Contain('Item3');
end;

procedure TJsonInterfaceListTests.TestMassiveRttiContextResolution;
var
  I: Integer;
  RttiType: TRttiType;
begin
  // Simulates high-throughput scenario for RTTI resolving
  for I := 1 to 50000 do
  begin
    RttiType := TActivator.GetRttiContext.GetType(TypeInfo(TJsonInterfaceListTests));
    Should(RttiType <> nil).BeTrue;
  end;
  Should(True).BeTrue;
end;

end.
