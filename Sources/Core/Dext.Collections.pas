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
{  Created: 2025-12-08                                                      }
{  Refactored: 2026-02-23 — Replaced RTL generics with TRawList backend    }
{                                                                           }
{***************************************************************************}
unit Dext.Collections;

interface

uses
  System.SysUtils,
  System.TypInfo,
  Dext.Collections.Base,
  Dext.Collections.Raw,
  Dext.Collections.Comparers,
  Dext.Collections.Dict,
  Dext.Specifications.Interfaces,
  Dext.Specifications.Evaluator;

type
  /// <summary>Collection notification type (compatible with RTL enum values)</summary>
  TCollectionNotification = (cnAdded, cnRemoved, cnExtracted);
  
  {$M+}
  IList<T> = interface(IEnumerable<T>)
    ['{8877539D-3522-488B-933B-8C4581177699}']
    function GetCount: Integer;
    function GetItem(Index: Integer): T;
    procedure SetItem(Index: Integer; const Value: T);

    procedure Add(const Value: T);
    procedure AddRange(const Values: IEnumerable<T>); overload;
    procedure AddRange(const Values: array of T); overload;
    procedure Insert(Index: Integer; const Value: T);
    function Remove(const Value: T): Boolean;
    function Extract(const Value: T): T;
    procedure Delete(Index: Integer);
    procedure RemoveAt(Index: Integer);
    procedure Clear();
    function Contains(const Value: T): Boolean;
    function IndexOf(const Value: T): Integer;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: T read GetItem write SetItem; default;

    function Where(const Predicate: TFunc<T, Boolean>): IList<T>; overload;
    function Where(const Expression: IExpression): IList<T>; overload;

    function First: T; overload;
    function First(const Expression: IExpression): T; overload;

    function Last: T;

    function FirstOrDefault: T; overload;
    function FirstOrDefault(const DefaultValue: T): T; overload;
    function FirstOrDefault(const Expression: IExpression): T; overload;

    function Any(const Predicate: TFunc<T, Boolean>): Boolean; overload;
    function Any(const Expression: IExpression): Boolean; overload;
    function Any: Boolean; overload;

    function All(const Predicate: TFunc<T, Boolean>): Boolean; overload;
    function All(const Expression: IExpression): Boolean; overload;

    procedure ForEach(const Action: TProc<T>);
    procedure Sort(const AComparer: IComparer<T> = nil);
    function ToArray: TArray<T>;
  end;

  /// <summary>Generic Stack (LIFO) interface</summary>
  IStack<T> = interface(IEnumerable<T>)
    ['{7A8B9C0D-1E2F-3A4B-5C6D-7E8F9A0B1C2D}']
    function GetCount: Integer;
    procedure Push(const Value: T);
    function Pop: T;
    function Peek: T;
    function TryPop(out Value: T): Boolean;
    function TryPeek(out Value: T): Boolean;
    procedure Clear;
    function Contains(const Value: T): Boolean;
    function ToArray: TArray<T>;
    property Count: Integer read GetCount;
  end;

  /// <summary>Generic Queue (FIFO) interface</summary>
  IQueue<T> = interface(IEnumerable<T>)
    ['{AD1F2E3D-4C5B-6A7B-8C9D-0E1F2A3B4C5D}']
    function GetCount: Integer;
    procedure Enqueue(const Value: T);
    function Dequeue: T;
    function Peek: T;
    function TryDequeue(out Value: T): Boolean;
    function TryPeek(out Value: T): Boolean;
    procedure Clear;
    function Contains(const Value: T): Boolean;
    function ToArray: TArray<T>;
    property Count: Integer read GetCount;
  end;

  /// <summary>Generic HashSet interface</summary>
  IHashSet<T> = interface(IEnumerable<T>)
    ['{6B7C8D9E-0F1A-2B3C-4D5E-6F7A8B9C0D1E}']
    function GetCount: Integer;
    function Add(const Value: T): Boolean;
    function Remove(const Value: T): Boolean;
    procedure Clear;
    function Contains(const Value: T): Boolean;
    function ToArray: TArray<T>;
    property Count: Integer read GetCount;
  end;

  /// <summary>Enumerator backed by TRawList</summary>
  {$M+}
  TEnumerator<T> = class(TInterfacedObject, IEnumerator<T>)
  private
    FCore: TRawList;
    FIndex: Integer;
  public
    constructor Create(ACore: TRawList);
    function GetCurrent: T;
    function MoveNext: Boolean;
    property Current: T read GetCurrent;
  end;

  /// <summary>
  ///   Generic list backed by non-generic TRawList.
  ///   All storage is delegated to a single TRawList instance,
  ///   providing Code Folding: one compiled TRawList serves ALL
  ///   generic specializations.
  /// </summary>
  {$M+}
  TList<T> = class(TInterfacedObject, IList<T>, IEnumerable<T>, IDextCollection)
  protected
    FCore: TRawList;
    FOwnsObjects: Boolean;
    procedure Notify(Sender: TObject; const Item: T;
      Action: TCollectionNotification); virtual;
    function GetOwnsObjects: Boolean;
    procedure SetOwnsObjects(Value: Boolean);
    function GetCount: Integer;
    function GetItem(Index: Integer): T;
    procedure SetItem(Index: Integer; const Value: T);
  public
    function GetEnumerator: IEnumerator<T>;
    constructor Create; overload;
    constructor Create(OwnsObjects: Boolean); overload;
    destructor Destroy; override;

    procedure Add(const Value: T);
    procedure AddRange(const Values: IEnumerable<T>); overload;
    procedure AddRange(const Values: array of T); overload;
    procedure Insert(Index: Integer; const Value: T);
    function Remove(const Value: T): Boolean;
    function Extract(const Value: T): T;
    procedure Delete(Index: Integer);
    procedure RemoveAt(Index: Integer);
    procedure Clear;
    function Contains(const Value: T): Boolean;
    function IndexOf(const Value: T): Integer;

    function Where(const Predicate: TFunc<T, Boolean>): IList<T>; overload;
    function Where(const Expression: IExpression): IList<T>; overload;

    function First: T; overload;
    function First(const Expression: IExpression): T; overload;

    function Last: T;

    function FirstOrDefault: T; overload;
    function FirstOrDefault(const DefaultValue: T): T; overload;
    function FirstOrDefault(const Expression: IExpression): T; overload;

    function Any(const Predicate: TFunc<T, Boolean>): Boolean; overload;
    function Any(const Expression: IExpression): Boolean; overload;
    function Any: Boolean; overload;

    function All(const Predicate: TFunc<T, Boolean>): Boolean; overload;
    function All(const Expression: IExpression): Boolean; overload;

    procedure ForEach(const Action: TProc<T>);
    procedure Sort(const AComparer: IComparer<T> = nil);
    function ToArray: TArray<T>;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: T read GetItem write SetItem; default;
    property OwnsObjects: Boolean read FOwnsObjects write FOwnsObjects;
  end;

  /// <summary>Backward compatibility alias</summary>
  TSmartList<T> = class(TList<T>);
  TSmartEnumerator<T> = class(TEnumerator<T>);

  {$M+}
  {$RTTI EXPLICIT METHODS([vcPublic])}
  TCollections = class
  public
    class function CreateList<T>(OwnsObjects: Boolean = False): IList<T>; static;
    class function CreateObjectList<T: class>(OwnsObjects: Boolean = False): IList<T>; static;
    class function CreateDictionary<K, V>(ACapacity: Integer = 0): IDictionary<K, V>; overload; static;
    class function CreateDictionary<K, V>(AOwnsValues: Boolean; ACapacity: Integer = 0): IDictionary<K, V>; overload; static;

    class function CreateStack<T>: IStack<T>; static;
    class function CreateQueue<T>: IQueue<T>; static;
    class function CreateHashSet<T>: IHashSet<T>; static;
  end;
  {$M-}

