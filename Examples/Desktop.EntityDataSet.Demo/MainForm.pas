unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.DBCtrls, Vcl.Grids,
  Vcl.DBGrids, Data.DB, Dext.Entity.DataSet, Dext.Entity.Attributes, Vcl.Buttons,
  Dext.Collections;

type
  [Table('products')]
  TProduct = class
  private
    FId: Integer;
    FDescription: string;
    FPrice: Double;
  public
    constructor Create(Id: Integer; const Description: string; Price: Double);

    [PK, AutoInc]
    property Id: Integer read FId write FId;
    property Description: string read FDescription write FDescription;
    property Price: Double read FPrice write FPrice;
  end;

  TFormMain = class(TForm)
    PanelTop: TPanel;
    DBGridProducts: TDBGrid;
    DBNavigator: TDBNavigator;
    DataSource: TDataSource;
    EntityDataSet: TEntityDataSet;
    procedure FormCreate(Sender: TObject);
  private
    FDataSet: TEntityDataSet;
    FProducts: IList<TProduct>;
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

procedure TFormMain.FormCreate(Sender: TObject);
begin
  FDataSet := TEntityDataSet.Create(Self);
  DataSource.DataSet := FDataSet;
  DBGridProducts.DataSource := DataSource;

  FProducts := TCollections.CreateList<TProduct>(True);

  for var i := 0 to 99 do
  begin
    FProducts.Add(TProduct.Create(
      100 + i, {Id}
      'Product ' + IntToStr(i + 1), {Description}
      100.0 * (i + 1) {Price}
    ));
  end;

  // Carregando dados no DataSet
  // TODO
  // FDataSet.Items := FProducts;
end;

{ TProduct }

constructor TProduct.Create(Id: Integer; const Description: string; Price: Double);
begin
  inherited Create;
  FId := Id;
  FDescription := Description;
  FPrice := Price;
end;

end.
