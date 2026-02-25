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
{  Created: 2026-02-25                                                      }
{                                                                           }
{  Dext-native comparer interfaces and default implementations.             }
{  Replaces System.Generics.Defaults with zero RTL generics dependency.     }
{                                                                           }
{  Design Notes:                                                            }
{  - Uses GetTypeKind(T) compiler intrinsic for compile-time branch         }
{    elimination, ensuring zero overhead for known types.                   }
{  - BobJenkins hash for consistent, high-quality hash codes.               }
{  - Currency type is correctly handled as fixed-point (Int64-based),       }
{    not as Double.                                                         }
{                                                                           }
{***************************************************************************}
unit Dext.Collections.Comparers;

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Hash;

type
  TComparison<T> = reference to function(const Left, Right: T): Integer;

  /// <summary>
  ///   Generic comparer interface for ordering comparison.
  ///   Returns negative if Left &lt; Right, zero if equal, positive if Left &gt; Right.
  /// </summary>
  IComparer<T> = interface
    function Compare(const Left, Right: T): Integer;
  end;

  /// <summary>
  ///   Generic equality comparer interface.
  ///   Provides equality comparison and hash code generation.
  /// </summary>
  IEqualityComparer<T> = interface
    function Equals(const Left, Right: T): Boolean;
    function GetHashCode(const Value: T): Integer;
  end;

  /// <summary>
  ///   Default ordering comparer.
  ///   Uses GetTypeKind for compile-time specialization per type kind.
  /// </summary>
  TDefaultComparer<T> = class(TInterfacedObject, IComparer<T>)
  public
    function Compare(const Left, Right: T): Integer;
  end;

  /// <summary>
  ///   Default equality comparer.
  ///   Uses GetTypeKind for compile-time specialization and BobJenkins hash.
  /// </summary>
  TDefaultEqualityComparer<T> = class(TInterfacedObject, IEqualityComparer<T>)
  public
    function Equals(const Left, Right: T): Boolean; reintroduce;
    function GetHashCode(const Value: T): Integer; reintroduce;
  end;

  /// <summary>
  ///   Factory for creating IComparer&lt;T&gt; instances.
  ///   Usage: TComparer&lt;string&gt;.Default
  /// </summary>
  TComparer<T> = class
  public
    class function Default: IComparer<T>; static;
    class function Construct(const AComparison: TComparison<T>): IComparer<T>; static;
  end;

  TComparisonComparer<T> = class(TInterfacedObject, IComparer<T>)
  private
    FComparison: TComparison<T>;
  public
    constructor Create(const AComparison: TComparison<T>);
    function Compare(const Left, Right: T): Integer;
  end;

  /// <summary>
  ///   Factory for creating IEqualityComparer&lt;T&gt; instances.
  ///   Usage: TEqualityComparer&lt;string&gt;.Default
  /// </summary>
  TEqualityComparer<T> = class
  public
    class function Default: IEqualityComparer<T>; static;
  end;

/// <summary>Byte-level ordering comparison for generic fallback</summary>
function BinaryCompare(Left, Right: Pointer; Size: Integer): Integer;

implementation

{ BinaryCompare }

function BinaryCompare(Left, Right: Pointer; Size: Integer): Integer;
var
  I: Integer;
  LB, RB: Byte;
begin
  for I := 0 to Size - 1 do
  begin
    LB := PByte(NativeUInt(Left) + NativeUInt(I))^;
    RB := PByte(NativeUInt(Right) + NativeUInt(I))^;
    if LB < RB then Exit(-1);
    if LB > RB then Exit(1);
  end;
  Result := 0;
end;

{ TDefaultComparer<T> }