implementation

uses
  Dext.Collections.Memory,
  Dext.Collections.Stack,
  Dext.Collections.Queue,
  Dext.Collections.HashSet;

{ TEnumerator<T> }

constructor TEnumerator<T>.Create(ACore: TRawList);
begin
  inherited Create;
  FCore := ACore;
  FIndex := -1;
end;

function TEnumerator<T>.GetCurrent: T;
begin
  FCore.GetRawItem(FIndex, @Result);
end;

function TEnumerator<T>.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FCore.Count;
end;

{ TList<T> }

constructor TList<T>.Create;
begin
  Create(False);
end;

constructor TList<T>.Create(OwnsObjects: Boolean);
begin
  inherited Create;
  FOwnsObjects := OwnsObjects;
  FCore := TRawList.Create(SizeOf(T), System.TypeInfo(T));
end;

destructor TList<T>.Destroy;
begin
  Clear;
  FCore.Free;
  inherited;
end;

procedure TList<T>.Notify(Sender: TObject; const Item: T;
  Action: TCollectionNotification);
begin
  if FOwnsObjects and (Action = cnRemoved) then
  begin
    if PTypeInfo(System.TypeInfo(T)).Kind = tkClass then
      TObject(PPointer(@Item)^).Free;
  end;
end;

function TList<T>.GetOwnsObjects: Boolean;
begin
  Result := FOwnsObjects;
