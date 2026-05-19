unit Dext.ActiveArchitecture.Services;

interface

uses
  System.SysUtils,
  Dext.Net.RestClient,
  Dext.Net.RestRequest,
  Dext.ActiveArchitecture.Domain;

type
  /// <summary>
  /// Implementação concreta do serviço de frete externo consumindo uma API REST.
  /// Reside na camada de Infraestrutura e utiliza o TRestClient do Dext.
  /// </summary>
  TShippingService = class(TInterfacedObject, IShippingService)
  private
    FClient: TRestClient;
  public
    constructor Create;
    destructor Destroy; override;
    
    function CalcularCotacaoFrete(const Country: string; TotalWeight: Double): Double;
  end;

implementation

{ TShippingService }

constructor TShippingService.Create;
begin
  inherited;
  // Inicialização e configuração do timeout do cliente REST gerido por escopo
  FClient := TRestClient
    .Create('https://api.exchangerate-api.com/v4/latest/USD')
    .Timeout(3000);
end;

destructor TShippingService.Destroy;
begin
  inherited;
end;

function TShippingService.CalcularCotacaoFrete(const Country: string; TotalWeight: Double): Double;
var
  ResponseText: string;
  BaseRate: Double;
begin
  // Peso base multiplicado pela taxa de envio internacional estimada por país
  if SameText(Country, 'Brazil') or SameText(Country, 'Brasil') then
    BaseRate := 15.0
  else if SameText(Country, 'Portugal') then
    BaseRate := 8.5
  else if SameText(Country, 'USA') or SameText(Country, 'UK') then
    BaseRate := 12.0
  else
    BaseRate := 20.0;

  try
    // Demonstração real de requisição síncrona/fluente e resiliente no Dext.Net
    ResponseText := FClient.Get('').Await.ContentString;

    // Se obtivermos resposta da API externa de câmbio, aplicamos um fator dinâmico na cotação
    if not ResponseText.IsEmpty then
      Result := (TotalWeight * BaseRate) * 1.05
    else
      Result := TotalWeight * BaseRate;
  except
    // Fallback: se estiver offline durante a palestra ou houver timeout, retorna a cotação padrão baseada em memória
    Result := TotalWeight * BaseRate;
  end;
end;

end.
