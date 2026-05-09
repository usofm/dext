program DextGeminiServer;

{$APPTYPE CONSOLE}

uses
  Dext.MM,
  System.Classes,
  System.SysUtils,
  Dext.Net.RestClient,
  Dext,
  Dext.Web,
  Dext.Utils,
  Gemini.Models in 'Gemini.Models.pas';


const
  ApiKey = 'GEMINI-API-KEY';
  // Chamada à API do Gemini usando o endpoint v1 (Estável)
  AgentModelUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=' + ApiKey;

begin
  // Inicializa a aplicação Web do Dext
  var App : IWebApplication := WebApplication;
  var Services := App.Services;

  //Services.AddTransient<IList<TGeminiPart>, TList<TGeminiPart>>;

  App.Builder
    .UseDeveloperExceptionPage
    .UseHttpLogging
    .UseStaticFiles('wwwroot')

    // Rota da API: Integração com Gemini
    .MapPost<TChatRequest, IResult>('/ia/ask',
      function(Req: TChatRequest): IResult
      begin
        var GeminiRequest := TGeminiRequest.Create(Req.pergunta);
        var Payload := TDextJson.Serialize(GeminiRequest);

        var Response := RestClient(AgentModelUrl)
          .PostJson(Payload)
          .Await;

        if Response.StatusCode = HttpStatus.OK then
        begin
          try
            var GeminiResponse := TDextJson.Deserialize<TGeminiResponse>(Response.ContentString);
            if GeminiResponse.HasContent then
            begin
              var ChatResponse: TChatResponse;
              ChatResponse.resposta := GeminiResponse.FirstText;
              Result := Results.Ok(ChatResponse);
            end
            else
              Result := Results.Problem('A IA não retornou uma estrutura de resposta válida.');
          except
            on E: Exception do
              Result := Results.Problem('Erro ao processar a resposta da IA: ' + E.Message);
          end;
        end
        else
        begin
          var ErrorMessage := 'Erro "' + Response.StatusCode.ToString + '" na API do Gemini.';
          try
            var ErrorResponse := TDextJson.Deserialize<TGeminiErrorResponse>(Response.ContentString);
            if (ErrorResponse.error.message <> '') then
              ErrorMessage := ErrorResponse.error.message;
          except
            on E: Exception do
              SafeWriteLn('Error parsing error response: ' + E.Message);
          end;
          Result := Results.Problem(ErrorMessage);
        end;
      end);

  // Inicia o servidor na porta 8080 (Padrão)
  App.Run;
end.






