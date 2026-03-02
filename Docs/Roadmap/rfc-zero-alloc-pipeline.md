# 🚀 RFC: Zero-Alloc Pipeline & Memory Optimization

## 📌 Visão Geral

Este documento define o plano tático para refatorar o fluxo crítico de execução do Dext Framework (Routing, Model Binding, Middlewares e ORM API). O objetivo principal é substituir coleções alocadas no Heap (`TList<T>`, `TStrings`, `TDictionary`) por alocações baseadas em Stack (`TVector<T>`) e spans dinâmicos, culminando na leitura avançada de JSON usando pointer de Offsets via `Prototype.Entity`.

## 🛡️ Regras de Engajamento (Rules of Engagement)

Para garantir que a performance não quebre a estabilidade do V1 RC, toda tentativa de otimização deve seguir estritamente o ciclo abaixo:

1. **Test-First (TDD-ish)**: Antes de tocar em qualquer linha do `Dext.Core` ou `Dext.Web`, o caso de uso *deve* estar coberto por um teste unitário em `Tests\`.
2. **Green Baseline**: Os testes devem compilar e passar com a implementação atual (lenta/alocada).
3. **Benchmark Baseline**: Antes de refatorar uma classe (ex: `TRouter`), criamos um micro-benchmark para registrar as nanosegundos e contagem de alocações atuais e gravamos o resultado no histórico.
4. **Cirurgia Segura**: Fazemos a alteração para `TVector<T>` ou Injeção por Offset (JSON).
5. **Validation**: Rodamos a suíte inteira de unit tests (os 140+ já existentes + os novos). Se quebrar, reverte ou conserta.
6. **Benchmark Final (Delta)**: Rodamos o benchmark novamente para atestar o ganho real e validar a ausência de regressões.

---

## 🎯 Fases de Execução & Mapeamento de Alvos

### Fase 1: Enxugando a Web Pipeline (Roteamento & Middlewares)

A Web Pipeline executa milhares de vezes por segundo. O GC não deveria trabalhar aqui.

- **Alvo 1: Engine de Roteamento (`Dext.Web.Routing` / Equivalentes)**
  - Onde dói: Path splitting (`/api/users/{id}`) frequentemente usa `SplitString`, gerando múltiplos objetos de Array/TStrings.
  - Cura: Substituir processamento de strings por spans (`TByteSpan`) e `TVector<string>` na Stack.
- **Alvo 2: Middleware Chain Executions**
  - Onde dói: Construir a cadeia de execução pode usar arrays/listas temporárias desnecessárias.
  - Cura: Utilizar nossas novas Coleções (`IList<T>`) que não geram bloat ou `TVector`.

### Fase 2: O Caminho de Volta do Banco (ORM Query Builder)

A fluidez custa memória. Vamos baratear a fluent API.

- **Alvo 3: Montagem das `Specifications` e Constraints**
  - Onde dói: A cada chamada de `.Where()`, `.Sort()`, nodes e estruturas em árvore podem ser alocadas. Coleções intermediárias são jogadas fora ao dar o `.ToList`.
  - Cura: Usar arrays curtos em stack (`TVector<T>`) para agrupar os fragmentos da Query até a compilação final pro dialeto (SQL).

### Fase 3: Model Binding JSON Extremo (Direct Memory Inject)

A joia da coroa. Pular a via-sacra da RTTI tradicional durante o Parsing JSON.

- **Alvo 4: JSON para Interfaces/Classes via Offset**
  - Onde dói: O parser lê o JSON, gera Dicionários, chama o Rtti Context, acha a Property, invoca o método setter Virtual. Multiplique isso por milhares de registros.
  - Cura:
    1. O Parser analisa a memória bruta (JSON Binário).
    2. Lê o `Prototype.Entity<T>` para buscar os Offsets de memória físicos cacheados dos tributos.
    3. Escreve os bytes parseados diretamente no endereço do field: `PInteger(PByte(Obj) + Offset)^ := Value`.

### Fase 4: HTTP Request Zero-Alloc Pipeline (Gordura de Requisição)

**Objetivo:** Eliminar qualquer alocação na Heap que seja triggada cada vez que uma request bate nos WebHosts Indy (Ex: Dicionários fantasmas criados sem que o programador solicite o dado).

- [x] Converter retorno de `GetQuery` em `IHttpRequest` para struct-view `TQueryDictionary` lazy-loaded.
- [x] Converter retorno de `GetHeaders` no Request/Response para struct-view (Não copiar da `TIdHeaderList`)
- [x] Otimizar retorno de `GetCookies` em `IHttpRequest` de `IDictionary` para struct-view de array.
- [x] Aplicar Lazy-Loading estrito na propriedade `FItems` do `TIndyHttpContext` (que hoje engole memória em toda requisição, incondicionalmente).

---

## 📈 Rastreamento e Logs

Todas as evoluções serão registradas em um diário de Benchmarks na pasta (a ser criada) `/Benchmarks/ZeroAlloc/`. Qualquer PR que reduza a performance em relação à Baseline será considerada uma [Regressão] e será vetada.

**Status Finalizado**: Todas as fases (1 a 4) concluídas com sucesso. O pipeline completo do Dext Framework agora opera em regime Zero-Allocation.
