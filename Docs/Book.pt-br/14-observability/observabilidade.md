# Telemetria e Live Tracing

O Dext fornece um sistema de observabilidade poderoso e desacoplado baseado no padrão **Diagnostic Source**. Isso permite monitorar o desempenho do banco de dados, o ciclo de vida das requisições web e eventos personalizados com um overhead de desempenho mínimo.

## O Diagnostic Source

O ponto central para a telemetria é o `TDiagnosticSource`. Ele atua como um publicador onde os componentes do framework e seu próprio código podem "escrever" eventos que os observadores podem "assinar".

### Assinando Eventos

Para monitorar eventos, você assina um observador (um callback) na fonte de diagnósticos.

```pascal
uses Dext.Logging.Telemetry, System.JSON;

initialization
  TDiagnosticSource.Instance.Subscribe(procedure(const AName: string; const APayload: TJSONObject)
    begin
      if AName.StartsWith('SQL.') then
        LogSQL(APayload);
    end);
```

## A Ponte para o ILogger

O Dext vem com uma "ponte" integrada que roteia automaticamente os eventos de telemetria para o sistema de logs (`ILogger`). Isso é extremamente útil durante o desenvolvimento para ver o que está acontecendo sem precisar de um dashboard externo.

Para ativar, basta garantir que a telemetria esteja habilitada na configuração:

```json
{
  "Logging": {
    "CaptureTelemetry": true
  }
}
```

No console, você verá saídas como:
```text
info: Telemetry
      [SQL] SELECT "Id", "Name" FROM "Customers" (2ms)
info: Telemetry
      [HTTP] GET /api/orders - 200 (15ms)
```

## Instrumentação Nativa

### Banco de Dados (ORM)
O `TDbSet<T>` publica automaticamente os seguintes eventos:

| Nome do Evento | Descrição | Dados do Payload |
| :--- | :--- | :--- |
| `SQL.Query` | Executou um SELECT | `SQL`, `DurationMs`, `Rows`, `Error` |
| `SQL.Insert` | Executou um INSERT | `SQL`, `DurationMs`, `Id`, `Error` |
| `SQL.Update` | Executou um UPDATE | `SQL`, `DurationMs`, `Rows`, `Error` |
| `SQL.Delete` | Executou um DELETE | `SQL`, `DurationMs`, `Rows`, `Error` |

### Web Framework
O `TDextPipeline` publica eventos do ciclo de vida HTTP:

| Nome do Evento | Descrição | Dados do Payload |
| :--- | :--- | :--- |
| `HTTP.Request` | Execução completa da requisição | `Method`, `Path`, `StatusCode`, `DurationMs` |

## Escrevendo Eventos Personalizados

Você pode instrumentar sua própria lógica de negócio usando o método `Write`.

```pascal
var Payload := TJSONObject.Create;
Payload.AddPair('OrderId', LOrderId);
Payload.AddPair('Amount', LAmount);

TDiagnosticSource.Instance.Write('Negocio.PedidoProcessado', Payload);
```

## Nota de Desempenho
Se não houver assinantes para um evento específico, a geração do payload e o envio são ignorados, garantindo que a telemetria tenha **custo quase zero** quando não estiver em uso.

---

[← Recursos Avançados](../10-advanced/README.md) | [Próximo: Logging →](logging.md)