end;

procedure TList<T>.SetOwnsObjects(Value: Boolean);
begin
  FOwnsObjects := Value;
end;

function TList<T>.GetCount: Integer;
begin
  Result := FCore.Count;
end;

function TList<T>.GetItem(Index: Integer): T;
begin
  Result := Default(T);
  FCore.GetRawItem(Index, @Result);
end;

procedure TList<T>.SetItem(Index: Integer; const Value: T);
var
  OldItem: T;
begin
  OldItem := GetItem(Index);
  FCore.SetRawItem(Index, @Value);
  Notify(Self, OldItem, cnRemoved);
  Notify(Self, Value, cnAdded);
end;

function TList<T>.GetEnumerator: IEnumerator<T>;
begin
  Result := TEnumerator<T>.Create(FCore);
end;

procedure TList<T>.Add(const Value: T);
begin
  FCore.AddRaw(@Value);
  Notify(Self, Value, cnAdded);
end;

procedure TList<T>.AddRange(const Values: IEnumerable<T>);
var
  Enum: IEnumerator<T>;
begin
  Enum := Values.GetEnumerator;
  while Enum.MoveNext do
    Add(Enum.Current);
end;

procedure TList<T>.AddRange(const Values: array of T);
var
  I: Integer;
begin
  if FCore.Capacity < FCore.Count + Length(Values) then
    FCore.Capacity := FCore.Count + Length(Values);
  for I := Low(Values) to High(Values) do
    Add(Values[I]);
end;

procedure TList<T>.Insert(Index: Integer; const Value: T);
begin
  FCore.InsertRaw(Index, @Value);
  Notify(Self, Value, cnAdded);
end;

function TList<T>.IndexOf(const Value: T): Integer;
var
  I: Integer;
  ItemPtr: Pointer;
begin
  for I := 0 to FCore.Count - 1 do
  begin
    ItemPtr := FCore.GetItemPtr(I);
    case GetTypeKind(T) of
      tkUString:
        if PString(ItemPtr)^ = PString(@Value)^ then Exit(I);
      tkClass, tkInterface:
        if PPointer(ItemPtr)^ = PPointer(@Value)^ then Exit(I);
      tkLString:
        if PAnsiString(ItemPtr)^ = PAnsiString(@Value)^ then Exit(I);
      tkWString:
        if PWideString(ItemPtr)^ = PWideString(@Value)^ then Exit(I);
      tkInteger, tkChar, tkEnumeration, tkSet, tkWChar:
        case SizeOf(T) of
          1: if PByte(ItemPtr)^ = PByte(@Value)^ then Exit(I);
          2: if PWord(ItemPtr)^ = PWord(@Value)^ then Exit(I);
          4: if PCardinal(ItemPtr)^ = PCardinal(@Value)^ then Exit(I);
          8: if PUInt64(ItemPtr)^ = PUInt64(@Value)^ then Exit(I);
        else
          if CompareMem(ItemPtr, @Value, SizeOf(T)) then Exit(I);
        end;
      tkFloat:
        case SizeOf(T) of
          4: if PSingle(ItemPtr)^ = PSingle(@Value)^ then Exit(I);
          8: if PDouble(ItemPtr)^ = PDouble(@Value)^ then Exit(I);
          10: if PExtended(ItemPtr)^ = PExtended(@Value)^ then Exit(I);
        else
          if CompareMem(ItemPtr, @Value, SizeOf(T)) then Exit(I);
        end;
      tkInt64:
        if PInt64(ItemPtr)^ = PInt64(@Value)^ then Exit(I);
    else
      if CompareMem(ItemPtr, @Value, SizeOf(T)) then Exit(I);
    end;
  end;
  Result := -1;
