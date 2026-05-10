unit Dext.Entity.Metadata;

interface

uses
  System.SysUtils,
  System.Classes,
  Dext.Collections,
  DelphiAST,
  DelphiAST.Classes,
  DelphiAST.Consts,
  SimpleParser.Lexer.Types,
  Dext.Entity.Core;

type
  /// <summary>
  ///   Specialized syntax analyzer to extract Delphi entity metadata via AST (Static Analysis).
  ///   Allows discovering tables, columns, and attributes directly from .pas files without compilation.
  /// </summary>
  TEntityMetadataParser = class
    FTypeAttributes: TList<TSyntaxNode>;
    FMemberAttributes: TList<TSyntaxNode>;
    function GetNodeText(Node: TSyntaxNode): string;
    function HasAttribute(Nodes: TList<TSyntaxNode>; const AttrName: string; Node: TSyntaxNode = nil): Boolean;
    function GetAttributeValue(Nodes: TList<TSyntaxNode>; const AttrName: string; Node: TSyntaxNode = nil): string;
    function GetAttributeArguments(Nodes: TList<TSyntaxNode>; const AttrName: string; Node: TSyntaxNode = nil): TArray<string>;
    procedure ExtractMembers(AMetadata: TEntityClassMetadata; AClassNode: TSyntaxNode);
  public
    constructor Create;
    destructor Destroy; override;
    function ParseUnit(const AFileName: string; const AContent: string = ''): IList<TEntityClassMetadata>;
  end;

implementation

uses
  Winapi.Windows,
  System.IOUtils,
  System.Types,
  System.TypInfo,
  System.StrUtils;

function TEntityMetadataParser.GetNodeText(Node: TSyntaxNode): string;
  function FindText(ANode: TSyntaxNode): string;
  var
    Child: TSyntaxNode;
  begin
    Result := '';
    if ANode = nil then Exit;
    
    if ANode is TValuedSyntaxNode then
    begin
      Result := TValuedSyntaxNode(ANode).Value;
      if Result <> '' then Exit;
    end;
    
    Result := ANode.GetAttribute(anName);
    if Result <> '' then Exit;
    
    Result := ANode.GetAttribute(anType);
    if Result <> '' then Exit;
    
    for Child in ANode.ChildNodes do
    begin
      Result := FindText(Child);
      if Result <> '' then Exit;
    end;
  end;
begin
  Result := '';
  if Node = nil then Exit;
  Result := FindText(Node);
  if Result.StartsWith('&') then
    Result := Result.Substring(1);
end;

function TEntityMetadataParser.HasAttribute(Nodes: TList<TSyntaxNode>; const AttrName: string; Node: TSyntaxNode): Boolean;
  function NormalizeAttr(const S: string): string;
  var
    N: string;
    P: Integer;
  begin
    N := Trim(S);
    P := LastDelimiter('.', N);
    if P > 0 then
      N := Copy(N, P + 1, MaxInt);
    if N.StartsWith('&') then
      N := N.Substring(1);
    if EndsText('Attribute', N) then
      N := Copy(N, 1, Length(N) - Length('Attribute'));
    Result := N;
  end;

  function AttrMatches(const FoundName, ExpectedName: string): Boolean;
  begin
    Result := SameText(NormalizeAttr(FoundName), NormalizeAttr(ExpectedName));
  end;

  function Check(ANode: TSyntaxNode): Boolean;
  var
    Attr, AttrNameNode: TSyntaxNode;
    FoundName: string;
  begin
    Result := False;
    if (ANode = nil) or (ANode.Typ <> ntAttributes) then Exit;
    for Attr in ANode.ChildNodes do
    begin
      AttrNameNode := Attr.FindNode(ntName);
      if AttrNameNode <> nil then
      begin
        FoundName := GetNodeText(AttrNameNode);
        if AttrMatches(FoundName, AttrName) then
        begin
          Exit(True);
        end;
      end;
    end;
  end;
var
  Child: TSyntaxNode;
begin
  Result := False;
  if Node <> nil then
  begin
    if Node.Typ = ntAttributes then begin if Check(Node) then Exit(True); end;
    for Child in Node.ChildNodes do
      if Child.Typ = ntAttributes then
        if Check(Child) then Exit(True);
  end;
  if Nodes <> nil then
    for Child in Nodes do
      if Check(Child) then Exit(True);
end;

