unit TestJsonCore.Entities;

interface

uses
  Dext.Collections,
  Dext.Types.UUID;

type
  {$M+}
  TPost = class
  private
    FId: Integer;
    FContent: string;
  public
    property Id: Integer read FId write FId;
    property Content: string read FContent write FContent;
  end;

  TThreadContent = class
  private
    FId: Integer;
    FName: string;
    FInternalPosts: IList<TPost>;
    procedure SetPosts(const Value: IList<TPost>);
  public
    constructor Create;
    destructor Destroy; override;
    property Id: Integer read FId write FId;
    property Name: string read FName write FName;
    property Posts: IList<TPost> read FInternalPosts write SetPosts;
  end;

  TEntityWithGuid = class
  private
    FId: TGUID;
    FName: string;
  public
    property Id: TGUID read FId write FId;
    property Name: string read FName write FName;
  end;

  TEntityWithUuid = class
  private
    FId: TUUID;
    FName: string;
  public
    property Id: TUUID read FId write FId;
    property Name: string read FName write FName;
  end;

implementation

constructor TThreadContent.Create;
begin
  FInternalPosts := TCollections.CreateList<TPost>;
end;

destructor TThreadContent.Destroy;
begin
  // FInternalPosts is an interface, it will be freed automatically if not circular
  // But wait, it's assigned to FInternalPosts.
  inherited;
end;

procedure TThreadContent.SetPosts(const Value: IList<TPost>);
begin
  FInternalPosts := Value;
end;

end.
