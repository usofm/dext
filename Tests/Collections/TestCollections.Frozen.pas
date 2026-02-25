unit TestCollections.Frozen;

interface

uses
  System.SysUtils,
  Dext.Testing,
  Dext.Collections,
  Dext.Collections.Dict,
  Dext.Collections.Frozen;

type
  TFrozenDictionaryTests = class
  public
    [Test]
    procedure TestCreateFromPairs;
    [Test]
    procedure TestCreateFromDictionary;
    [Test]
    procedure TestTryGetValue;
  end;

implementation

{ TFrozenDictionaryTests }

procedure TFrozenDictionaryTests.TestCreateFromPairs;
var
  Pairs: TArray<TPair<string, Integer>>;
  Frozen: IFrozenDictionary<string, Integer>;
begin
  SetLength(Pairs, 2);
  Pairs[0] := TPair<string, Integer>.Create('One', 1);
  Pairs[1] := TPair<string, Integer>.Create('Two', 2);
  
  Frozen := TFrozenDictionary<string, Integer>.Create(Pairs);
  
  Should(Frozen.Count).Be(2);
  Should(Frozen.ContainsKey('One')).BeTrue;
  Should(Frozen.ContainsKey('Two')).BeTrue;
  Should(Frozen['One']).Be(1);
  Should(Frozen['Two']).Be(2);
  Should(Frozen.ContainsKey('Three')).BeFalse;
end;

procedure TFrozenDictionaryTests.TestCreateFromDictionary;
var
  Dict: IDictionary<string, Integer>;
  Frozen: IFrozenDictionary<string, Integer>;
begin
  Dict := TCollections.CreateDictionary<string, Integer>;
  Dict.Add('A', 10);
  Dict.Add('B', 20);
  
  Frozen := TFrozenDictionary<string, Integer>.Create(Dict);
  
  Should(Frozen.Count).Be(2);
  Should(Frozen.ContainsKey('A')).BeTrue;
  Should(Frozen.ContainsKey('B')).BeTrue;
  Should(Frozen['A']).Be(10);
  Should(Frozen['B']).Be(20);
end;

procedure TFrozenDictionaryTests.TestTryGetValue;
var
  Dict: IDictionary<string, Integer>;
  Frozen: IFrozenDictionary<string, Integer>;
  Val: Integer;
begin
  Dict := TCollections.CreateDictionary<string, Integer>;
  Dict.Add('Test', 99);
  
  Frozen := TFrozenDictionary<string, Integer>.Create(Dict);
  
  Should(Frozen.TryGetValue('Test', Val)).BeTrue;
  Should(Val).Be(99);
  
  Should(Frozen.TryGetValue('NotExists', Val)).BeFalse;
  Should(Val).Be(0); 
end;

end.
