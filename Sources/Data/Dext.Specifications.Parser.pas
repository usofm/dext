unit Dext.Specifications.Parser;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.Variants,
  Dext.Specifications.Interfaces,
  Dext.Specifications.Types;

type
  TStringExpressionParser = class
  public
    class function Parse(const AFilter: string): IExpression;
  end;

implementation

uses
  System.StrUtils;

{ TStringExpressionParser }

class function TStringExpressionParser.Parse(const AFilter: string): IExpression;
var
  Parts: TArray<string>;
  FieldName, Op, ValStr: string;
  BinaryOp: TBinaryOperator;
  Value: TValue;
  Dbl: Double;
  Int: Integer;
begin
  Result := nil;
  if AFilter.Trim = '' then Exit;

  // Parser simplificado baseado em Split por Espaço
  // Sintaxe esperada: "Campo Operador Valor"
  Parts := AFilter.Trim.Split([' ']);
  
  if Length(Parts) < 3 then
    Exit; // Formato inválido para esse parser básico

  FieldName := Parts[0];
  Op := Parts[1].ToUpper;
  
  // Capturar o Valor (pode conter espaços se for string entre aspas)
  ValStr := string.Join(' ', Parts, 2, Length(Parts) - 2).Trim;
  if ValStr.StartsWith('''') and ValStr.EndsWith('''') then
    ValStr := ValStr.Substring(1, ValStr.Length - 2);

  // Identificar Operador
  if (Op = '=') or (Op = 'EQUAL') then BinaryOp := boEqual
  else if (Op = '<>') or (Op = 'NOTEQUAL') then BinaryOp := boNotEqual
  else if Op = '>' then BinaryOp := boGreaterThan
  else if Op = '>=' then BinaryOp := boGreaterThanOrEqual
  else if Op = '<' then BinaryOp := boLessThan
  else if Op = '<=' then BinaryOp := boLessThanOrEqual
  else if Op = 'LIKE' then BinaryOp := boLike
  else Exit;

  // Converter valor tipado
  if ValStr.ToLower = 'true' then Value := True
  else if ValStr.ToLower = 'false' then Value := False
  else if (ValStr.Contains('.')) and (TryStrToFloat(ValStr, Dbl, FormatSettings.Invariant)) then Value := Dbl
  else if TryStrToInt(ValStr, Int) then Value := Int
  else Value := ValStr;

  // Criar Expressão Binary
  Result := TBinaryExpression.Create(
    TPropertyExpression.Create(FieldName),
    TLiteralExpression.Create(Value),
    BinaryOp
  );
end;

end.