end;

function TList<T>.Contains(const Value: T): Boolean;
begin
  Result := IndexOf(Value) >= 0;
end;

function TList<T>.Remove(const Value: T): Boolean;
var
  Idx: Integer;
begin
  Idx := IndexOf(Value);
  if Idx >= 0 then
  begin
    RemoveAt(Idx);
    Result := True;
  end
  else
    Result := False;
end;

function TList<T>.Extract(const Value: T): T;
var
  Idx: Integer;
begin
  Idx := IndexOf(Value);
  if Idx >= 0 then
  begin
    Result := GetItem(Idx);
    // Delete from storage without freeing (notify as Extracted)
    FCore.DeleteRaw(Idx);
    Notify(Self, Result, cnExtracted);
  end
  else
    Result := Default(T);
end;

procedure TList<T>.Delete(Index: Integer);
begin
  RemoveAt(Index);
end;

procedure TList<T>.RemoveAt(Index: Integer);
var
  OldItem: T;
begin
  OldItem := GetItem(Index);
  FCore.DeleteRaw(Index);
  Notify(Self, OldItem, cnRemoved);
end;

procedure TList<T>.Clear;
var
  I: Integer;
  Item: T;
begin
  // Notify in reverse order before clearing storage
  for I := FCore.Count - 1 downto 0 do
  begin
    Item := GetItem(I);
    Notify(Self, Item, cnRemoved);
  end;
  FCore.Clear;
end;

// LINQ-like Implementation

function TList<T>.Where(const Predicate: TFunc<T, Boolean>): IList<T>;
var
  I: Integer;
  Item: T;
  NewList: IList<T>;
begin
  NewList := TCollections.CreateList<T>(False);
  Result := NewList;
  for I := 0 to FCore.Count - 1 do
  begin
    Item := GetItem(I);
    if Predicate(Item) then
      NewList.Add(Item);
  end;
end;

function TList<T>.Where(const Expression: IExpression): IList<T>;
var
  I: Integer;
  Item: T;
  NewList: IList<T>;
begin
  NewList := TCollections.CreateList<T>(False);
  Result := NewList;

  if PTypeInfo(System.TypeInfo(T)).Kind <> tkClass then
    raise Exception.Create('Expression evaluation is only supported for class types.');

  for I := 0 to FCore.Count - 1 do
  begin
    Item := GetItem(I);
    if TExpressionEvaluator.Evaluate(Expression, TObject(PPointer(@Item)^)) then
      NewList.Add(Item);
  end;
end;

function TList<T>.First: T;
begin
  if FCore.Count = 0 then
    raise Exception.Create('List is empty');
  Result := GetItem(0);
end;

function TList<T>.Last: T;
begin
  if FCore.Count = 0 then
    raise Exception.Create('List is empty');
  Result := GetItem(FCore.Count - 1);
end;

function TList<T>.First(const Expression: IExpression): T;
var
  I: Integer;
  Item: T;
begin
  if PTypeInfo(System.TypeInfo(T)).Kind <> tkClass then
    raise Exception.Create('Expression evaluation is only supported for class types.');

  for I := 0 to FCore.Count - 1 do
  begin
    Item := GetItem(I);
    if TExpressionEvaluator.Evaluate(Expression, TObject(PPointer(@Item)^)) then
      Exit(Item);
  end;
  raise Exception.Create('Sequence contains no matching element');
end;

function TList<T>.FirstOrDefault: T;
begin
  if FCore.Count = 0 then
    Result := Default(T)
  else
    Result := GetItem(0);
end;

function TList<T>.FirstOrDefault(const DefaultValue: T): T;
begin
  if FCore.Count = 0 then
    Result := DefaultValue
  else
    Result := GetItem(0);
