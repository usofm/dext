# Specification: S26 — Interactive Test Runner (Premium Edition)

Esta especificação detalha a evolução do Test Runner do Dext Sidecar para uma ferramenta de produtividade de elite, integrando execução reativa, telemetria e cobertura de código.

## 1. Interface de Execução Reativa

### A. Test Tree Explorer
*   **Visual Hierárquico:** Árvore organizada por `Project > Unit > Fixture > Method`.
*   **Smart Filtering:** Filtrar por nome, status (Passed, Failed, Skipped) ou tags.
*   **Execução Granular:** Botão "Run" em cada nível da árvore (executar apenas uma Fixture ou um único Teste).

### B. Live Result Stream
*   **Progresso Visual:** Barra de progresso circular ou linear no topo.
*   **Instant Feedback:** Ícones de status (Checkmark verde / X vermelho) aparecendo em tempo real conforme os testes terminam via SSE.

## 2. Deep Integration (Observability Correlation)

O grande diferencial do Dext Sidecar:
*   **Test-to-Log Link:** Ao selecionar um teste falho, o Dashboard filtra automaticamente o log do **Live Stream** para mostrar apenas os logs emitidos *durante* a execução daquele teste específico (usando o `SpanId` do teste).
*   **Diff Viewer:** Para falhas de asserção, mostrar um diff visual entre o valor `Expected` e `Actual`.

## 3. Visual Code Coverage
*   **Coverage Overlay:** Integrar o relatório de cobertura diretamente na visualização de arquivos.
*   **Heatmap:** Mostrar quais Fixtures/Units têm menos cobertura diretamente na árvore de testes.
*   **Drill-down:** Clicar em uma porcentagem e abrir o relatório HTML detalhado em um frame dentro do Sidecar.

## 4. Workflows de Desenvolvedor
*   **Watch Mode (TDD):** Opção de monitorar mudanças em arquivos `.pas` e re-executar automaticamente os testes afetados.
*   **Failure Persistence:** Manter o histórico das últimas 5 execuções para análise de flakiness.

---
**Meta:** Tornar o ciclo de feedback do desenvolvedor o mais curto e informativo possível, eliminando a necessidade de alternar entre IDE, Console e Navegador.
