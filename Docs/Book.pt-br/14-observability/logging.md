# Logging e Diagnósticos

O Dext possui um sistema de logging robusto, inspirado no ecossistema .NET, que permite registrar mensagens de forma estruturada e direcioná-las para diferentes destinos (Sinks).

## Configuração Básica

O logging é configurado no método `ConfigureServices` da sua classe `Startup` usando o builder fluente:

```pascal
procedure TStartup.ConfigureServices(const Services: TDextServices; const Configuration: IConfiguration);
begin
  Services.AddLogging(
    procedure(Builder: ILoggingBuilder)
    begin
      Builder
        .SetMinimumLevel(TLogLevel.Information)
        .AddConsole
        .AddTelemetry; // Roteia eventos de telemetria para o log
    end);
end;
```

## Níveis de Log

Os seguintes níveis estão disponíveis (em ordem de severidade):

| Nível | Descrição |
| :--- | :--- |
| `Trace` | Logs detalhados para diagnóstico profundo. |
| `Debug` | Logs úteis durante o desenvolvimento. |
| `Information` | Fluxos normais da aplicação (startup, requisições). |
| `Warning` | Eventos anômalos que não interrompem o fluxo. |
| `Error` | Falhas que impedem uma operação específica. |
| `Critical` | Falhas críticas que exigem atenção imediata. |

## Log em Arquivo

O Dext inclui um provedor nativo para gravação em arquivos. Os arquivos são gravados no formato **JSON Lines** por padrão, facilitando o consumo por ferramentas de análise.

```pascal
Builder.AddFile('logs/app.log');
```

O provedor gerencia automaticamente a criação dos diretórios necessários.

## Utilizando o ILogger

Para registrar mensagens, você deve solicitar a interface `ILogger` via Injeção de Dependência em seus controladores ou serviços:

```pascal
type
  TMyController = class(TWebController)
  private
    FLogger: ILogger;
  public
    constructor Create(const ALogger: ILogger);
    
    function Get: IWebResponse;
  end;

function TMyController.Get: IWebResponse;
begin
  FLogger.Info('Processando requisição para {Path}', [Request.Path]);
  // ...
end;
```

### Mensagens Estruturadas

O Dext suporta mensagens estruturadas usando a sintaxe de chaves `{}`. Isso permite que provedores avançados (como o Telemetry Bridge) capturem os parâmetros de forma independente da mensagem formatada.

```pascal
FLogger.LogInformation('Pedido {Id} processado com sucesso em {Duration}ms', [LOrderId, LDuration]);
```

## Logging de Requisições HTTP

Para registrar automaticamente todas as requisições HTTP (URL, Método, Status Code, Tempo), adicione o middleware no método `Configure`:

```pascal
procedure TStartup.Configure(const App: IWebApplication);
begin
  App.Builder.UseHttpLogging;
  // ...
end;
```

---

[← Telemetria](observabilidade.md)
