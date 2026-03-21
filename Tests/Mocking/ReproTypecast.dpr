program ReproTypecast;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  Dext.Utils,
  Dext.Mocks.Auto;

type
  TCustomerRepository = class
  public
    function GetCount: Integer; virtual;
  end;

  TServiceWithClass = class
  private
    FRepo: TCustomerRepository;
  public
    constructor Create(Repo: TCustomerRepository);
    property Repo: TCustomerRepository read FRepo;
  end;

{ TCustomerRepository }
function TCustomerRepository.GetCount: Integer;
begin
  Result := 10;
end;

{ TServiceWithClass }
constructor TServiceWithClass.Create(Repo: TCustomerRepository);
begin
  FRepo := Repo;
end;

var
  Mocker: TAutoMocker;
  Svc: TServiceWithClass;
begin
  try
    Mocker := TAutoMocker.Create;
    try
      WriteLn('Creating instance...');
      Svc := Mocker.CreateInstance<TServiceWithClass>;
      try
        WriteLn('Instance created successfully.');
        if Svc.Repo <> nil then
          WriteLn('Repo is not nil.')
        else
          WriteLn('Repo is nil!');
      finally
        Svc.Free;
      end;
    finally
      Mocker.Free;
    end;
  except
    on E: Exception do
      WriteLn('Exception: ', E.ClassName, ': ', E.Message);
  end;

  ConsolePause;
end.
