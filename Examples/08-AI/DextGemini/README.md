# Dext Gemini AI: O Fim da Complexidade
**Dext Minimal API + Dext.Templating vs The World**

Este projeto é uma provocação técnica. Mostramos como o **Dext Framework** torna obsoletas stacks complexas como Next.js (Frontend) + Horse (Backend) ao oferecer uma solução unificada e nativa.

## Por que esta stack é superior?

### 1. Dext Minimal API vs Horse
Enquanto o Horse exige registros manuais e middlewares externos para quase tudo, o Dext Minimal API oferece:
- **Injeção de Dependência Nativa**: Serviços são injetados nos parâmetros da lambda automaticamente.
- **Model Binding Automático**: O Dext faz o parse do JSON para o seu DTO/Record sem que você precise chamar `BodyAsJson`.
- **Sintaxe Fluída**: Configuração de rotas, metadados e segurança em uma única cadeia de métodos.

### 2. Dext.Templating vs Next.js
Para muitas aplicações de negócio, o Next.js adiciona uma complexidade desnecessária (Node.js, build, hydration). Com o **Dext.Templating**:
- **SSR Nativo**: O servidor Delphi renderiza o HTML usando um motor AST de alta performance.
- **Mapeamento Automático**: O `IViewData` do Web Framework é mapeado automaticamente para o contexto do template.
- **Razor-Like Syntax**: Use `@var`, `@if`, `@foreach` diretamente no HTML.
- **Zero JS Build**: Sem npm, sem webpack, sem dor de cabeça. Apenas um executável Delphi servindo tudo.

### 3. Dext.Net & Serialization vs The Rest
Esqueça a verbosidade de manipular JSON manualmente.
- **Records & Auto-Serialization**: Use records tipados para falar com o Gemini. O Dext cuida do resto.
- **RestClient Fluído**: Suporte total a `Await` e chamadas encadeadas.

## Destaques Técnicos

1. **AddDextTemplating**: Habilitação do motor de templates com apenas uma linha de código.
2. **Type-Safe IA**: Toda a comunicação com a API do Google é tipada, garantindo robustez.
3. **Tailwind CSS**: Estética premium integrada ao SSR nativo.

## Como Executar

1. Abra o projeto `Server\DextGeminiServer.dpr`.
2. Insira sua **Gemini API Key**.
3. Compile e rode.
4. Acesse `http://localhost:9000`.

---
*Dext: Provando que o Delphi moderno é a stack mais produtiva para o desenvolvedor Full-Stack.*
