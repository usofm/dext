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
{  Created: 2026-02-24                                                      }
{                                                                           }
{  Generic dictionary (hash map) for Dext.Collections.                      }
{  Thin generic frontend over TRawDictionary backend.                       }
{                                                                           }
{***************************************************************************}
unit Dext.Collections.Dict;

interface

uses
  System.SysUtils,
  System.TypInfo,
  Dext.Collections.Base,
  Dext.Collections.RawDict;

type
  /// <summary>Key-value pair record</summary>
  TPair<K, V> = record
    Key: K;
    Value: V;
    constructor Create(const AKey: K; const AValue: V);
  end;

  /// <summary>Generic dictionary interface</summary>
  IDictionary<K, V> = interface(IEnumerable<TPair<K, V>>)
    ['{A7E3F294-60B1-4C01-B8D5-4E5F3A2C1D70}']
    function GetCount: Integer;
    function GetItem(const Key: K): V;
    procedure SetItem(const Key: K; const Value: V);

    procedure Add(const Key: K; const Value: V);
    procedure AddOrSetValue(const Key: K; const Value: V);
    function TryGetValue(const Key: K; out Value: V): Boolean;
    function ContainsKey(const Key: K): Boolean;
    function Remove(const Key: K): Boolean;
    function Extract(const Key: K): V;
    procedure Clear;

    function Keys: TArray<K>;
    function Values: TArray<V>;
    function ToArray: TArray<TPair<K, V>>;
    function GetEnumerator: IEnumerator<TPair<K, V>>;

    property Count: Integer read GetCount;
    property Items[const Key: K]: V read GetItem write SetItem; default;
  end;

  /// <summary>Generic dictionary implementation backed by TRawDictionary</summary>
  TDictionary<K, V> = class(TInterfacedObject, IDictionary<K, V>)
  private
    FCore: TRawDictionary;
    FOwnsValues: Boolean;
    function GetCount: Integer;
    function GetItem(const Key: K): V;
    procedure SetItem(const Key: K; const Value: V);
  public
    constructor Create; overload;
    constructor Create(ACapacity: Integer); overload;
    constructor Create(AOwnsValues: Boolean; ACapacity: Integer = 0); overload;
    destructor Destroy; override;

    function GetEnumerator: IEnumerator<TPair<K, V>>;

    procedure Add(const Key: K; const Value: V);
    procedure AddOrSetValue(const Key: K; const Value: V);
    function TryGetValue(const Key: K; out Value: V): Boolean;
    function ContainsKey(const Key: K): Boolean;
    function Remove(const Key: K): Boolean;
    function Extract(const Key: K): V;
    procedure Clear;

    function Keys: TArray<K>;
    function Values: TArray<V>;
    function ToArray: TArray<TPair<K, V>>;

    property Count: Integer read GetCount;
    property Items[const Key: K]: V read GetItem write SetItem; default;
    property OwnsValues: Boolean read FOwnsValues write FOwnsValues;
  end;

  /// <summary>Enumerator for TDictionary</summary>
  TDictEnumerator<K, V> = class(TInterfacedObject, IEnumerator<TPair<K, V>>)
  private
    FCore: TRawDictionary;
    FIndex: Integer;
  public
    constructor Create(ACore: TRawDictionary);
    function GetCurrent: TPair<K, V>;
    function MoveNext: Boolean;
    property Current: TPair<K, V> read GetCurrent;
  end;

implementation

{ TPair<K, V> }

constructor TPair<K, V>.Create(const AKey: K; const AValue: V);
begin
  Key := AKey;
  Value := AValue;
end;

{ TDictionary<K, V> }

constructor TDictionary<K, V>.Create;
begin
  Create(False, 0);
end;

constructor TDictionary<K, V>.Create(ACapacity: Integer);
begin
  Create(False, ACapacity);
end;

constructor TDictionary<K, V>.Create(AOwnsValues: Boolean; ACapacity: Integer);
var
  HF: TRawHashFunc;
  EF: TRawEqualFunc;
begin
  inherited Create;
  FOwnsValues := AOwnsValues;

  if PTypeInfo(System.TypeInfo(K)).Kind in [tkUString, tkLString, tkWString] then
  begin
    HF := @StringRawHash;
    EF := @StringRawEqual;
  end
  else
  begin
    HF := @DefaultRawHash;
    EF := @DefaultRawEqual;
  end;

  FCore := TRawDictionary.Create(
    SizeOf(K), SizeOf(V),
    System.TypeInfo(K), System.TypeInfo(V),
    HF, EF,
    ACapacity
  );
end;

destructor TDictionary<K, V>.Destroy;
begin
  if FOwnsValues and (PTypeInfo(System.TypeInfo(V)).Kind = tkClass) then
  begin
    // Free owned objects before clearing
    FCore.ForEachRaw(
      function(KeyPtr, ValuePtr: Pointer): Boolean
      begin
        if PPointer(ValuePtr)^ <> nil then
          TObject(PPointer(ValuePtr)^).Free;
        Result := True;
      end);
  end;
  FCore.Free;
  inherited;
end;

