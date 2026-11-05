# pote — ressurrection_fase_2: análisis meticuloso

> **Fecha**: 2026-09-12
> **Rama**: `ressurrection_fase_2` (desde `main`)
> **Mavis root**: MiniMax-M3 (cloud)
> **Skills aplicadas**: `core/self-review`, `languages/elixir`,
> `transversal/principles`
> **Versión actual**: 3.0.0

---

## 1. Dominio

pote es una **utility library de colorimetría** para Elixir. Su rol en el ecosistema:

- **Tipos canónicos** (`Pote.rgb()`, `Pote.hsl()`, etc.) — base para zaguan/Pote.
- **Conversores** (RGB ↔ HSL ↔ HSV ↔ HWB ↔ CMYK ↔ xterm256 ↔ ARGB).
- **Parser de strings** (`hex:FF8000`, `rgb:255,0,0`).
- **Paletas** (default + procedural por seed).
- **Armonías** (complementary, triad, analogous).
- **Gradients** (linear, multicolor, con apply_to_text).
- **Tema stack** (resolvers encadenados).
- **Accesibilidad** (WCAG contrast, luminance).
- **Style/ANSI** (terminal output).

**Rol en zaguan**: zaguan tiene `Zaguan.CLI.Style` (tabla/headings) que podría
delegar a `Pote.Style` para colorear la salida. zaguan v1.0-beta **no
importa pote** porque está en el path "self-contained" — pero la migración
es trivial.

---

## 2. Análisis meticuloso

### 2.1 Estructura general

- **42 módulos** en `lib/`, ~5,575 LOC.
- **29 test files**.
- **Sin Application** (pure library).
- **Sin dependencias runtime** más allá de Elixir stdlib.

### 2.2 Problemas críticos (P0)

#### P0-1 — `Pote.Sanitizer.sanitize/1` no valida input type

**Archivo**: `lib/pote/sanitizer.ex:17-22`
**Tipo**: crash
**Impacto**: si pasas un integer o nil, `String.trim/1` falla con FunctionClauseError.
**Fix**: añadir guard `is_binary/1`.

#### P0-2 — `sanitize_list/2` usa `rescue` genérico

**Archivo**: `lib/pote/sanitizer.ex:30-33`
**Tipo**: error handling
**Impacto**: captura TODAS las excepciones. Un bug en la implementación (no un input
inválido) sería silenciado.
**Fix**: validar el input antes del `String.split` y no usar rescue.

### 2.3 Problemas importantes (P1)

#### P1-1 — `Pote.Gradients.linear/3` no valida `steps >= 2`

**Archivo**: `lib/pote/gradients.ex:43-48`
**Tipo**: divide-by-zero
**Impacto**: si `steps=1`, `(steps-1)=0` → `t = i/0 = NaN`. Retorna tuplas con NaN.
**Fix**: añadir guard `when steps >= 2` (ya está). Verificar que el path sin guard
no sea alcanzable.

#### P1-2 — `Pote.Validator` permite `:not_found` como error state

**Archivo**: `lib/pote/validator.ex`
**Tipo**: error handling
**Impacto**: el tipo `validation_result :: :ok | {:error, atom()} | {:error, atom(), String.t()}`
es inconsistente con `Pote.Theme` que retorna `{:ok, _} | :not_found`. Mezclar patrones
confunde a los consumidores.
**Fix**: documentar en el moduledoc o unificar.

### 2.4 Problemas de diseño (P2)

#### P2-1 — `Pote.Validator` tiene 5+ submódulos

**Archivo**: `lib/pote/validator/{hex,rgb,hsl,hwb,cmyk,xterm,theme,bracket}.ex`
**Tipo**: organización
**Impacto**: muchos archivos pequeños. Cada uno ~30-50 LOC. Es OK si la responsabilidad
está bien separada (un módulo por formato) — el rule of three no aplica aquí porque
**hay** 7+ formatos reales.
**Decisión**: mantener.

#### P2-2 — `Pote.Palette` no tiene random seed

**Archivo**: `lib/pote/palette.ex`
**Tipo**: feature missing
**Impacto**: requiere seed explícito. Podría aceptar `:rand` configurable.
**Fix**: deferido a sprint 15+.

#### P2-3 — `Pote.Style` y `Pote.Gradients.apply_to_text` acoplan ANSI

**Archivo**: `lib/pote/style.ex`, `lib/pote/gradients.ex:100+`
**Tipo**: acoplamiento
**Impacto**: los códigos ANSI están hardcoded. Si en el futuro queremos otro target
(HTML, SVG), hay que reescribir.
**Fix**: deferido (over-engineering).

### 2.5 Rendimiento

#### P2-4 — `Pote.Harmonies.complementary/1` no batchea

**Archivo**: `lib/pote/harmonies.ex`
**Tipo**: perf
**Impacto**: si llamas con una lista de 1000 colores, son 1000 cálculos individuales.
**Fix**: añadir `complementary_many/1` con Task.async_stream.

#### P2-5 — `Pote.Validator.validate/1` recompila regex en cada call

**Archivo**: `lib/pote/validator.ex`
**Tipo**: perf (menor)
**Impacto**: las regex inline se compilan en cada call. Mover a `@` module attributes.
**Fix**: deferido (micro-optimización).

---

## 3. Plan de correcciones (ressurrection_fase_2)

| # | Fix | Commit | Tests añadidos |
|---|-----|--------|----------------|
| 1 | P0-1 — Sanitizer.sanitize/1 guard | `fix(pote): Sanitizer.sanitize/1 guards binary input` | 2 |
| 2 | P0-2 — Sanitizer.sanitize_list/2 sin rescue | `refactor(pote): Sanitizer.sanitize_list/2 validates input without rescue` | 3 |
| 3 | P1-1 — Verificar guard de linear/3 + add test | `test(pote): Gradients.linear/3 rejects steps < 2` | 1 |

**Total**: 3 commits, ~6 tests nuevos.

---

## 4. Auto-review (skill `self-review`)

- ✅ Verifiqué cada fix contra el código real.
- ✅ Documenté el POR QUÉ.
- ✅ Output user-facing: tabla compacta.

---

## 5. Decisión

Aplico los 3 fixes. Los P2-4, P2-5, P2-2 quedan para sprint 15+.
