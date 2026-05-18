# Specification: S25 — Metrics & Health Monitoring

Esta especificação detalha o sistema de métricas em tempo real do Dext Sidecar, permitindo monitorar a performance e a saúde da infraestrutura da aplicação Delphi.

## 1. Conceitos de Métricas
Seguiremos o modelo **RED** (Rate, Errors, Duration) para APIs e o monitoramento de recursos de sistema.

*   **Counters:** Valores que apenas crescem (ex: total de requisições, total de erros).
*   **Gauges:** Valores instantâneos (ex: consumo de memória, threads ativas, conexões no pool).
*   **Histograms:** Distribuição de valores (ex: latência p95/p99).

## 2. Dashboards de Infraestrutura (Vistas Padrão)

### A. Runtime Health
*   **Memory Usage:** Gráfico de linha comparando `Working Set` vs `Private Bytes`.
*   **CPU Impact:** Percentual de CPU consumido pelo processo da aplicação.
*   **Thread Count:** Monitoramento de exaustão de threads (crucial para servidores Indy/HTTP).
*   **GC/Memory Manager:** No Delphi, monitorar a contagem de alocações ou fragmentação (via `GetMemoryManager`).

### B. Web API Performance (RED Dashboard)
*   **Throughput:** Gráfico de Requisições por Segundo (RPS).
*   **Error Rate:** % de respostas HTTP 4xx e 5xx.
*   **Latency:** Heatmap ou linha de tempo de resposta médio vs p95.

### C. Database Metrics
*   **Connection Pool:** Conexões ativas vs inativas no pool (FireDAC/Dext DB).
*   **Slow Queries:** Top 10 queries mais lentas detectadas via telemetria.

## 3. UI: Experiência Visual
A UI deve ser "Premium", utilizando componentes de gráfico leves e responsivos (ex: Chart.js ou uPlot).

*   **Grid Layout:** Widgets redimensionáveis.
*   **Time Picker:** Seleção de intervalo (Últimos 5 min, 30 min, 1 hora).
*   **Real-time Update:** Atualização via SSE ou polling inteligente (HTMX).

## 4. Implementação no Framework

### Coleta de Dados
1.  **Dext.Web.Metrics:** Middleware que intercepta toda requisição HTTP e emite métricas de duração/status.
2.  **Dext.Core.Metrics:** Sistema para o usuário definir métricas customizadas:
    ```delphi
    Metrics.Increment('orders_processed');
    Metrics.Gauge('active_users', 150);
    ```

### Exportação
*   As métricas são agregadas localmente (in-memory) e enviadas em "flushes" periódicos (ex: a cada 10s) para o Sidecar via `/api/telemetry/metrics`.

---
**Meta:** Prover uma visão holística da aplicação sem necessidade de configurar agentes externos pesados.
