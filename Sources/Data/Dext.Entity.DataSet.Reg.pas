{***************************************************************************}
{                                                                           }
{           Dext Framework                                                  }
{                                                                           }
{           Copyright (C) 2026 Cesar Romero & Dext Contributors             }
{                                                                           }
{***************************************************************************}
unit Dext.Entity.DataSet.Reg;

interface

uses
  System.Classes;

procedure Register;

implementation

uses
  Dext.Entity.DataSet;

procedure Register;
begin
  RegisterComponents('Dext Entity', [TEntityDataSet]);
end;

end.
