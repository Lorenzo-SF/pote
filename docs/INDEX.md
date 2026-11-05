# Pote — Document Index

> v2.2.0 — Colorimetry and theme/palette management for Elixir

| Document | Description |
|----------|-------------|
| [`ARCHITECTURE.md`](./ARCHITECTURE.md) | Complete design reference: subsystems (Orchestrator, Format handlers, Converters, Harmonies, Gradients, Theme system), dependencies, key decisions |
| [`AUDIT.md`](./AUDIT.md) | Code quality audit: coverage (93.2%), floating-point precision, typespec gaps, dead code, top 5 fixes |
| [`README.md`](../README.md) | English README — installation, usage, API overview |
| [`docs/README.es.md`](./README.es.md) | Spanish README |
| [`CHANGELOG.md`](../CHANGELOG.md) | Version history and release notes |
| [`LICENSE.md`](../LICENSE.md) | MIT License |
| [`plan_pote.md`](./plan_pote.md) | Historical refactoring plan (converter consolidation) |

### Ecosystem context

Pote is the **color foundation** of the Lorenzo-SF ecosystem. It is consumed
by Alaja (for terminal rendering) and indirectly by all CLI tools. See the
[dependency graph](../docs/ARCHITECTURE.md#5-consumed-by).
