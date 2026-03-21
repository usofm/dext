unit Dext.Entity.FluentMapping.Tests;

interface

uses
  Dext.Test,
  Dext.Entity,
  Dext.Entity.Mapping,
  Dext.Entity.Dialects,
  Dext.Mocks,
  Dext.Core.SmartTypes,
  Dext.Types.Lazy,
  FireDAC.Comp.Client;

type
  TFluentOrder = class
  private
    FId: Integer;
    FDescription: String;
    FCreator: String;
    FVersion: Integer;
    FCreatedAt: TDateTime;
    FCustomer: Lazy<TObject>;
  public
    property Id: Integer read FId write FId;
    property Description: String read FDescription write FDescription;
    property Creator: String read FCreator write FCreator;
    property Version: Integer read FVersion write FVersion;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    property Customer: Lazy<TObject> read FCustomer write FCustomer;
  end;

  TFluentMappingConfig = class(TEntityTypeConfiguration<TFluentOrder>)
  public
    procedure Configure(Builder: IEntityTypeBuilder<TFluentOrder>); override;
  end;

  [TestFixture]
  TFluentMappingTests = class
  public
    [Test]
    procedure Test_Complex_Fluent_Mapping;
  end;

implementation

uses
  System.SysUtils,
  System.Rtti,
  Dext.Entity.Drivers.FireDAC,
  Dext.Specifications.Interfaces;

{ TFluentMappingConfig }

procedure TFluentMappingConfig.Configure(Builder: IEntityTypeBuilder<TFluentOrder>);
begin
  Builder.ToTable('Orders');
  Builder.HasKey('Id');
  
  Builder.Prop('Description').HasColumnName('Desc');
  Builder.Prop('Version').IsVersion;
  Builder.Prop('CreatedAt').IsCreatedAt;
  Builder.Prop('Customer').IsLazy;
end;

{ TFluentMappingTests }

procedure TFluentMappingTests.Test_Complex_Fluent_Mapping;
var
  LConn: TFDConnection;
  LDextConn: IDbConnection;
  Ctx: TDbContext;
  DbSet: IDbSet<TFluentOrder>;
  MockDbSet: TMock<IDbSet<TFluentOrder>>;
  LExpr: IExpression;
begin
  LConn := TFDConnection.Create(nil);
  LConn.Params.DriverID := 'SQLite';
  LConn.Params.Database := ':memory:';
    
  LDextConn := TFireDACConnection.Create(LConn, True);
  Ctx := TDbContext.Create(LDextConn, TSQLiteDialect.Create);
  try
    // Register mapping
    Ctx.ModelBuilder.AddConfiguration<TFluentOrder>(TFluentMappingConfig.Create);
    
    // Setup Schema (Creates tables based on mapping)
    Ctx.ExecuteSchemaSetup;
    
    DbSet := Ctx.Entities<TFluentOrder>;
    Assert.IsNotNull(DbSet, 'DbSet should not be null');
    
    // Test Mocking - using a more explicit approach to avoid E2035 if overloads are confusing the compiler
    MockDbSet := TMock<IDbSet<TFluentOrder>>.Create;
    try
        LExpr := nil;
        // Mocking the Count function
        MockDbSet.Setup.Count(It.IsAny<IExpression>).Returns(TValue.From<Integer>(100));
        
        Assert.AreEqual(100, MockDbSet.Instance.Count(LExpr));
    finally
        MockDbSet.Free;
    end;
  finally
    Ctx.Free;
  end;
end;

initialization
  TTestRunner.Register(TFluentMappingTests);

end.
