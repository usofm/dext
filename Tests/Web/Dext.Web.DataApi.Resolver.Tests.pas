{***************************************************************************}
{                                                                           }
{           Dext Framework                                                  }
{           Copyright (C) 2025 Cesar Romero & Dext Contributors             }
{                                                                           }
{***************************************************************************}

unit Dext.Web.DataApi.Resolver.Tests;

interface

uses
  Dext.Testing,
  System.SysUtils,
  System.Variants,
  System.TypInfo,
  Dext.Entity.Mapping,
  Dext.Web.ModelBinding,
  Dext.Web.DataApi.Resolver,
  Dext.Types.UUID;

type
  [TestClass]
  TEntityIdResolverTests = class
  private
    FBinder: IModelBinder;
    function CreateSimpleMap(APKType: PTypeInfo): TEntityMap;
    function CreateCompositeMap: TEntityMap;
  public
    [Setup]
    procedure Setup;
    
    [Test]
    procedure Test_Resolve_Integer;
    
    [Test]
    procedure Test_Resolve_UUID;
    
    [Test]
    procedure Test_Resolve_String;
    
    [Test]
    procedure Test_Resolve_Composite;

    [Test]
    procedure Test_Resolve_InvalidComposite_Format;
  end;

  TIntegerEntity = class
  private
    FId: Integer;
  public
    property Id: Integer read FId write FId;
  end;

  TUUIDEntity = class
  private
    FId: TUUID;
  public
    property Id: TUUID read FId write FId;
  end;

  TStringEntity = class
  private
    FId: string;
  public
    property Id: string read FId write FId;
  end;

  TCompositeEntity = class
  private
    FOrderId: Integer;
    FItemNo: Integer;
  public
    property OrderId: Integer read FOrderId write FOrderId;
    property ItemNo: Integer read FItemNo write FItemNo;
  end;

implementation

uses
  System.Rtti;

{ TEntityIdResolverTests }

procedure TEntityIdResolverTests.Setup;
begin
  FBinder := TModelBinder.Create;
end;

function TEntityIdResolverTests.CreateSimpleMap(APKType: PTypeInfo): TEntityMap;
var
  Prop: TRttiProperty;
  Ctx: TRttiContext;
  PMap: TPropertyMap;
begin
  Result := TEntityMap.Create(nil); 
  Prop := Ctx.GetType(APKType).GetProperty('Id');
  PMap := TPropertyMap.Create(Prop.Name);
  PMap.Prop := Prop;
  PMap.IsPK := True;
  Result.Properties.Add(Prop.Name, PMap);
  Result.Keys.Add(Prop.Name);
end;

function TEntityIdResolverTests.CreateCompositeMap: TEntityMap;
var
  Ctx: TRttiContext;
  T: TRttiType;
  Prop: TRttiProperty;
  PMap1, PMap2: TPropertyMap;
begin
  Result := TEntityMap.Create(nil);
  T := Ctx.GetType(TCompositeEntity);
  
  Prop := T.GetProperty('OrderId');
  PMap1 := TPropertyMap.Create(Prop.Name);
  PMap1.Prop := Prop;
  PMap1.IsPK := True;
  Result.Properties.Add(Prop.Name, PMap1);
  Result.Keys.Add(Prop.Name);

  Prop := T.GetProperty('ItemNo');
  PMap2 := TPropertyMap.Create(Prop.Name);
  PMap2.Prop := Prop;
  PMap2.IsPK := True;
  Result.Properties.Add(Prop.Name, PMap2);
  Result.Keys.Add(Prop.Name);
end;

procedure TEntityIdResolverTests.Test_Resolve_Integer;
var
  Map: TEntityMap;
  Val: Variant;
begin
  Map := CreateSimpleMap(TypeInfo(TIntegerEntity));
  try
    Val := TEntityIdResolver.Resolve(Map, '123', FBinder);
    Should(Integer(Val)).Be(123);
  finally
    Map.Free;
  end;
end;

procedure TEntityIdResolverTests.Test_Resolve_String;
var
  Map: TEntityMap;
  Val: Variant;
begin
  Map := CreateSimpleMap(TypeInfo(TStringEntity));
  try
    Val := TEntityIdResolver.Resolve(Map, 'Slug-Key', FBinder);
    Should(string(Val)).Be('Slug-Key');
  finally
    Map.Free;
  end;
end;

procedure TEntityIdResolverTests.Test_Resolve_UUID;
var
  Map: TEntityMap;
  Val: Variant;
  IdStr: string;
begin
  IdStr := '550e8400-e29b-41d4-a716-446655440000';
  Map := CreateSimpleMap(TypeInfo(TUUIDEntity));
  try
    Val := TEntityIdResolver.Resolve(Map, IdStr, FBinder);
    // TUUID has implicit conversion to/from string, 
    // and custom records in Variants often fall back to strings/vStrings.
    Should(string(Val)).Be(IdStr);
  finally
    Map.Free;
  end;
end;

procedure TEntityIdResolverTests.Test_Resolve_Composite;
var
  Map: TEntityMap;
  Val: Variant;
begin
  Map := CreateCompositeMap;
  try
    Val := TEntityIdResolver.Resolve(Map, '10|50', FBinder);
    
    Should(VarIsArray(Val)).BeTrue;
    Should(Integer(Val[0])).Be(10);
    Should(Integer(Val[1])).Be(50);
  finally
    Map.Free;
  end;
end;

procedure TEntityIdResolverTests.Test_Resolve_InvalidComposite_Format;
var
  Map: TEntityMap;
begin
  Map := CreateCompositeMap;
  try
    Should(procedure
      begin
        TEntityIdResolver.Resolve(Map, '10', FBinder);
      end).Throw<EConvertError>;
  finally
    Map.Free;
  end;
end;

end.
