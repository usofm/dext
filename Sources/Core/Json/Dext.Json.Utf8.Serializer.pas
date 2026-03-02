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
{  Created: 2025-12-19                                                      }
{                                                                           }
{***************************************************************************}
unit Dext.Json.Utf8.Serializer;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  Dext.Collections,
  Dext.Collections.Dict,
  Dext.Collections.Vector,
  Dext.Core.Span,
  Dext.Json.Utf8,
  Dext.Core.DateUtils,
  Dext.Types.UUID;

type
  EUtf8SerializationException = class(Exception);

  PTUUID = ^TUUID;

  TJsonFieldInfo = record
    NameBytes: TBytes;
    Offset: Integer;
    TypeKind: TTypeKind;
    TypeInfo: PTypeInfo;
  end;

  TJsonRecordInfo = record
    Fields: TArray<TJsonFieldInfo>;
  end;

  TUtf8JsonSerializerCache = class
  public class var
    Cache: IDictionary<PTypeInfo, TJsonRecordInfo>;
    class constructor Create;
  end;

  TUtf8JsonSerializer = record
  private
    class function GetRecordInfo(AType: PTypeInfo): TJsonRecordInfo; static;
    class procedure DeserializeRecord(var AReader: TUtf8JsonReader; AType: PTypeInfo; AInstance: Pointer); static;
    class procedure DeserializeFieldDirect(var AReader: TUtf8JsonReader; const FieldInfo: TJsonFieldInfo; Instance: Pointer); static;
  public
    class function Deserialize<T>(const AData: TByteSpan): T; static;
  end;

implementation

{ TUtf8JsonSerializerCache }

class constructor TUtf8JsonSerializerCache.Create;
begin
  Cache := TCollections.CreateDictionary<PTypeInfo, TJsonRecordInfo>;
end;

{ TUtf8JsonSerializer }

class function TUtf8JsonSerializer.GetRecordInfo(AType: PTypeInfo): TJsonRecordInfo;
var
  Ctx: TRttiContext;
  RType: TRttiType;
  Field: TRttiField;
  FldInfo: TJsonFieldInfo;
  Fields: TVector<TJsonFieldInfo>;
begin
  if TUtf8JsonSerializerCache.Cache.TryGetValue(AType, Result) then
    Exit;

  Ctx := TRttiContext.Create;
  try
    RType := Ctx.GetType(AType);
    if RType = nil then Exit;

    for Field in RType.GetFields do
    begin
      FldInfo.NameBytes := TEncoding.UTF8.GetBytes(Field.Name);
      FldInfo.Offset := Field.Offset;
      if Field.FieldType <> nil then
      begin
        FldInfo.TypeKind := Field.FieldType.TypeKind;
        FldInfo.TypeInfo := Field.FieldType.Handle;
      end
      else
      begin
        FldInfo.TypeKind := tkUnknown;
        FldInfo.TypeInfo := nil;
      end;
      Fields.Add(FldInfo);
    end;

    Result.Fields := Fields.ToArray;
    TUtf8JsonSerializerCache.Cache.Add(AType, Result);
  finally
    Ctx.Free;
  end;
end;

class function TUtf8JsonSerializer.Deserialize<T>(const AData: TByteSpan): T;
var
  Reader: TUtf8JsonReader;
  TypeInfoInfo: PTypeInfo;
begin
  Reader := TUtf8JsonReader.Create(AData);
  TypeInfoInfo := System.TypeInfo(T);

  // Initial Read to get to the start
  if not Reader.Read then
    Exit(Default(T)); 

  if TypeInfoInfo.Kind = tkRecord then
  begin
    Result := Default(T);
    DeserializeRecord(Reader, TypeInfoInfo, @Result);
  end
  else
    raise EUtf8SerializationException.Create('Only Records are supported for zero-allocation deserialization currently.');
end;

class procedure TUtf8JsonSerializer.DeserializeRecord(var AReader: TUtf8JsonReader; AType: PTypeInfo; AInstance: Pointer);
var
  RecInfo: TJsonRecordInfo;
  I: Integer;
  Found: Boolean;
  ValSpan: TByteSpan;
begin
  if AReader.TokenType <> TJsonTokenType.StartObject then
   if AReader.TokenType <> TJsonTokenType.StartObject then
     raise EUtf8SerializationException.Create('Expected StartObject');

  RecInfo := GetRecordInfo(AType);

  while AReader.Read do
  begin
    if AReader.TokenType = TJsonTokenType.EndObject then
      Break;

    if AReader.TokenType = TJsonTokenType.PropertyName then
    begin
      ValSpan := AReader.ValueSpan;
      Found := False;
      
      for I := 0 to High(RecInfo.Fields) do
      begin
        if ValSpan.Equals(TByteSpan.FromBytes(RecInfo.Fields[I].NameBytes)) then
        begin
          if not AReader.Read then
            raise EUtf8SerializationException.Create('Unexpected end of JSON while reading value');
            
          DeserializeFieldDirect(AReader, RecInfo.Fields[I], AInstance);
          Found := True;
          Break;
        end;
      end;
      
      if not Found then
      begin
        // Advance to Value and Skip
        if AReader.Read then
          AReader.Skip;
      end;
    end;
  end;
end;

class procedure TUtf8JsonSerializer.DeserializeFieldDirect(var AReader: TUtf8JsonReader; const FieldInfo: TJsonFieldInfo; Instance: Pointer);
var
  P: Pointer;
begin
  P := Pointer(NativeUInt(Instance) + NativeUInt(FieldInfo.Offset));
  case FieldInfo.TypeKind of
    tkInteger:
      PInteger(P)^ := AReader.GetInt32;
      
    tkInt64:
      PInt64(P)^ := AReader.GetInt64;
      
    tkFloat:
      if (FieldInfo.TypeInfo = TypeInfo(TDateTime)) or 
         (FieldInfo.TypeInfo = TypeInfo(TDate)) or 
         (FieldInfo.TypeInfo = TypeInfo(TTime)) then
      begin
         var DateStr := AReader.GetString;
         var Dt: TDateTime;
         if TryParseCommonDate(DateStr, Dt) then
           PDateTime(P)^ := Dt
         else
           PDateTime(P)^ := 0;
      end
      else
        PDouble(P)^ := AReader.GetDouble;
      
    tkString, tkLString, tkWString, tkUString:
      PString(P)^ := AReader.GetString;
      
    tkEnumeration:
      if FieldInfo.TypeInfo = TypeInfo(Boolean) then
        PBoolean(P)^ := AReader.GetBoolean
      else
        AReader.Skip;
        
    tkRecord:
      begin
        if FieldInfo.TypeInfo = TypeInfo(TGUID) then
        begin
          var GuidStr := AReader.GetString;
          var G: TGUID;
          
          if GuidStr.Trim = '' then
            G := TGUID.Empty
          else if GuidStr.StartsWith('{') and GuidStr.EndsWith('}') then
            G := StringToGUID(GuidStr)
          else if GuidStr.Length = 36 then
            G := StringToGUID('{' + GuidStr + '}')
          else
            G := StringToGUID(GuidStr);
            
          PGUID(P)^ := G;
        end
        else if FieldInfo.TypeInfo = TypeInfo(TUUID) then
        begin
          var GuidStr := AReader.GetString;
          if GuidStr.Trim = '' then
            PTUUID(P)^ := TUUID.Null
          else
            PTUUID(P)^ := TUUID.FromString(GuidStr);
        end
        else
        begin
          AReader.Skip;
        end;
      end;
      
    else
      AReader.Skip;
  end;
end;

end.
