unit Dext.EF.Design.Scaffolding.Preview;

interface

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.UITypes,
  ToolsAPI,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Dext.Entity.Scaffolding,
  Dext.Scaffolding.Models,
  Dext.Entity.TemplatedScaffolding;

type
  TScaffoldingPreviewForm = class(TForm)
  private
    FPanelTop: TPanel;
    FPanelBottom: TPanel;
    FMemoCode: TMemo;
    FBtnCreate: TButton;
    FBtnCancel: TButton;
    FEditUnitName: TEdit;
    FEditPath: TEdit;
    FBtnPath: TButton;
    FCmbStyle: TComboBox;
    FChkSaveToDisk: TCheckBox;
    FStatsLabel: TLabel;
    
    FMeta: TArray<TMetaTable>;
    FGeneratedCode: string;
    
    procedure RebuildCode;
    procedure OnUnitNameChange(Sender: TObject);
    procedure OnStyleChange(Sender: TObject);
    procedure OnPathClick(Sender: TObject);
    procedure OnCreateClick(Sender: TObject);
    procedure OnSaveToDiskChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure ShowPreview(const AMeta: TArray<TMetaTable>; const ASuggestedPath: string); overload;
    function ShowPreviewModal(const AMeta: TArray<TMetaTable>; const ASuggestedPath: string): Boolean;
  end;

function ShowScaffoldingPreview(const AMeta: TArray<TMetaTable>; const ASuggestedPath: string): Boolean;

implementation

uses
  Vcl.FileCtrl;

function ShowScaffoldingPreview(const AMeta: TArray<TMetaTable>; const ASuggestedPath: string): Boolean;
var
  Form: TScaffoldingPreviewForm;
begin
  Result := False;
  Form := TScaffoldingPreviewForm.Create(nil);
  try
    Form.ShowPreview(AMeta, ASuggestedPath);
    if Form.ShowModal = mrOk then
      Result := True;
  finally
    Form.Free;
  end;
end;