function TDictionary<K, V>.GetEnumerator: IEnumerator<TPair<K, V>>;
begin
  Result := TDictEnumerator<K, V>.Create(FCore);
end;

function TDictionary<K, V>.GetCount: Integer;
begin
  Result := FCore.Count;
end;

function TDictionary<K, V>.GetItem(const Key: K): V;
var
  VP: Pointer;
begin
  if not FCore.TryGetRaw(@Key, VP) then
    raise Exception.Create('Key not found in dictionary');
  Result := V(VP^);
end;

procedure TDictionary<K, V>.SetItem(const Key: K; const Value: V);
begin
  AddOrSetValue(Key, Value);
end;

procedure TDictionary<K, V>.Add(const Key: K; const Value: V);
begin
  FCore.AddRaw(@Key, @Value);
end;

procedure TDictionary<K, V>.AddOrSetValue(const Key: K; const Value: V);
var
  VP: Pointer;
begin
  // If OwnsValues, free the old object before overwriting
  if FOwnsValues and (PTypeInfo(System.TypeInfo(V)).Kind = tkClass) then
  begin
    if FCore.TryGetRaw(@Key, VP) then
    begin
      if PPointer(VP)^ <> nil then
        TObject(PPointer(VP)^).Free;
    end;
  end;
  FCore.AddOrSetRaw(@Key, @Value);
end;

function TDictionary<K, V>.TryGetValue(const Key: K; out Value: V): Boolean;
var
  VP: Pointer;
begin
  Result := FCore.TryGetRaw(@Key, VP);
  if Result then
    Value := V(VP^)
  else
    Value := Default(V);
end;

function TDictionary<K, V>.ContainsKey(const Key: K): Boolean;
begin
  Result := FCore.ContainsKeyRaw(@Key);
end;

function TDictionary<K, V>.Remove(const Key: K): Boolean;
begin
  if FOwnsValues and (PTypeInfo(System.TypeInfo(V)).Kind = tkClass) then
  begin
    var VP: Pointer;
    if FCore.TryGetRaw(@Key, VP) then
    begin
      if PPointer(VP)^ <> nil then
        TObject(PPointer(VP)^).Free;
    end;
  end;
  Result := FCore.RemoveRaw(@Key);
end;

function TDictionary<K, V>.Extract(const Key: K): V;
var
  VP: Pointer;
begin
  if FCore.TryGetRaw(@Key, VP) then
  begin
    Result := V(VP^);
    FCore.RemoveRaw(@Key);
  end
  else
    Result := Default(V);
end;

procedure TDictionary<K, V>.Clear;
begin
  if FOwnsValues and (PTypeInfo(System.TypeInfo(V)).Kind = tkClass) then
  begin
    FCore.ForEachRaw(
      function(KeyPtr, ValuePtr: Pointer): Boolean
      begin
        if PPointer(ValuePtr)^ <> nil then
          TObject(PPointer(ValuePtr)^).Free;
        Result := True;
      end);
  end;
  FCore.Clear;
end;

function TDictionary<K, V>.Keys: TArray<K>;
var
  Arr: TArray<K>;
  Idx: Integer;
begin
  SetLength(Arr, FCore.Count);
  Idx := 0;
  FCore.ForEachRaw(
    function(KeyPtr, ValuePtr: Pointer): Boolean
    begin
      Arr[Idx] := K(KeyPtr^);
      Inc(Idx);
      Result := True;
    end);
  Result := Arr;
end;

function TDictionary<K, V>.Values: TArray<V>;
var
  Arr: TArray<V>;
  Idx: Integer;
begin
  SetLength(Arr, FCore.Count);
  Idx := 0;
  FCore.ForEachRaw(
    function(KeyPtr, ValuePtr: Pointer): Boolean
    begin
      Arr[Idx] := V(ValuePtr^);
      Inc(Idx);
      Result := True;
    end);
  Result := Arr;
end;

function TDictionary<K, V>.ToArray: TArray<TPair<K, V>>;
var
  Arr: TArray<TPair<K, V>>;
  Idx: Integer;
begin
  SetLength(Arr, FCore.Count);
  Idx := 0;
  FCore.ForEachRaw(
    function(KeyPtr, ValuePtr: Pointer): Boolean
    begin
      Arr[Idx].Key := K(KeyPtr^);
      Arr[Idx].Value := V(ValuePtr^);
      Inc(Idx);
      Result := True;
    end);
  Result := Arr;
end;

{ TDictEnumerator<K, V> }

constructor TDictEnumerator<K, V>.Create(ACore: TRawDictionary);
begin
  inherited Create;
  FCore := ACore;
  FIndex := -1;
end;

function TDictEnumerator<K, V>.GetCurrent: TPair<K, V>;
begin
  Result.Key := K(FCore.GetKeyPtrAtIndex(FIndex)^);
  Result.Value := V(FCore.GetValuePtrAtIndex(FIndex)^);
end;

function TDictEnumerator<K, V>.MoveNext: Boolean;
begin
  Inc(FIndex);
  while FIndex < FCore.Capacity do
  begin
    if FCore.IsSlotOccupied(FIndex) then
      Exit(True);
    Inc(FIndex);
  end;
  Result := False;
end;

end.
