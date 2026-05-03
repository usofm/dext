unit Admin.Utils;

interface

uses
  System.SysUtils,
  System.IOUtils;

function GetFilePath(const RelativePath: string): string;

implementation

function GetFilePath(const RelativePath: string): string;
var
  AppDir: string;
  SearchDir: string;
  TargetPath: string;
  CandidatePath: string;
  I: Integer;
  CategoryDirs: TArray<string>;
  CatDir: string;
  PotentialPath: string;
begin
  AppDir := ExtractFilePath(ParamStr(0));
  AppDir := ExpandFileName(AppDir);
  
  // Estratégia: Subir até encontrar 'Web.Dext.Starter.Admin'  
  SearchDir := AppDir;
  for I := 0 to 5 do
  begin
    // Verifica se existe Web.Dext.Starter.Admin neste nível (ou dentro de um sub-nível de categoria)
    TargetPath := TPath.Combine(SearchDir, 'Web.Dext.Starter.Admin');
    if not TDirectory.Exists(TargetPath) then
    begin
      // Tenta encontrar em categorias comuns (01-06, 99)
      if TDirectory.Exists(SearchDir) then
      begin
        CategoryDirs := TDirectory.GetDirectories(SearchDir, '*');
        for CatDir in CategoryDirs do
        begin
          PotentialPath := TPath.Combine(CatDir, 'Web.Dext.Starter.Admin');
          if TDirectory.Exists(PotentialPath) then
          begin
            TargetPath := PotentialPath;
            Break;
          end;
        end;
      end;
    end;

    if TDirectory.Exists(TargetPath) then
    begin
      CandidatePath := TPath.Combine(TargetPath, RelativePath);
      // Verificar se o arquivo/diretório existe antes de retornar
      if TFile.Exists(CandidatePath) or TDirectory.Exists(TPath.GetDirectoryName(CandidatePath)) then
      begin
        Result := CandidatePath;
        Exit;
      end;
    end;
    
    // Subir um nível
    SearchDir := TPath.GetDirectoryName(ExcludeTrailingPathDelimiter(SearchDir));
    if SearchDir = '' then Break;
  end;
  
  // Fallback: caminho absoluto direto (para cenário onde estamos rodando de dentro do projeto)
  CandidatePath := TPath.Combine(AppDir, RelativePath);
  if TFile.Exists(CandidatePath) then
  begin
    Result := CandidatePath;
    Exit;
  end;
  
  // Último fallback: mesmo que não exista, retorna o path esperado na nova estrutura
  Result := TPath.Combine(AppDir, '..\99-Archived_PoCs\Web.Dext.Starter.Admin\' + RelativePath);
end;

end.
