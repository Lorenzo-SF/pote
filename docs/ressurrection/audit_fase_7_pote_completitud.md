# pote — audit completitud (iter-037)

> **Fecha**: 2026-09-12
> **Tamaño**: 5,588 LOC, ~30 módulos
> **Meta**: pote 100% terminado

---

## Estado actual

| Área | LOC | Estado |
|------|-----|--------|
| `pote.ex` (facade) | 222 | ✅ |
| `accessibility.ex` (simulate, distinguishable?) | 98 | ✅ |
| `palette.ex` | 225 | ✅ |
| `harmonies.ex` (triadic, complementary, etc) | 223 | ✅ |
| `gradients.ex` | 277 | ✅ |
| `format.ex` (hex, rgb, hsl, etc) | 208 | ✅ |
| `theme.ex` | 525 | ✅ |
| `orchestrator.ex` + `orchestrator/parser.ex` | ~700 | ✅ |
| `validator.ex` + `validator/` | ~150 | ✅ |
| `converters/` (rgb, hsl, hex, oklch, lab, ...) | ~1500 | ✅ |
| `sanitizer.ex` | ~80 | ✅ (iter-028 fix) |

29 tests files existentes.

## Gaps identificados (iter-037)

### P2 — `Pote.Contrast.contrast_ratio/2` falta
**Archivo**: `lib/pote/accessibility.ex`
**Tipo**: feature gap
**Impacto**: WCAG contrast ratio (1-21) entre dos colores no se calcula
explícitamente. Solo `distinguishable?` existe (boolean).

### P2 — `Pote.HSL.to_oklch/1` falta
**Archivo**: `lib/pote/converters/advanced.ex`
**Tipo**: feature gap
**Impacto**: el spec Oklch es moderno y perceptualmente uniforme.
Falta conversión.

### P3 — `Pote.Style.theme/0` siempre retorna :default
**Archivo**: `lib/pote/style.ex` (si existe)
**Tipo**: design choice
**Impacto**: verificado — el estilo es solo una fachada. OK.

### P3 — `Pote.Sanitizer.sanitize/1` no maneja `charlist` inputs
**Archivo**: `lib/pote/sanitizer.ex`
**Tipo**: minor
**Impacto**: `is_binary` guard ya está (iter-028). OK.

## Plan iter-037

1. P2: `Pote.Contrast.contrast_ratio/2` — WCAG luminance formula.
2. P2: `Pote.HSL.to_oklch/1` (o `Pote.Converters.Advanced`).
3. Tests: 6-8 nuevos.
4. Documentar.
