# S19: FluentQuery Join Evolution (Post V1 Final)

## Status
- **Planning only** (no implementation in RC1)
- **Current release phase**: V1 RC1
- **Execution window**: **after V1 Final**

## Objective
Define a safe and high-performance evolution path for `TFluentQuery` join capabilities, preserving ecosystem consistency and Dext principles:
- High performance
- Minimal/zero allocations in hot paths
- Backward compatibility
- Predictable behavior across ORM, specs, SQL generation, docs, and examples

This spec is intentionally separated from Issue #117 delivery.  
**Issue #117 remains the immediate focus for V1 RC1** (examples + docs).

---

## Context
Current join surface mixes two distinct execution models:
1. **SQL Join** via `Join(table, alias, joinType, condition)` (provider-translated SQL)
2. **Generic Join** via `Join<TInner, TKey, TResult>` (in-memory correlation)

Issue #117 highlighted discoverability and usage confusion between these two models.

---

## Non-Goals (for RC1)
The following are **not** to be shipped in RC1:
- Large API redesign of `TFluentQuery`
- Breaking changes in existing Join signatures
- SQL parser expansion beyond simple, deterministic cases
- New behavior that risks ORM performance regressions before V1 Final

---

## Scope (Post V1 Final)

## 1) API Clarity and Discoverability
### Goals
- Make SQL Join and in-memory Join behavior explicit in API and docs.
- Reduce ambiguity in naming and overload intent.

### Candidate actions
- Keep existing APIs source-compatible.
- Add explicit aliases (example: `JoinInMemory`) while preserving legacy `Join<TInner,...>`.
- Add XML docs warning for in-memory materialization behavior.

## 2) String Join Condition Helper
### Goals
- Keep ergonomic overload for simple `"left = right"` scenarios.
- Enforce strict and predictable parsing rules.

### Candidate actions
- Formalize grammar support for v1 helper:
  - exactly one equality predicate
  - no boolean chaining
  - no function parsing
- Clear exception messages for invalid formats.
- Document that complex ON expressions must use `IExpression`.

## 3) SQL Join Projection Ergonomics
### Goals
- Improve practical usability for joined result shapes without compromising performance.

### Candidate actions
- Evaluate typed projection helpers for SQL joins.
- Avoid runtime reflection-heavy projection in hot paths.

## 4) Diagnostics and Operability
### Goals
- Improve explainability/debugging of query translation.

### Candidate actions
- Evaluate `ToQueryString()`-style API for generated SQL + params.
- Query tagging (`TagWith`) for observability/tracing.

---

## Ecosystem Impact Assessment
Any post-Final change must be validated across:
- `Sources/Data/Dext.Entity.Query.pas`
- `Sources/Core/Dext.Specifications.*`
- SQL generator (`Dext.Specifications.SQL.Generator`)
- DbContext/DbSet query execution pipeline
- Examples (`Orm.EntityDemo`, others)
- Dext Book EN/PT-BR
- Unit/integration/performance test suites

### Compatibility rules
1. No breaking signature removals in first post-Final iteration.
2. Legacy behavior preserved unless clearly versioned/deprecated.
3. New APIs must be additive and documented.

---

## Performance and Allocation Constraints
All proposed changes must satisfy:
- No extra allocations per-row in materialization paths.
- No reflection churn in tight loops (cache or pre-bind where possible).
- SQL Join pipeline overhead must remain effectively constant-time per query build step.
- In-memory Join path must document and preserve current complexity expectations.

### Required benchmarks (minimum)
1. Join query build overhead (before/after)
2. SQL generation overhead for joined specs
3. In-memory Join throughput for medium/large sets
4. Allocation snapshots (baseline vs proposed)

Use existing benchmark infra from S18.

---

## Risk Register
1. **API confusion risk**: same name, different execution model  
Mitigation: explicit aliases + docs + examples

2. **Regression risk** in SQL translation  
Mitigation: golden tests for generated SQL and parameterization

3. **Performance risk** from convenience APIs  
Mitigation: micro-benchmarks + allocation guards

4. **Ecosystem drift risk** (docs/examples/code mismatch)  
Mitigation: synchronized update checklist in PR template

---

## Delivery Phases (Post V1 Final)
1. **Phase A (Safe Additive)**
- Documentation and naming clarity
- Alias APIs (if approved)
- Non-breaking helper APIs

2. **Phase B (Diagnostics)**
- Query explain/inspect API
- Optional tagging support

3. **Phase C (Ergonomic Projection)**
- Typed SQL join projection patterns
- Performance validation and hardening

---

## Acceptance Criteria (for S19 implementation cycle)
1. All Join modes are explicitly documented with execution model.
2. No breaking changes to existing join consumers.
3. Benchmarks show no unacceptable degradation (threshold from S18 policy).
4. EN/PT-BR docs and examples remain synchronized.
5. Unit + integration + example suite pass in CI.

---

## Immediate Priority Note
While this spec defines the post-Final roadmap, the **current active priority in RC1** is:
- Deliver Issue #117 with focused examples and documentation.