end;

function TList<T>.FirstOrDefault(const Expression: IExpression): T;
var
  I: Integer;
  Item: T;
begin
  if PTypeInfo(System.TypeInfo(T)).Kind <> tkClass then
    raise Exception.Create('Expression evaluation is only supported for class types.');

  for I := 0 to FCore.Count - 1 do
  begin
    Item := GetItem(I);
    if TExpressionEvaluator.Evaluate(Expression, TObject(PPointer(@Item)^)) then
      Exit(Item);
  end;
  Result := Default(T);
end;

function TList<T>.Any(const Predicate: TFunc<T, Boolean>): Boolean;
var
  I: Integer;
begin
  for I := 0 to FCore.Count - 1 do
    if Predicate(GetItem(I)) then
      Exit(True);
  Result := False;
end;

function TList<T>.Any(const Expression: IExpression): Boolean;
var
  I: Integer;
  Item: T;
begin
  if PTypeInfo(System.TypeInfo(T)).Kind <> tkClass then
    raise Exception.Create('Expression evaluation is only supported for class types.');

  for I := 0 to FCore.Count - 1 do
  begin
    Item := GetItem(I);
    if TExpressionEvaluator.Evaluate(Expression, TObject(PPointer(@Item)^)) then
      Exit(True);
  end;
  Result := False;
end;

function TList<T>.Any: Boolean;
begin
  Result := FCore.Count > 0;
end;

function TList<T>.All(const Predicate: TFunc<T, Boolean>): Boolean;
var
  I: Integer;
begin
  for I := 0 to FCore.Count - 1 do
    if not Predicate(GetItem(I)) then
      Exit(False);
  Result := True;
end;

function TList<T>.All(const Expression: IExpression): Boolean;
var
  I: Integer;
  Item: T;
begin
  if PTypeInfo(System.TypeInfo(T)).Kind <> tkClass then
    raise Exception.Create('Expression evaluation is only supported for class types.');

  for I := 0 to FCore.Count - 1 do
  begin
    Item := GetItem(I);
    if not TExpressionEvaluator.Evaluate(Expression, TObject(PPointer(@Item)^)) then
      Exit(False);
  end;
  Result := True;
end;

procedure TList<T>.ForEach(const Action: TProc<T>);
var
  I: Integer;
begin
  for I := 0 to FCore.Count - 1 do
    Action(GetItem(I));
end;

procedure TList<T>.Sort(const AComparer: IComparer<T>);
type
  PT = ^T;
var
  Comparer: IComparer<T>;
begin
  if AComparer <> nil then
    Comparer := AComparer
  else
    Comparer := TComparer<T>.Default;

  FCore.SortRaw(
    function(A, B: Pointer): Integer
    begin
      Result := Comparer.Compare(PT(A)^, PT(B)^);
    end
  );
end;

function TList<T>.ToArray: TArray<T>;
begin
  SetLength(Result, FCore.Count);
  if FCore.Count > 0 then
    FCore.GetRawData(@Result[0]);
end;

{ TCollections }

class function TCollections.CreateList<T>(OwnsObjects: Boolean): IList<T>;
begin
  Result := TList<T>.Create(OwnsObjects);
end;

class function TCollections.CreateObjectList<T>(OwnsObjects: Boolean): IList<T>;
begin
  Result := TList<T>.Create(OwnsObjects);
end;

class function TCollections.CreateDictionary<K, V>(ACapacity: Integer): IDictionary<K, V>;
begin
  Result := TDictionary<K, V>.Create(ACapacity);
end;

class function TCollections.CreateDictionary<K, V>(AOwnsValues: Boolean; ACapacity: Integer): IDictionary<K, V>;
begin
  Result := TDictionary<K, V>.Create(AOwnsValues, ACapacity);
end;

class function TCollections.CreateStack<T>: IStack<T>;
begin
  Result := TStack<T>.Create;
end;

class function TCollections.CreateQueue<T>: IQueue<T>;
begin
  Result := TQueue<T>.Create;
end;

class function TCollections.CreateHashSet<T>: IHashSet<T>;
begin
  Result := THashSet<T>.Create;
end;

end.
