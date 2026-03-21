unit Dext.Entity.DataSet.Tests;

interface

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  Dext.Assertions,
  Dext.Testing.Attributes,
  Dext.Entity.DataSet,
  Dext.Core.SmartTypes,
  Dext.Types.Nullable,
  Dext.Types.Lazy,
  Dext.Entity;

type
  TSmartProduct = class
  private
    FID: IntType;
    FName: StringType;
    FPrice: Prop<Double>;
    FQuantity: Nullable<Integer>;
    FActive: BoolType;
    FDescription: Lazy<string>;
  public
    property ID: IntType read FID write FID;
    property Name: StringType read FName write FName;
    property Price: Prop<Double> read FPrice write FPrice;
    property Quantity: Nullable<Integer> read FQuantity write FQuantity;
    property Active: BoolType read FActive write FActive;
    property Description: Lazy<string> read FDescription write FDescription;
  end;

  [TestFixture('TEntityDataSet SmartTypes Support Tests')]
  TDataSetSmartTypesTests = class
  public
    [Test]
    procedure Test_Read_SmartTypes;
    
    [Test]
    procedure Test_Read_Nullable_Empty;

    [Test]
    procedure Test_Read_Lazy_Value;
  end;

implementation

{ TDataSetSmartTypesTests }

procedure TDataSetSmartTypesTests.Test_Read_SmartTypes;
var
  DataSet: TEntityDataSet;
  Product: TSmartProduct;
begin
  Product := TSmartProduct.Create;
  try
    Product.ID := 1;
    Product.Name := 'Smart Watch';
    Product.Price := 299.90;
    Product.Quantity := 10;
    Product.Active := True;

    DataSet := TEntityDataSet.Create(nil);
    DataSet.Load(TArray<TObject>.Create(Product), TSmartProduct);
    try
      DataSet.Open;

      Should(DataSet.FieldByName('ID').AsInteger).Be(1);
      Should(DataSet.FieldByName('Name').AsString).Be('Smart Watch');
      Should(DataSet.FieldByName('Price').AsFloat).Be(299.90);
      Should(DataSet.FieldByName('Quantity').AsInteger).Be(10);
      Should(DataSet.FieldByName('Active').AsBoolean).BeTrue;
    finally
      DataSet.Free;
    end;
  finally
    Product.Free;
  end;
end;

procedure TDataSetSmartTypesTests.Test_Read_Nullable_Empty;
var
  DataSet: TEntityDataSet;
  Product: TSmartProduct;
begin
  Product := TSmartProduct.Create;
  try
    Product.ID := 2;
    Product.Name := 'Incomplete Product';
    Product.Price := 0;
    Product.Quantity.Clear; // Null
    Product.Active := False;

    DataSet := TEntityDataSet.Create(nil);
    try
      DataSet.Load(TArray<TObject>.Create(Product), TSmartProduct);
      DataSet.Open;

      Should(DataSet.FieldByName('Quantity').IsNull).BeTrue;
    finally
      DataSet.Free;
    end;
  finally
    Product.Free;
  end;
end;

procedure TDataSetSmartTypesTests.Test_Read_Lazy_Value;
var
  DataSet: TEntityDataSet;
  Product: TSmartProduct;
begin
  Product := TSmartProduct.Create;
  try
    Product.ID := 3;
    Product.Name := 'Lazy Product';
    Product.Description := 'Long description here'; // Automatic implicit conversion to Lazy<string>

    DataSet := TEntityDataSet.Create(nil);
    try
      DataSet.Load(TArray<TObject>.Create(Product), TSmartProduct);
      DataSet.Open;

      Should(DataSet.FieldByName('Description').AsString).Be('Long description here');
    finally
      DataSet.Free;
    end;
  finally
    Product.Free;
  end;
end;

end.