function TEntityMetadataParser.GetAttributeArguments(Nodes: TList<TSyntaxNode>; const AttrName: string; Node: TSyntaxNode): TArray<string>;
  function NormalizeAttr(const S: string): string;
  var
    N: string;
    P: Integer;
  begin
    N := Trim(S);
    P := LastDelimiter('.', N);
    if P > 0 then
      N := Copy(N, P + 1, MaxInt);
    if N.StartsWith('&') then
      N := N.Substring(1);
    if EndsText('Attribute', N) then
      N := Copy(N, 1, Length(N) - Length('Attribute'));
    Result := N;
  end;

  function GetArgsFromAttr(AnAttr: TSyntaxNode): TArray<string>;
  var
    Args, Arg, ValNode: TSyntaxNode;
  begin
    Result := [];
    Args := AnAttr.FindNode(ntArguments);
    if Args <> nil then
      for Arg in Args.ChildNodes do
      begin
        ValNode := Arg.FindNode(ntValue);
        if ValNode <> nil then
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)] := GetNodeText(ValNode).DeQuotedString('''');
        end;
      end;
  end;

  function GetArgs(ANode: TSyntaxNode): TArray<string>;
  var
    Attr, NameNode: TSyntaxNode;
  begin
    Result := [];
    if ANode = nil then Exit;
    for Attr in ANode.ChildNodes do
      if Attr.Typ = ntAttribute then
      begin
        NameNode := Attr.FindNode(ntName);
        if (NameNode <> nil) and SameText(NormalizeAttr(GetNodeText(NameNode)), NormalizeAttr(AttrName)) then
          Exit(GetArgsFromAttr(Attr));
      end;
  end;
var
  Child: TSyntaxNode;
begin
  Result := [];
  if Node <> nil then
  begin
    if Node.Typ = ntAttributes then begin Result := GetArgs(Node); if Length(Result) > 0 then Exit; end;
    for Child in Node.ChildNodes do
      if Child.Typ = ntAttributes then begin Result := GetArgs(Child); if Length(Result) > 0 then Exit; end;
  end;
  if Nodes <> nil then
    for Child in Nodes do begin Result := GetArgs(Child); if Length(Result) > 0 then Exit; end;
end;

function TEntityMetadataParser.GetAttributeValue(Nodes: TList<TSyntaxNode>; const AttrName: string; Node: TSyntaxNode): string;
  function NormalizeAttr(const S: string): string;
  var
    N: string;
    P: Integer;
  begin
    N := Trim(S);
    P := LastDelimiter('.', N);
    if P > 0 then
      N := Copy(N, P + 1, MaxInt);
    if N.StartsWith('&') then
      N := N.Substring(1);
    if EndsText('Attribute', N) then
      N := Copy(N, 1, Length(N) - Length('Attribute'));
    Result := N;
  end;

  function GetValFromAttr(AnAttr: TSyntaxNode): string;
  var
    Args, Arg, ValNode: TSyntaxNode;
    RawVal: string;
  begin
    Result := '';
    Args := AnAttr.FindNode(ntArguments);
    if Args <> nil then
    begin
      for Arg in Args.ChildNodes do
      begin
        ValNode := Arg.FindNode(ntValue);
        if ValNode <> nil then
        begin
          RawVal := GetNodeText(ValNode);
          Result := RawVal.DeQuotedString('''');
          if Result <> '' then Exit;
        end;
      end;
    end;
  end;

  function GetVal(ANode: TSyntaxNode): string;
  var
    Attr, NameNode: TSyntaxNode;
    FoundName: string;
  begin
    Result := '';
    if (ANode = nil) or (ANode.Typ <> ntAttributes) then Exit;
    for Attr in ANode.ChildNodes do
    begin
      NameNode := Attr.FindNode(ntName);
      if NameNode <> nil then
      begin
        FoundName := GetNodeText(NameNode);
        if SameText(NormalizeAttr(FoundName), NormalizeAttr(AttrName)) then
        begin
          Result := GetValFromAttr(Attr);
          if Result <> '' then Exit;
        end;
      end;
    end;
  end;
var
  Child: TSyntaxNode;
begin
  Result := '';
  if Node <> nil then
  begin
    Result := GetVal(Node);
    if Result <> '' then Exit;
    for Child in Node.ChildNodes do
    begin
      Result := GetVal(Child);
      if Result <> '' then Exit;
    end;
  end;
  if Nodes <> nil then
    for Child in Nodes do
    begin
      Result := GetVal(Child);
      if Result <> '' then Exit;
    end;
end;

procedure TEntityMetadataParser.ExtractMembers(AMetadata: TEntityClassMetadata; AClassNode: TSyntaxNode);
  procedure Scan(ContextNode: TSyntaxNode);
  var
    CChild, Sub: TSyntaxNode;
    MName, MType, AlignAttr: string;
    Member: TEntityMemberMetadata;
    TempValue: string;
    JoinArgs: TArray<string>;
  begin
    for CChild in ContextNode.ChildNodes do
    begin
      if CChild.Typ = ntAttributes then
      begin
        FMemberAttributes.Add(CChild);
        Continue;
      end;

      if CChild.Typ in [ntProperty, ntField] then
      begin
        MName := GetNodeText(CChild);
        if MName = '' then Continue;

        // SKIP private fields starting with 'F' unless they have attributes
        if (CChild.Typ = ntField) and (FMemberAttributes.Count = 0) and (MName.StartsWith('F')) then
          Continue;

        MType := CChild.GetAttribute(anType);
        if MType = '' then
        begin
          for Sub in CChild.ChildNodes do
            if Sub.Typ = ntType then
              MType := GetNodeText(Sub);
        end;

        Member := AMetadata.Members.Add;
        Member.Name := MName;
        Member.MemberType := MType;
        Member.Visible := True;
        
        Member.IsPrimaryKey := HasAttribute(FMemberAttributes, 'PrimaryKey', CChild) or 
                               HasAttribute(FMemberAttributes, 'PK', CChild);
        
        Member.IsRequired := HasAttribute(FMemberAttributes, 'Required', CChild);
        Member.IsAutoInc := HasAttribute(FMemberAttributes, 'AutoInc', CChild);
        Member.IsReadOnly := HasAttribute(FMemberAttributes, 'NotMapped', CChild);
        Member.IsCurrency := HasAttribute(FMemberAttributes, 'Currency', CChild);
        
        Member.HasJoin := HasAttribute(FMemberAttributes, 'Join', CChild);
        if Member.HasJoin then
        begin
          JoinArgs := GetAttributeArguments(FMemberAttributes, 'Join', CChild);
          if Length(JoinArgs) >= 1 then Member.JoinColumn := JoinArgs[0];
          if Length(JoinArgs) >= 2 then Member.JoinTargetColumn := JoinArgs[1];
        end;
        
        Member.HasInclude := HasAttribute(FMemberAttributes, 'Include', CChild);
        
        // Relation Type detection (Independence of Join/Include)
        if HasAttribute(FMemberAttributes, 'HasMany', CChild) then Member.RelationType := 'HasMany'
        else if HasAttribute(FMemberAttributes, 'HasOne', CChild) then Member.RelationType := 'HasOne'
        else if HasAttribute(FMemberAttributes, 'BelongsTo', CChild) then Member.RelationType := 'BelongsTo'
        // Scaffolding often emits [ForeignKey('...')] on navigation members.
        // Treat it as BelongsTo so design-time metadata can classify navigation correctly.
        else if HasAttribute(FMemberAttributes, 'ForeignKey', CChild) or
                HasAttribute(FMemberAttributes, 'FK', CChild) then
          Member.RelationType := 'BelongsTo';
        
        Member.DefaultValue := GetAttributeValue(FMemberAttributes, 'DefaultValue', CChild);

        // DisplayLabel / Caption / DisplayName
        TempValue := GetAttributeValue(FMemberAttributes, 'Caption', CChild);
        if TempValue = '' then TempValue := GetAttributeValue(FMemberAttributes, 'DisplayLabel', CChild);
        if TempValue = '' then TempValue := GetAttributeValue(FMemberAttributes, 'DisplayName', CChild);
        if TempValue <> '' then Member.DisplayLabel := TempValue;

        // DisplayFormat
        TempValue := GetAttributeValue(FMemberAttributes, 'DisplayFormat', CChild);
        if TempValue <> '' then Member.DisplayFormat := TempValue;

        // EditMask
        TempValue := GetAttributeValue(FMemberAttributes, 'EditMask', CChild);
        if TempValue <> '' then Member.EditMask := TempValue;

        // Visible
        TempValue := GetAttributeValue(FMemberAttributes, 'Visible', CChild);
        if TempValue <> '' then Member.Visible := SameText(TempValue, 'True');

        // Integer Attributes (Only set if > 0)
        TempValue := GetAttributeValue(FMemberAttributes, 'MaxLength', CChild);
        if (TempValue <> '') and (StrToIntDef(TempValue, 0) > 0) then Member.MaxLength := StrToInt(TempValue);

        TempValue := GetAttributeValue(FMemberAttributes, 'DisplayWidth', CChild);
        if (TempValue <> '') and (StrToIntDef(TempValue, 0) > 0) then Member.DisplayWidth := StrToInt(TempValue);

        TempValue := GetAttributeValue(FMemberAttributes, 'Precision', CChild);
        if (TempValue <> '') and (StrToIntDef(TempValue, 0) > 0) then Member.Precision := StrToInt(TempValue);

        // Alignment
        AlignAttr := GetAttributeValue(FMemberAttributes, 'Alignment', CChild);
        if AlignAttr <> '' then Member.Alignment := TAlignment(GetEnumValue(TypeInfo(TAlignment), AlignAttr));

        FMemberAttributes.Clear;
      end
      else if CChild.Typ in [ntPrivate, ntPublic, ntPublished, ntProtected, ntStrictPrivate, ntStrictProtected] then
      begin
        Scan(CChild);
      end
      else if not (CChild.Typ in [ntAnsiComment, ntBorComment, ntSlashesComment]) then
      begin
        FMemberAttributes.Clear;
      end;
    end;
  end;
begin
  FMemberAttributes.Clear;
  Scan(AClassNode);
end;

constructor TEntityMetadataParser.Create;
begin
  FTypeAttributes := TList<TSyntaxNode>.Create;
  FMemberAttributes := TList<TSyntaxNode>.Create;
end;

destructor TEntityMetadataParser.Destroy;
begin
  FTypeAttributes.Free;
  FMemberAttributes.Free;
  inherited;
end;

function TEntityMetadataParser.ParseUnit(const AFileName: string; const AContent: string): IList<TEntityClassMetadata>;
var
  Builder: TPasSyntaxTreeBuilder;
  SyntaxTree, InterfaceNode, TypeSection, TypeNode, ClassNode: TSyntaxNode;
  ClassName, TableName, DisplayName, LContent, LUnitName: string;
  Stream: TStringStream;
  Metadata: TEntityClassMetadata;
begin
  Result := TCollections.CreateObjectList<TEntityClassMetadata>(True);
  LContent := AContent;
  LUnitName := ChangeFileExt(ExtractFileName(AFileName), '');

  if LContent = '' then
  begin
    if not FileExists(AFileName) then
    begin
       Exit;
    end;
    try
      LContent := TFile.ReadAllText(AFileName);
    except
      on E: Exception do
      begin
        Exit;
      end;
    end;
  end;

  Builder := TPasSyntaxTreeBuilder.Create;
  try
    Builder.InitDefinesDefinedByCompiler;
    Builder.AddDefine('MSWINDOWS');
    Builder.UseDefines := True;

    Stream := TStringStream.Create(LContent);
    try
      SyntaxTree := Builder.Run(Stream);
      try
        InterfaceNode := SyntaxTree.FindNode(ntInterface);
        if InterfaceNode = nil then InterfaceNode := SyntaxTree;

        for TypeSection in InterfaceNode.ChildNodes do
        begin
          if TypeSection.Typ <> ntTypeSection then Continue;

          FTypeAttributes.Clear;
          for TypeNode in TypeSection.ChildNodes do
          begin
            if TypeNode.Typ = ntAttributes then
            begin
              FTypeAttributes.Add(TypeNode);
              Continue;
            end;

            if TypeNode.Typ = ntTypeDecl then
            begin
              ClassName := TypeNode.GetAttribute(anName);
              ClassNode := TypeNode.FindNode(ntType);

              if (ClassNode <> nil) and SameText(ClassNode.GetAttribute(anType), 'class') then
              begin
                 if HasAttribute(FTypeAttributes, 'Table', TypeNode) or HasAttribute(FTypeAttributes, 'Entity', TypeNode) then
                 begin
                  TableName := GetAttributeValue(FTypeAttributes, 'Table', TypeNode);
                  if TableName = '' then TableName := GetAttributeValue(FTypeAttributes, 'Entity', TypeNode);
                  if TableName = '' then TableName := ClassName;
                    
                  DisplayName := GetAttributeValue(FTypeAttributes, 'DisplayLabel', TypeNode);
                  if DisplayName = '' then DisplayName := GetAttributeValue(FTypeAttributes, 'DisplayName', TypeNode);
                  if DisplayName = '' then DisplayName := GetAttributeValue(FTypeAttributes, 'Caption', TypeNode);

                  Metadata := TEntityClassMetadata.Create;
                  Metadata.EntityClassName := ClassName;
                  Metadata.DisplayName := DisplayName;
                  Metadata.EntityUnitName := LUnitName;
                  Metadata.TableName := TableName;
                  ExtractMembers(Metadata, ClassNode);
                  Result.Add(Metadata);
                end;
              end;
              // ALWAYS clear after any type declaration node to prepare for the next potential class
              FTypeAttributes.Clear;
            end;
          end;
        end;
      finally
        SyntaxTree.Free;
      end;
    finally
      Stream.Free;
    end;
  finally
    Builder.Free;
  end;
end;

end.
