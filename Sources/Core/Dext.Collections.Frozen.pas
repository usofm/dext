unit Dext.Collections.Frozen;

interface

uses
  System.SysUtils,
  Dext.Collections.Dict;

type
  IFrozenDictionary<K, V> = interface
    ['{F1F2F3F4-E5E6-D7D8-C9CA-B7B8B9B0A1A2}']
    function TryGetValue(const Key: K; out Value: V): Boolean;
    function ContainsKey(const Key: K): Boolean;
    function GetCount: Integer;
    function GetItem(const Key: K): V;
    
    property Items[const Key: K]: V read GetItem; default;
    property Count: Integer read GetCount;
  end;

  TFrozenDictionary<K, V> = class(TInterfacedObject, IFrozenDictionary<K, V>)
  private
    FDict: IDictionary<K, V>;
    function GetCount: Integer;
    function GetItem(const Key: K): V;
  public
    constructor CreateInternal(const ADict: IDictionary<K, V>);
    
    function TryGetValue(const Key: K; out Value: V): Boolean;
    function ContainsKey(const Key: K): Boolean;

    class function Create(const Pairs: TArray<TPair<K, V>>): IFrozenDictionary<K, V>; overload;
    class function Create(const Dict: IDictionary<K, V>): IFrozenDictionary<K, V>; overload;
    
    property Items[const Key: K]: V read GetItem; default;
    property Count: Integer read GetCount;
  end;

implementation

{ TFrozenDictionary<K, V> }

constructor TFrozenDictionary<K, V>.CreateInternal(const ADict: IDictionary<K, V>);
begin
  inherited Create;
  FDict := ADict;
end;

class function TFrozenDictionary<K, V>.Create(const Pairs: TArray<TPair<K, V>>): IFrozenDictionary<K, V>;
var
  Dict: IDictionary<K, V>;
  Pair: TPair<K, V>;
begin
  Dict := TDictionary<K, V>.Create(Length(Pairs));
  for Pair in Pairs do
    Dict.AddOrSetValue(Pair.Key, Pair.Value);
  Result := TFrozenDictionary<K, V>.CreateInternal(Dict);
end;

class function TFrozenDictionary<K, V>.Create(const Dict: IDictionary<K, V>): IFrozenDictionary<K, V>;
var
  NewDict: IDictionary<K, V>;
  Pair: TPair<K, V>;
begin
  NewDict := TDictionary<K, V>.Create(Dict.Count);
  for Pair in Dict do
    NewDict.AddOrSetValue(Pair.Key, Pair.Value);
  Result := TFrozenDictionary<K, V>.CreateInternal(NewDict);
end;

function TFrozenDictionary<K, V>.ContainsKey(const Key: K): Boolean;
begin
  Result := FDict.ContainsKey(Key);
end;

function TFrozenDictionary<K, V>.GetCount: Integer;
begin
  Result := FDict.Count;
end;

function TFrozenDictionary<K, V>.GetItem(const Key: K): V;
begin
  Result := FDict.Items[Key];
end;

function TFrozenDictionary<K, V>.TryGetValue(const Key: K; out Value: V): Boolean;
begin
  Result := FDict.TryGetValue(Key, Value);
end;

end.
