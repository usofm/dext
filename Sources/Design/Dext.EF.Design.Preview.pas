unit Dext.EF.Design.Preview;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.Grids,
  Vcl.DBGrids,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.DatS,
  FireDAC.Phys.Intf,
  FireDAC.DApt.Intf,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  Dext.Entity.DataSet,
  Dext.Entity.DataProvider,
  Dext.Entity.Dialects,
  Dext.Entity.Core;

type
  /// <summary>Data preview window for entities.</summary>
  TPreviewForm = class(TForm)
  private
    FPageControl: TPageControl;
    FTabData: TTabSheet;
    FTabSQL: TTabSheet;
    FGrid: TDBGrid;
    FSqlMemo: TMemo;
    FDataSource: TDataSource;
    FQuery: TFDQuery;
    FPanel: TPanel;
    FCloseBtn: TButton;
    procedure MemoFieldGetText(Sender: TField; var Text: string; DisplayText: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    /// <summary>Configures the preview query for the specified DataSet.</summary>
    procedure Preview(ADataSet: TEntityDataSet);
  end;

  /// <summary>Displays a modal window with a data preview of the entity bound to the DataSet.</summary>
procedure ShowEntityPreview(ADataSet: TEntityDataSet);

implementation

procedure ShowEntityPreview(ADataSet: TEntityDataSet);
var
  Form: TPreviewForm;
begin
  Form := TPreviewForm.Create(nil);
  try
    Form.Preview(ADataSet);
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

{ TPreviewForm }

constructor TPreviewForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'Dext Entity Preview';
  Width := 800;
  Height := 600;
  Position := poScreenCenter;
  
  FPanel := TPanel.Create(Self);
  FPanel.Parent := Self;
  FPanel.Align := alBottom;
  FPanel.Height := 50;
  FPanel.BevelOuter := bvNone;
  
  FCloseBtn := TButton.Create(Self);
  FCloseBtn.Parent := FPanel;
  FCloseBtn.Caption := 'Close';
  FCloseBtn.ModalResult := mrOk;
  FCloseBtn.Width := 90;
  FCloseBtn.Height := 30;
  FCloseBtn.Top := 10;
  FCloseBtn.Left := FPanel.Width - FCloseBtn.Width - 10;
  FCloseBtn.Anchors := [akRight, akTop];
  
  FPageControl := TPageControl.Create(Self);
  FPageControl.Parent := Self;
  FPageControl.Align := alClient;
  FPageControl.AlignWithMargins := True;
  
  FTabData := TTabSheet.Create(Self);
  FTabData.PageControl := FPageControl;
  FTabData.Caption := 'Data Preview';
  
  FTabSQL := TTabSheet.Create(Self);
  FTabSQL.PageControl := FPageControl;
  FTabSQL.Caption := 'SQL Command';

  FGrid := TDBGrid.Create(Self);
  FGrid.Parent := FTabData;
  FGrid.Align := alClient;
  FGrid.ReadOnly := True;
  
  FSqlMemo := TMemo.Create(Self);
  FSqlMemo.Parent := FTabSQL;
  FSqlMemo.Align := alClient;
  FSqlMemo.ReadOnly := True;
  FSqlMemo.ScrollBars := ssBoth;
  FSqlMemo.Font.Name := 'Consolas';
  FSqlMemo.Font.Size := 10;

  FDataSource := TDataSource.Create(Self);
  FGrid.DataSource := FDataSource;
  
  FQuery := TFDQuery.Create(Self);
  FDataSource.DataSet := FQuery;
end;

procedure TPreviewForm.Preview(ADataSet: TEntityDataSet);
var
  DP: IEntityDataProvider;
  MD: TEntityClassMetadata;
  SQL: string;
  I, J: Integer;
  Fld: TField;
  Member: TEntityMemberMetadata;
  TypeStr: string;
  Col: TColumn;
  SqlDialect: ISQLDialect;
begin
  if not Assigned(ADataSet.DataProvider) then
    raise Exception.Create('Provider is missing.');
    
  if not ADataSet.DataProvider.GetInterface(IEntityDataProvider, DP) then
    raise Exception.Create('Invalid Provider.');

  if ADataSet.EntityClassName = '' then
     raise Exception.Create('EntityClassName is missing.');

  MD := DP.GetEntityMetadata(ADataSet.EntityClassName);
  if MD = nil then
    raise Exception.Create('Entity metadata not found.');

  FQuery.Connection := ADataSet.DataProvider.DatabaseConnection;
  if FQuery.Connection = nil then
     raise Exception.Create('Connection is not assigned to Provider.');

  // Dynamic Schema Support: Ensure session context (search_path, USE, etc.) is set
  SqlDialect := TDialectFactory.CreateDialect(TDialectFactory.DetectDialect(FQuery.Connection.DriverName));
  if SqlDialect <> nil then
  begin
    SQL := FQuery.Connection.Params.Values['Schema'];
    if SQL = '' then SQL := FQuery.Connection.Params.Values['MetaCurSchema'];
    if SQL = '' then SQL := FQuery.Connection.Params.Values['MetaDefSchema'];

    if SQL <> '' then
    begin
      SQL := SqlDialect.GetSetSchemaSQL(SQL);
      if SQL <> '' then
        FQuery.Connection.ExecSQL(SQL);
    end;
  end;

  SQL := DP.BuildPreviewSql(ADataSet.EntityClassName, 50);
  if SQL = '' then
    SQL := 'SELECT * FROM ' + MD.TableName;

  FSqlMemo.Lines.Text := SQL;
  FQuery.SQL.Text := SQL;
  FQuery.Open;
  
  for I := 0 to FQuery.Fields.Count - 1 do
  begin
    Fld := FQuery.Fields[I];
    if (Fld.DataType = ftMemo) or (Fld.DataType = ftWideMemo) then
      Fld.OnGetText := MemoFieldGetText;

    // H.3: Visualização de Tipos no Preview
    for J := 0 to MD.Members.Count - 1 do
    begin
      Member := MD.Members[J];
      if SameText(Member.Name, Fld.FieldName) or SameText(Member.Name, Fld.Origin) then
      begin
        TypeStr := Member.MemberType;
        if Member.MaxLength > 0 then
          TypeStr := TypeStr + '(' + Member.MaxLength.ToString + ')';
        if Member.Precision > 0 then
          TypeStr := TypeStr + '(' + Member.Precision.ToString + ')';
          
        Fld.DisplayLabel := Format('%s [%s]', [Fld.FieldName, TypeStr.ToUpper]);
        Break;
      end;
    end;
  end;

  // Auto-ajuste básico de larguras de colunas
  for I := 0 to FGrid.Columns.Count - 1 do
  begin
    Col := FGrid.Columns[I];
    if Col.Field.DataType in [ftString, ftWideString, ftWideMemo, ftMemo] then
      Col.Width := 250
    else if Col.Field.DataType in [ftInteger, ftLargeint, ftFloat, ftCurrency] then
      Col.Width := 80
    else
      Col.Width := 120;
  end;
  
  Caption := 'Previewing: ' + MD.EntityClassName + ' (Table: ' + MD.TableName + ')';
end;

procedure TPreviewForm.MemoFieldGetText(Sender: TField; var Text: string;
  DisplayText: Boolean);
begin
  if not Sender.IsNull then
    Text := Sender.AsString
  else
    Text := '';
end;

end.
