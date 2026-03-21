# Dext Framework — Agent Skills (Habilidades do Agente)

Pacotes de instruções focados para escrever código **Dext** (framework moderno para Delphi) correto e idiomático.

## Habilidades Disponíveis

| Habilidade | Arquivo | Carregar Quando |
|-------|------|-----------|
| **dext-app-structure** | `dext-app-structure.md` | Configuração de novo projeto, classe Startup, pipeline de middleware, bootstrap `.dpr`, layout do projeto |
| **dext-web** | `dext-web.md` | Endpoints HTTP, Minimal APIs, Controllers, roteamento, model binding, padrão Results |
| **dext-view-engine** | `dext-view-engine.md` | Web Stencils SSR, `Results.View`, sintaxe de templates (`@if`, `@foreach`, `@switch`), layouts (`@LayoutPage`, `@RenderBody`, `@Import`), binding `@(Prop(...))`, streaming flyweight, AddVar/OnValue, scaffolding, sessão/auth, whitelist |
| **dext-htmx** | `dext-htmx.md` | Padrões HTMX: busca ao vivo, edição inline, exclusão, modais, paginação, abas, scroll infinito, partials, estratégias de swap, indicadores de carregamento |
| **dext-orm** | `dext-orm.md` | Entidades ORM, DbContext, consultas, Smart Properties, CRUD |
| **dext-orm-advanced** | `dext-orm-advanced.md` | Relacionamentos, eager loading, herança (TPH/TPT), Especificações, migrations, SQL bruto, stored procedures, locking, multi-tenancy |
| **dext-di** | `dext-di.md` | Registro de serviços, tempos de vida (Scoped/Singleton/Transient), injeção via construtor, atributo `[Inject]` |
| **dext-auth** | `dext-auth.md` | Autenticação JWT, endpoints de login, `[Authorize]`, claims, `TClaimsBuilder` |
| **dext-testing** | `dext-testing.md` | Testes de unidade, `Mock<T>`, assertions fluentes (`Should`), `[TestFixture]`, testes de snapshot |
| **dext-collections** | `dext-collections.md` | `IList<T>`, `TCollections`, operações LINQ, semântica de ownership, `IChannel<T>` |
| **dext-api-features** | `dext-api-features.md` | Middleware, CORS, rate limiting, cache de resposta, health checks, OpenAPI/Swagger, arquivos estáticos, compressão |
| **dext-background** | `dext-background.md` | Workers em segundo plano (`IHostedService`), configuração (`IConfiguration`, padrão Options), tarefas assíncronas (`TAsyncTask`) |
| **dext-networking** | `dext-networking.md` | Cliente REST (`TRestClient`), requisições HTTP assíncronas, respostas tipadas, provedores de autenticação, pool de conexões |
| **dext-realtime** | `dext-realtime.md` | Hubs (`THub`), mensagens em tempo real compatíveis com SignalR, grupos, `IHubContext<T>` |
| **dext-database-as-api** | `dext-database-as-api.md` | API REST CRUD instantânea de entidades ORM com zero código (`MapDataApi<T>`) |
| **dext-desktop-ui** | `dext-desktop-ui.md` | Aplicativos desktop VCL, Navigator (inspirado no Flutter), Magic Binding (bidirecional, declarativo), MVVM |
| **dext-server-adapters** | `dext-server-adapters.md` | Adaptador Indy (self-hosted), SSL/HTTPS (OpenSSL/Taurus), `Run` vs `Start`, padrões de deploy, WebBroker/ISAPI (roadmap) |
| **dext-examples** | `dext-examples.md` | Índice dos projetos oficiais em `Examples\`, comandos de compilação, qual demo mostra qual recurso |

## Instalação Manual

Copie a pasta `Docs/skills/` para o seu projeto e, em seguida, referencie as habilidades pelo nome do arquivo.

| Agente | Caminho no projeto | Caminho global |
|-------|--------------------|-------------|
| **Claude Code** | `.claude/skills/` | `~/.claude/skills/` |
| **Cursor** | `.agents/skills/` | `~/.agents/skills/` |
| **Cline** | `.cline/skills/` | `~/.cline/skills/` |
| **OpenCode** | `.agents/skills/` | `~/.agents/skills/` |
| **Continue** | `.continue/skills/` | `~/.continue/skills/` |

## Como Funciona

As habilidades são carregadas dinamicamente quando o agente precisa delas. O README é sempre carregado para que o agente saiba qual habilidade ativar. Os arquivos de habilidades individuais são carregados sob demanda — mantendo a janela de contexto leve. Alguns usuários avançados preferem configurar links simbólicos para apontar ferramentas como o `claude-code` de `.claude/skills` diretamente para a pasta `Docs/skills` neste repositório.

## Guia de Ativação (Triggers)

**Carregue `dext-view-engine`** quando:

- Configurar o Web Stencils como motor de views/templates
- Escrever chamadas `Results.View` ou configuração `AddWebStencils`
- Criar ou editar arquivos `.html` com sintaxe `@`
- Usar `@if`, `@else`, `@foreach`, `@switch`, `@ForEach`, `@page`, `@query` em templates
- Trabalhar com layouts (`@LayoutPage`, `@RenderBody`, `@RenderHeader`, `@Import`, `@ExtraHeader`)
- Fazer binding de Smart Properties em templates (`@(Prop(...))`)
- Configurar a whitelist do Web Stencils para classes de entidade
- Usar `AddVar`, `AddModule`, `OnValue` ou `@Scaffolding`
- Implementar gestão de sessão (`TWebSessionManager`, `TWebFormsAuthenticator`, `TWebAuthorizer`)
- Usar o objeto `@session` em templates
- Usar sintaxe de expressão `@()`
- Configurar o iterador flyweight em streaming para grandes volumes
- Dúvidas sobre sintaxe de templates Web Stencils, sistema de layout ou arquitetura
- Integração com frameworks CSS (Tailwind, Bootstrap) e Web Stencils

**Carregue `dext-htmx`** quando:

- Adicionar interatividade HTMX a templates Web Stencils
- Construir busca ao vivo, edição inline, exclusão ou padrões com modais
- Configurar `hx-get`, `hx-post`, `hx-put`, `hx-delete`, `hx-target`, `hx-swap`, `hx-trigger`
- Criar views parciais para respostas fragmento HTMX
- Implementar paginação, abas, scroll infinito ou tabelas ordenáveis com HTMX
- Usar indicadores de carregamento (`htmx-indicator`)
- Integrar AlpineJS ou Hyperscript junto com HTMX
- Entender headers de resposta HTMX (`HX-Redirect`, `HX-Trigger`, etc.)
- Depurar problemas em que o layout ainda renderiza dentro do alvo HTMX

**Carregue `dext-app-structure`** quando:

- Criar um novo projeto Dext do zero
- Configurar a classe Startup e o pipeline de middleware
- Configurar o ponto de entrada `.dpr`
- Organizar arquivos e módulos do projeto

**Carregue `dext-web`** quando:

- Criar ou modificar endpoints HTTP (`MapGet`, `MapPost`, `[HttpGet]`, `[HttpPost]`)
- Escrever controllers (`[ApiController]`, `TInterfacedObject`)
- Lidar com model binding, parâmetros de rota, query strings, headers
- Usar `Results.Ok`, `Results.Created`, etc.

**Carregue `dext-orm`** quando:

- Definir classes de entidade com `[Table]`, `[PK]`, `[Required]`, etc.
- Escrever subclasses de `TDbContext` com propriedades `IDbSet<T>`
- Consultar com `.Where`, `.ToList`, `.Find`, Smart Properties
- Adicionar/atualizar/remover registros, db seeding

**Carregue `dext-orm-advanced`** quando:

- Definir relacionamentos (`[ForeignKey]`, `[InverseProperty]`, `[ManyToMany]`)
- Usar eager loading (`.Include`)
- Trabalhar com herança TPH/TPT (`[Inheritance]`, `[DiscriminatorColumn]`)
- Escrever classes Specification, migrations, SQL bruto, stored procedures
- Implementar locking (otimista/pessimista) ou multi-tenancy

**Carregue `dext-di`** quando:

- Registrar serviços usando `.AddScoped`, `.AddSingleton`, `.AddTransient`
- Configurar `ConfigureServices` em uma classe Startup
- Injetar serviços via construtores ou pelo atributo `[Inject]`
- Usar o registro de factory com `IServiceProvider`

**Carregue `dext-auth`** quando:

- Implementar autenticação JWT
- Criar endpoints de login
- Usar `[Authorize]`, `[AllowAnonymous]`
- Construir claims usando `TClaimsBuilder`

**Carregue `dext-testing`** quando:

- Escrever classes com `[TestFixture]`
- Usar `Mock<T>` (de `Dext.Mocks`)
- Escrever assertions fluentes com `Should(...)`
- Configurar projetos de teste (`.dpr`)
- Usar snapshot testing (`MatchSnapshot`)

**Carregue `dext-collections`** quando:

- Usar `IList<T>`, `TCollections.CreateList`, `TCollections.CreateObjectList`
- Escrever consultas estilo LINQ em listas em memória
- Usar `IChannel<T>` para comunicação entre threads

**Carregue `dext-api-features`** quando:

- Adicionar middleware (CORS, rate limiting, compressão, arquivos estáticos)
- Configurar a documentação OpenAPI/Swagger
- Configurar health checks, cache de respostas

**Carregue `dext-background`** quando:

- Criar workers em background com `IHostedService`
- Carregar ou realizar bind de configurações (`appsettings.json`, variáveis de ambiente, padrão Options)
- Usar `TAsyncTask` para operações assíncronas não-bloqueantes

**Carregue `dext-networking`** quando:

- Fazer requisições HTTP de saída para APIs externas
- Usar `TRestClient` para chamadas REST
- Precisar de chamadas HTTP assíncronas com desserialização tipada

**Carregue `dext-realtime`** quando:

- Construir recursos em tempo real (WebSockets, push notifications)
- Usar `THub` e `IHubContext<T>`
- Enviar mensagens para clientes conectados ou grupos

**Carregue `dext-database-as-api`** quando:

- Precisar de CRUD REST instantâneo para uma entidade sem código de controller
- Usar `App.Builder.MapDataApi<T>` para painéis administrativos ou prototipagem rápida

**Carregue `dext-server-adapters`** quando:

- Configurar SSL/HTTPS (`SslProvider`, `SslCert`, `SslKey`)
- Escolher entre `App.Run` (bloqueante) e `App.Start` (não-bloqueante)
- Fazer deploy atrás de proxy reverso IIS/nginx
- Tiver dúvidas sobre suporte futuro a adaptadores ou ISAPI/WebBroker

**Carregue `dext-desktop-ui`** quando:

- Construir aplicativos desktop VCL com o Dext Navigator
- Implementar o Magic Binding (binding bidirecional declarativo)
- Seguir o padrão MVVM com ViewModel + Controller + Frame

**Carregue `dext-examples`** quando:

- Descobrir qual projeto em `Examples\` demonstra um padrão ou recurso
- Precisar de comandos MSBuild ou da lista curada de demos business vs utilitários

## Fatos Principais sobre o Framework

- **Pacotes**: Dext.Core, Dext.EF.Core, Dext.Web.Core, Dext.Testing, Dext.Net
- **Alvo**: Delphi 11 Alexandria e posteriores
- **Paradigma**: Inspirado no ASP.NET Core (Minimal APIs, padrão Controller, DI, ORM)
- **Código-fonte**: `$(DEXT)\Sources\` — configure a variável de ambiente `DEXT`
- **Exemplos**: `$(DEXT)\Examples\` — 39 projetos de exemplo completos
- **Documentação**: `$(DEXT)\Docs\Book\` — 79 capítulos em markdown

## Regras Críticas (Aplicam-se a Todas as Habilidades)

1. **Parâmetros de rota usam a sintaxe `{id}`**, não `:id` (estilo Express)
2. **Parâmetros de rota em controllers DEVEM começar com `/`**: `[HttpGet('/{id}')]`
3. **NUNCA nomeie um método de controller como `Create`** — cria conflito com os construtores do Delphi (use `CreateUser`, `CreateOrder`, etc.)
4. **NUNCA use `Ctx.RequestServices.GetService<T>`** — use parâmetros de tipo genéricos
5. **NUNCA use `TObjectList<T>`** para resultados de ORM — use `IList<T>` de `Dext.Collections`
6. **NUNCA use `[StringLength]`** — use `[MaxLength(N)]`
7. **NUNCA use `NavType<T>`** — use `Nullable<T>` de `Dext.Types.Nullable`
8. **Sempre `.WithPooling(True)`** para DbContexts em Web APIs
9. **Sempre chame `.Update(Entity)` antes de `SaveChanges`** para entidades desanexadas (detached)
10. **`Mock<T>` é um Record** — nunca chame `.Free` nele
11. **`Dext.Entity.Core`** deve estar na seção `uses` para os genéricos de `IDbSet<T>` compilarem
12. **`SetConsoleCharSet`** é OBRIGATÓRIO em todos os projetos console (test runners, ferramentas de linha de comando CLI)
13. **Ordem das Uses (CRÍTICA)**: Devido à limitação de apenas um class helper por tipo no Delphi, a ordem nas cláusulas `uses` deve ser sempre: `Dext` → `Dext.Entity` → `Dext.Web`. O último sempre vence e garante visibilidade dos métodos Web (como `MapGet`, `AddWebStencils`).
14. **Smart Properties**: Para entidades, use sempre os aliases **IntType**, **StringType**, **DoubleType** e **BoolType** (de `Dext.Core.SmartTypes`) em vez de `Prop<T>`.
15. **Web Stencils `@(Prop(...))`**: Use sempre `@(Prop(item.Property))` dentro de blocos de expressão `@()`. No Delphi 13+, `@item.Property` simples pode funcionar em texto plano via auto-unwrap do HandleLookup, mas `@(Prop(...))` é sempre correto e seguro.
16. **Whitelist do Web Stencils**: `WhitelistEntities = True` é o padrão — todas as entidades ORM entram na whitelist automaticamente. Chame `WhiteList(TClass)` apenas para objetos que não são entidades (DTOs, view models).
17. **Records não são suportados** em templates Web Stencils (sem RTTI para valores de enumeradores).
18. **Supressão automática de layout com HTMX**: o Dext detecta o header `HX-Request` e suprime o layout. NÃO chame `.WithLayout('')` para partials HTMX — é automático.
19. **Dicionários de ViewData são case-insensitive**: `@PageTitle` e `@pagetitle` resolvem o mesmo valor.