type
  TOTAFile = class(TInterfacedObject, IOTAFile)
  private
    FSource: string;
  public
    constructor Create(const ASource: string);
    function GetSource: string;
    function GetAge: TDateTime;
  end;

  TEntityUnitCreator = class(TInterfacedObject, IOTACreator, IOTAModuleCreator)
  private
    FContent: string;
    FUnitName: string;
    FFullFileName: string;
    FIsUnnamed: Boolean;
  public
    constructor Create(const AContent, AUnitName, AFullFileName: string; AIsUnnamed: Boolean);
    // IOTACreator
    function GetCreatorType: string;
    function GetExisting: Boolean;
    function GetFileSystem: string;
    function GetOwner: IOTAModule;
    function GetUnnamed: Boolean;
    // IOTAModuleCreator
    function GetAncestorName: string;
    function GetImplFileName: string;
    function GetIntfFileName: string;
    function GetFormName: string;
    function GetMainForm: Boolean;
    function GetShowForm: Boolean;
    function GetShowSource: Boolean;
    function NewFormFile(const FormIdent, AncestorIdent: string): IOTAFile;
    function NewImplFile(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
    function NewIntfFile(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
    function NewImplSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
    function NewIntfSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
    procedure FormCreated(const FormEditor: IOTAFormEditor);
  end;

{ TOTAFile }

constructor TOTAFile.Create(const ASource: string);
begin
  inherited Create;
  FSource := ASource;
end;

function TOTAFile.GetAge: TDateTime;
begin
  Result := -1;
end;

function TOTAFile.GetSource: string;
begin
  Result := FSource;
end;

{ TEntityUnitCreator }

constructor TEntityUnitCreator.Create(const AContent, AUnitName, AFullFileName: string; AIsUnnamed: Boolean);
begin
  inherited Create;
  FContent := AContent;
  FUnitName := AUnitName;
  FFullFileName := AFullFileName;
  FIsUnnamed := AIsUnnamed;
end;

procedure TEntityUnitCreator.FormCreated(const FormEditor: IOTAFormEditor);
begin
end;

function TEntityUnitCreator.GetAncestorName: string;
begin
  Result := '';
end;

function TEntityUnitCreator.GetCreatorType: string;
begin
  Result := sUnit;
end;

function TEntityUnitCreator.GetExisting: Boolean;
begin
  Result := False;
end;

function TEntityUnitCreator.GetFileSystem: string;
begin
  Result := '';
end;

function TEntityUnitCreator.GetFormName: string;
begin
  Result := '';
end;

function TEntityUnitCreator.GetImplFileName: string;
begin
  Result := FFullFileName;
end;

function TEntityUnitCreator.GetIntfFileName: string;
begin
  Result := '';
end;

function TEntityUnitCreator.GetMainForm: Boolean;
begin
  Result := False;
end;

function TEntityUnitCreator.GetOwner: IOTAModule;
var
  ModuleServices: IOTAModuleServices;
begin
  Result := nil;
  if Supports(BorlandIDEServices, IOTAModuleServices, ModuleServices) then
    Result := ModuleServices.GetActiveProject;
end;

function TEntityUnitCreator.GetShowForm: Boolean;
begin
  Result := False;
end;

function TEntityUnitCreator.GetShowSource: Boolean;
begin
  Result := True;
end;

function TEntityUnitCreator.GetUnnamed: Boolean;
begin
  Result := FIsUnnamed;
end;

function TEntityUnitCreator.NewFormFile(const FormIdent,
  AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

function TEntityUnitCreator.NewImplFile(const ModuleIdent, FormIdent,
  AncestorIdent: string): IOTAFile;
begin
  Result := TOTAFile.Create(FContent);
end;

function TEntityUnitCreator.NewIntfFile(const ModuleIdent, FormIdent,
  AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

function TEntityUnitCreator.NewImplSource(const ModuleIdent, FormIdent,
  AncestorIdent: string): IOTAFile;
begin
  Result := TOTAFile.Create(FContent);
end;

function TEntityUnitCreator.NewIntfSource(const ModuleIdent, FormIdent,
  AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

{ TScaffoldingPreviewForm }

constructor TScaffoldingPreviewForm.Create(AOwner: TComponent);
var
  Lbl: TLabel;
begin
  inherited CreateNew(AOwner);
  Caption := 'Dext: Scaffolding Preview';
  Width := 900;
  Height := 700;
  Position := poScreenCenter;
  
  FPanelTop := TPanel.Create(Self);
  FPanelTop.Parent := Self;
  FPanelTop.Align := alTop;
  FPanelTop.Height := 100;
  FPanelTop.BevelOuter := bvNone;
  
  // Unit Name
  Lbl := TLabel.Create(Self);
  Lbl.Parent := FPanelTop;
  Lbl.Caption := 'Unit Name:';
  Lbl.Left := 10;
  Lbl.Top := 15;
  
  FEditUnitName := TEdit.Create(Self);
  FEditUnitName.Parent := FPanelTop;
  FEditUnitName.Left := 80;
  FEditUnitName.Top := 12;
  FEditUnitName.Width := 200;
  FEditUnitName.OnChange := OnUnitNameChange;
  
  // Property Style
  Lbl := TLabel.Create(Self);
  Lbl.Parent := FPanelTop;
  Lbl.Caption := 'Style:';
  Lbl.Left := 300;
  Lbl.Top := 15;
  
  FCmbStyle := TComboBox.Create(Self);
  FCmbStyle.Parent := FPanelTop;
  FCmbStyle.Left := 340;
  FCmbStyle.Top := 12;
  FCmbStyle.Style := csDropDownList;
  FCmbStyle.Items.Add('POCO (Standard)');
  FCmbStyle.Items.Add('Smart (Dext Prop<T>)');
  FCmbStyle.ItemIndex := 1;
  FCmbStyle.OnChange := OnStyleChange;
  
  // Path
  Lbl := TLabel.Create(Self);
  Lbl.Parent := FPanelTop;
  Lbl.Caption := 'Target Path:';
  Lbl.Left := 10;
  Lbl.Top := 55;
  
  FEditPath := TEdit.Create(Self);
  FEditPath.Parent := FPanelTop;
  FEditPath.Left := 80;
  FEditPath.Top := 52;
  FEditPath.Width := 600;
  FEditPath.Anchors := [akLeft, akTop, akRight];
  
  FBtnPath := TButton.Create(Self);
  FBtnPath.Parent := FPanelTop;
  FBtnPath.Caption := '...';
  FBtnPath.Left := 685;
  FBtnPath.Top := 51;
  FBtnPath.Width := 30;
  FBtnPath.OnClick := OnPathClick;
  FBtnPath.Anchors := [akRight, akTop];
  
  FChkSaveToDisk := TCheckBox.Create(Self);
  FChkSaveToDisk.Parent := FPanelTop;
  FChkSaveToDisk.Caption := 'Save to Disk directly';
  FChkSaveToDisk.Left := 730;
  FChkSaveToDisk.Top := 53;
  FChkSaveToDisk.Width := 150;
  FChkSaveToDisk.OnClick := OnSaveToDiskChange;
  FChkSaveToDisk.Checked := False;
  FEditPath.Enabled := False;
  FBtnPath.Enabled := False;
  
  FPanelBottom := TPanel.Create(Self);
  FPanelBottom.Parent := Self;
  FPanelBottom.Align := alBottom;
  FPanelBottom.Height := 50;
  FPanelBottom.BevelOuter := bvNone;
  
  FBtnCreate := TButton.Create(Self);
  FBtnCreate.Parent := FPanelBottom;
  FBtnCreate.Caption := 'Create Unit';
  FBtnCreate.Width := 120;
  FBtnCreate.Height := 30;
  FBtnCreate.Top := 10;
  FBtnCreate.Left := FPanelBottom.Width - 130;
  FBtnCreate.Anchors := [akRight, akTop];
  FBtnCreate.OnClick := OnCreateClick;

  FBtnCancel := TButton.Create(Self);
  FBtnCancel.Parent := FPanelBottom;
  FBtnCancel.Caption := 'Cancel';
  FBtnCancel.ModalResult := mrCancel;
  FBtnCancel.Width := 100;
  FBtnCancel.Height := 30;
  FBtnCancel.Top := 10;
  FBtnCancel.Left := FBtnCreate.Left - 105; // 5px gap
  FBtnCancel.Anchors := [akRight, akTop];

  FStatsLabel := TLabel.Create(Self);
  FStatsLabel.Parent := FPanelBottom;
  FStatsLabel.Left := 10;
  FStatsLabel.Top := 15;
  FStatsLabel.Caption := 'Statistics: -';
  FStatsLabel.Font.Style := [fsBold];
  
  FMemoCode := TMemo.Create(Self);
  FMemoCode.Parent := Self;
  FMemoCode.Align := alClient;
  FMemoCode.AlignWithMargins := True;
  FMemoCode.ScrollBars := ssBoth;
  FMemoCode.Font.Name := 'Consolas';
  FMemoCode.Font.Size := 10;
  FMemoCode.ReadOnly := False;
end;

procedure TScaffoldingPreviewForm.ShowPreview(const AMeta: TArray<TMetaTable>; const ASuggestedPath: string);
begin
  FMeta := AMeta;
  FEditPath.Text := ASuggestedPath;
  
  if Length(FMeta) = 1 then
    FEditUnitName.Text := FMeta[0].Name + '.Entity'
  else
    FEditUnitName.Text := 'Entities';
    
  RebuildCode;
end;

function TScaffoldingPreviewForm.ShowPreviewModal(const AMeta: TArray<TMetaTable>; const ASuggestedPath: string): Boolean;
begin
  ShowPreview(AMeta, ASuggestedPath);
  Result := ShowModal = mrOk;
end;

procedure TScaffoldingPreviewForm.RebuildCode;
var
  Generator: TDelphiEntityGenerator;
  Style: TPropertyStyle;
  LineCount: Integer;
begin
  Style := psPOCO;
  if FCmbStyle.ItemIndex = 1 then
    Style := psSmart;

  Generator := TDelphiEntityGenerator.Create;
  try
    FGeneratedCode := Generator.GenerateUnit(
      FEditUnitName.Text,
      FMeta,
      msAttributes,
      Style,
      True
    );
    FMemoCode.Lines.Text := FGeneratedCode;

    LineCount := FMemoCode.Lines.Count;
    if Style = psSmart then
      FStatsLabel.Caption := Format('Stats: %d Entity Classes | %d Lines of Code', [Length(FMeta), LineCount])
    else
      FStatsLabel.Caption := Format('Stats: %d Entities | %d Metadata Classes | %d Lines', [Length(FMeta), Length(FMeta), LineCount]);
  finally
    Generator.Free;
  end;
end;

procedure TScaffoldingPreviewForm.OnUnitNameChange(Sender: TObject);
begin
  RebuildCode;
end;

procedure TScaffoldingPreviewForm.OnStyleChange(Sender: TObject);
begin
  RebuildCode;
end;

procedure TScaffoldingPreviewForm.OnPathClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := FEditPath.Text;
  if SelectDirectory('Select Target Folder', '', Dir) then
    FEditPath.Text := Dir;
end;

procedure TScaffoldingPreviewForm.OnSaveToDiskChange(Sender: TObject);
begin
  FEditPath.Enabled := FChkSaveToDisk.Checked;
  FBtnPath.Enabled := FChkSaveToDisk.Checked;
end;

procedure TScaffoldingPreviewForm.OnCreateClick(Sender: TObject);
var
  ModuleServices: IOTAModuleServices;
  NewModule: IOTAModule;
  FullFileName: string;
  Writer: TStreamWriter;
begin
  if not Supports(BorlandIDEServices, IOTAModuleServices, ModuleServices) then
    Exit;

  FullFileName := '';
  if FChkSaveToDisk.Checked then
  begin
    FullFileName := TPath.Combine(FEditPath.Text, FEditUnitName.Text + '.pas');
    
    // Ensure directory exists
    System.SysUtils.ForceDirectories(FEditPath.Text);
    
    // Save to disk
    Writer := TStreamWriter.Create(FullFileName, False, TEncoding.UTF8);
    try
      Writer.Write(FGeneratedCode);
    finally
      Writer.Free;
    end;
  end;

  // Create a new module using the custom creator
  NewModule := ModuleServices.CreateModule(
    TEntityUnitCreator.Create(FGeneratedCode, FEditUnitName.Text, FullFileName, not FChkSaveToDisk.Checked)
  );

  if NewModule <> nil then
    ModalResult := mrOk;
end;

end.