function TDefaultComparer<T>.Compare(const Left, Right: T): Integer;
begin
  case GetTypeKind(T) of
    tkUString:
    begin
      Result := CompareStr(PString(@Left)^, PString(@Right)^);
    end;

    tkLString:
    begin
      if PAnsiString(@Left)^ < PAnsiString(@Right)^ then Result := -1
      else if PAnsiString(@Left)^ > PAnsiString(@Right)^ then Result := 1
      else Result := 0;
    end;

    tkWString:
    begin
      if PWideString(@Left)^ < PWideString(@Right)^ then Result := -1
      else if PWideString(@Left)^ > PWideString(@Right)^ then Result := 1
      else Result := 0;
    end;

    tkInteger, tkChar, tkEnumeration, tkSet, tkWChar:
    begin
      case SizeOf(T) of
        1:
          if PByte(@Left)^ < PByte(@Right)^ then Result := -1
          else if PByte(@Left)^ > PByte(@Right)^ then Result := 1
          else Result := 0;
        2:
          if PWord(@Left)^ < PWord(@Right)^ then Result := -1
          else if PWord(@Left)^ > PWord(@Right)^ then Result := 1
          else Result := 0;
        4:
          if PCardinal(@Left)^ < PCardinal(@Right)^ then Result := -1
          else if PCardinal(@Left)^ > PCardinal(@Right)^ then Result := 1
          else Result := 0;
        8:
          if PUInt64(@Left)^ < PUInt64(@Right)^ then Result := -1
          else if PUInt64(@Left)^ > PUInt64(@Right)^ then Result := 1
          else Result := 0;
      else
        Result := BinaryCompare(@Left, @Right, SizeOf(T));
      end;
    end;

    tkFloat:
    begin
      case SizeOf(T) of
        4: // Single
          if PSingle(@Left)^ < PSingle(@Right)^ then Result := -1
          else if PSingle(@Left)^ > PSingle(@Right)^ then Result := 1
          else Result := 0;
        8: // Double or Currency
          if TypeInfo(T) = TypeInfo(Currency) then
          begin
            if PCurrency(@Left)^ < PCurrency(@Right)^ then Result := -1
            else if PCurrency(@Left)^ > PCurrency(@Right)^ then Result := 1
            else Result := 0;
          end
          else
          begin
            if PDouble(@Left)^ < PDouble(@Right)^ then Result := -1
            else if PDouble(@Left)^ > PDouble(@Right)^ then Result := 1
            else Result := 0;
          end;
        10: // Extended
          if PExtended(@Left)^ < PExtended(@Right)^ then Result := -1
          else if PExtended(@Left)^ > PExtended(@Right)^ then Result := 1
          else Result := 0;
      else
        Result := BinaryCompare(@Left, @Right, SizeOf(T));
      end;
    end;

    tkInt64:
    begin
      if PInt64(@Left)^ < PInt64(@Right)^ then Result := -1
      else if PInt64(@Left)^ > PInt64(@Right)^ then Result := 1
      else Result := 0;
    end;

    tkClass, tkInterface:
    begin
      if NativeUInt(PPointer(@Left)^) < NativeUInt(PPointer(@Right)^) then Result := -1
      else if NativeUInt(PPointer(@Left)^) > NativeUInt(PPointer(@Right)^) then Result := 1
      else Result := 0;
    end;
  else
    // Records, variants, and other types: byte-level comparison
    Result := BinaryCompare(@Left, @Right, SizeOf(T));
  end;
end;

{ TDefaultEqualityComparer<T> }

function TDefaultEqualityComparer<T>.Equals(const Left, Right: T): Boolean;
begin
  case GetTypeKind(T) of
    tkUString:
      Result := PString(@Left)^ = PString(@Right)^;
    tkLString:
      Result := PAnsiString(@Left)^ = PAnsiString(@Right)^;
    tkWString:
      Result := PWideString(@Left)^ = PWideString(@Right)^;
    tkInteger, tkChar, tkEnumeration, tkSet, tkWChar:
      case SizeOf(T) of
        1: Result := PByte(@Left)^ = PByte(@Right)^;
        2: Result := PWord(@Left)^ = PWord(@Right)^;
        4: Result := PCardinal(@Left)^ = PCardinal(@Right)^;
        8: Result := PUInt64(@Left)^ = PUInt64(@Right)^;
      else
        Result := CompareMem(@Left, @Right, SizeOf(T));
      end;
    tkFloat:
      case SizeOf(T) of
        4: Result := PSingle(@Left)^ = PSingle(@Right)^;
        8:
          if TypeInfo(T) = TypeInfo(Currency) then
            Result := PCurrency(@Left)^ = PCurrency(@Right)^
          else
            Result := PDouble(@Left)^ = PDouble(@Right)^;
        10: Result := PExtended(@Left)^ = PExtended(@Right)^;
      else
        Result := CompareMem(@Left, @Right, SizeOf(T));
      end;
    tkInt64:
      Result := PInt64(@Left)^ = PInt64(@Right)^;
    tkClass, tkInterface:
      Result := PPointer(@Left)^ = PPointer(@Right)^;
  else
    Result := CompareMem(@Left, @Right, SizeOf(T));
  end;
end;

function TDefaultEqualityComparer<T>.GetHashCode(const Value: T): Integer;
begin
  case GetTypeKind(T) of
    tkUString:
      Result := THashBobJenkins.GetHashValue(PString(@Value)^);
    tkLString:
      Result := THashBobJenkins.GetHashValue(string(PAnsiString(@Value)^));
    tkWString:
      Result := THashBobJenkins.GetHashValue(string(PWideString(@Value)^));
    tkClass:
      Result := THashBobJenkins.GetHashValue(PPointer(@Value)^, SizeOf(Pointer));
    tkInterface:
      Result := THashBobJenkins.GetHashValue(PPointer(@Value)^, SizeOf(Pointer));
  else
    // Integer, Float, Int64, Enum, Set, Record, etc: hash raw bytes
    Result := THashBobJenkins.GetHashValue(Value, SizeOf(T));
  end;
end;

{ TComparer<T> }

class function TComparer<T>.Default: IComparer<T>;
begin
  Result := TDefaultComparer<T>.Create;
end;

class function TComparer<T>.Construct(const AComparison: TComparison<T>): IComparer<T>;
begin
  Result := TComparisonComparer<T>.Create(AComparison);
end;

{ TComparisonComparer<T> }

constructor TComparisonComparer<T>.Create(const AComparison: TComparison<T>);
begin
  inherited Create;
  FComparison := AComparison;
end;

function TComparisonComparer<T>.Compare(const Left, Right: T): Integer;
begin
  Result := FComparison(Left, Right);
end;

{ TEqualityComparer<T> }

class function TEqualityComparer<T>.Default: IEqualityComparer<T>;
begin
  Result := TDefaultEqualityComparer<T>.Create;
end;

end.
