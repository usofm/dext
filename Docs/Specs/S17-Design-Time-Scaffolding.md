# S17: Component-Based Design-Time Scaffolding

**Status:** Implemented (2026-05-06)

## 1. Visão Geral
Esta especificação define a implementação de recursos de Scaffolding diretamente na IDE do Delphi através de menus de contexto (Verbs) em componentes de dados. O objetivo é permitir que projetos legados ou novos comecem a usar o Dext Framework em segundos, gerando entidades POCO/Smart-Properties a partir de conexões ou queries existentes.

---

## 2. Escopo Técnico Implementado

### 2.1. Conexões (Database-First)
*   **Componente:** `TFDConnection` (FireDAC).
*   **Menu de Contexto:** `Dext: Generate Entities from Tables...`
*   **Funcionalidade:** 
    *   **Integração via Selection Editor:** Utiliza `TSelectionEditor` em vez de `TComponentEditor` para garantir que o menu do Dext seja agregado aos menus nativos do FireDAC, sem substituí-los.
    *   **Seleção Avançada (UX):** Diálogo customizado (`TTableSelectionForm`) construído via código (`CreateNew`) com filtro de busca em tempo real, botões de seleção em massa (Select/Unselect All) e contadores dinâmicos de visibilidade e seleção.

### 2.2. DataSets (Query-First / Field-First)
*   **Componentes:** `TFDQuery`, `TFDTable` e descendentes de `TDataSet`.
*   **Menu de Contexto:** `Dext: Create Entity from this Dataset...`
*   **Lógica de Especialização:**
    *   **Heurística de Metadados:** Detecção precisa de `AutoInc` via RTTI (`Field.AutoGenerateValue = arAutoInc`) e tipo de dados (`ftAutoInc`), corrigindo falhas de detecção baseadas apenas em `ProviderFlags`.
    *   **Segurança:** Validação de `FieldCount > 0` antes de iniciar a geração, abortando com aviso amigável caso o dataset esteja fechado ou vazio.
    *   **Mapeamento de Atributos:** Geração inteligente de `[PK]`, `[AutoInc]`, `[Required]` e `[Column('name')]` baseada no estado real do componente em design-time.

---

## 3. Fluxo de Geração e UI

### 3.1. Diálogo de Preview (Live Preview)
O Expert exibe uma janela de preview rica antes da persistência:
1.  **Editor de Código:** Utiliza `TMemo` com `AlignWithMargins` e fontes mono-espaçadas para visualização fiel.
2.  **Estatísticas Dinâmicas:** Rodapé com contagem de Entidades, Metadados (para POCO) e total de linhas de código gerado.
3.  **Configurações On-the-fly:** Permite alternar entre estilos **POCO** (Puro) e **Smart** (Dext Prop<T>) com rebuild imediato do código.
4.  **Caminho de Destino:** Sugestão inteligente baseada no projeto ativo, com opção de salvar diretamente no disco ou apenas abrir na IDE.

### 3.2. Integração com a IDE (IOTA)
*   **Associação ao Projeto:** Ao confirmar a criação, a nova unit é automaticamente adicionada ao projeto ativo (`IOTAModuleServices.GetActiveProject`).
*   **Buffer In-Memory:** O código é injetado via `IOTACreator`, aparecendo como uma nova aba pronta para uso, respeitando o fluxo de trabalho do desenvolvedor.

---

## 4. Inteligência de Codificação

### 4.1. Lógica de Nomenclatura (PascalCase Inteligente)
O motor de scaffolding foi aprimorado para garantir uma estética profissional:
*   **Tratamento de Acrônimos:** Implementação da regra de "Caps Consecutivos". Exemplo: `EmployeeID` -> `EmployeeId`, `HTTP_CLIENT` -> `HttpClient`.
*   **Preservação de MixedCase:** Se a coluna já estiver em PascalCase (ex: `ReportsTo`), o gerador mantém a formatação, removendo apenas caracteres inválidos.
*   **TitleCase para Legado:** Colunas em `ALL_CAPS` são convertidas suavemente para PascalCase.

---

## 5. Arquitetura e Motor

### 5.1. Execução In-Process (Expert BPL)
O Scaffolding via componentes é executado **in-process** dentro do pacote do Expert (`.bpl`).
*   **Acesso RTTI Seguro:** Uso de `TValue.AsOrdinal` para leitura de enums e propriedades ordinais de componentes de terceiros sem crashes de typecast.
*   **Syntax Compliance:** Código gerado seguindo rigorosamente as normas de sintaxe Pascal (ex: loops `for I := 0 to Count - 1`).

### 5.2. Relacionamento com o CLI (dext.exe)
O Scaffolding de Design-Time complementa o CLI:
*   **CLI:** Focado em engenharia reversa massiva e automação de CI/CD via `dext-schema.yaml`.
*   **IDE Expert:** Focado em produtividade imediata "ponto-a-ponto" durante o desenvolvimento de novas funcionalidades ou migração pontual de telas legadas.

---
*Documento consolidado e atualizado para refletir a implementação de alta fidelidade finalizada em 06/05/2026.*
