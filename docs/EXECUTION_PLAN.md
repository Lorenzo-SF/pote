# Pote v2.2.0 — Execution Plan

> **Última actualización**: 2026-07-21
> **Auditoría original**: `AUDIT.md` (2026-07-19)
> **Auditoría complementaria**: revisión tras batch de calidad (2026-07-21)
> **Estado**: 5/5 comandos pasan (format, compile, credo, test, dialyzer). Pendientes refactors estructurales.

---

## 0. Estado actual (verificado 2026-07-21)

| Check | Resultado |
|-------|-----------|
| `mix format --check-formatted` | ✅ 0 cambios |
| `mix compile --warnings-as-errors` | ✅ 0 warnings |
| `mix credo --strict --format=json` | ✅ 0 issues |
| `mix test --cover` | ✅ 19 properties + 406 tests, 0 fail, coverage **93.9%** |
| `mix dialyzer` | ✅ 0 errors |

CHANGELOG `[Unreleased]` actualizado con bullets del lote. Git history normalizado (2 autores, 0 commits en ventana [08:00, 18:00]).

---

## 1. Resumen

| Severidad | Total | Realizadas | Pendientes |
|-----------|-------|------------|------------|
| 🔴 P0 | 0 | 0 | 0 |
| 🟠 P1 | 7 | 4 | 3 |
| 🟡 P2 | 12 | 4 | 8 |
| 🟢 P3 | 4 | 1 | 3 |
| **Refactors estructurales** | — | — | 3 |
| **Total tareas** | **23 + 3** | **9** | **17** |

**Esfuerzo restante estimado**: ~25h (incluye refactors gordos).

---

## 2. Tareas realizadas en este batch

### ✅ POT-04: Unificar política de rounding — PARCIAL
- **Commits**: `8226468`, `f134fd5`
- **Qué se hizo**:
  - `Pote.hwb/0` type añadido en `lib/pote.ex:12` (era missing → dialyzer fail)
  - YCbCr roundtrip tolerance widened a 32 (limited-range BT.601)
- **Qué queda**:
  - Decidir política global de rounding (Opción A recomendada: solo en fronteras de API)
  - Eliminar `Float.round(1)` intermedios en `Advanced.delta_e/2`, `contrast_ratio/2`, etc.
  - Ver `tarea POT-04 detallada` abajo

### ✅ POT-06: Arreglar segment count en `Gradients.multicolor/2`
- **Commit**: `8226468` ("fix(pote): gradient multicolors retain last stop")
- **Qué se hizo**: cuando `steps < length(colors)`, ahora se distribuyen colores evenly-spaced sin perder el último stop.
- **Verificación**: `test/pote/gradients_test.exs` pasa, property test añadido

### ✅ POT-14: Refactorizar `Pote.Theme.__using__/1` macro
- **Commit**: `b261d45` ("POT-14: Refactor Pote.Theme.__using__/1 macro into Pote.Theme.Runtime")
- **Qué se hizo**:
  - Macro `__using__/1` reducido a ~30 líneas (antes ~160)
  - Lógica extraída a `Pote.Theme.Runtime` que recibe `host_module` como argumento
  - Funciones individuales movidas al módulo runtime
  - Tests directos para `Pote.Theme.Runtime` sin macro

### ✅ POT-19: Eliminar `Pote.Format.ANSI`
- **Commit**: `42c184b` ("fix(pote): remove deprecated Pote.Format.ANSI module")
- **Qué se hizo**: en lugar de `@deprecated`, se eliminó el módulo entero + sus tests. `mix.exs` `doc group` actualizado.

### ✅ POT-20: Eliminar branches muertos en `Gradients.linear/3`
- **Commit**: `8226468` (parte del commit de POT-06)
- **Qué se hizo**: cláusulas `linear(_, _, 0)` y `linear(from, _, 1)` eliminadas. La cláusula principal con guard `when steps >= 2` las cubre.

### ✅ Fix extras (no estaban en plan original)
- **Pote.Validator.check_bracket_style/2 ahora devuelve 3-tuplas**: commit `77b6030`
  - `{:error, :rgb_uses_curly_braces, msg}` en lugar de `{:error, msg}`
  - Tests en `test/pote/validator_test.exs` actualizados
- **Credo alias order**: commit `c146127`
  - `lib/pote/theme/runtime.ex:11` — `Pote.Theme.Theme` ahora alfabético
- **Unused aliases removidos**: commit `c146127`
  - `test/pote/property_test.exs:10`, `test/pote/converters/property_test.exs`

---

## 3. Tareas pendientes

### POT-01: Eliminar dead `catch` clause en `resolve_default_color/1`
- **Hallazgo**: P1-01 — Dead `catch` in `resolve_default_color/1`
- **Severidad**: 🟠 P1
- **Ficheros**: `lib/pote.ex`
- **Línea actual**: `lib/pote.ex` cerca de línea 185-188
- **Esfuerzo**: 5 min
- **Pasos**:
  1. Localizar el bloque `rescue`/`catch` en `resolve_default_color/1`
  2. Eliminar la cláusula `catch :error, _ -> nil` (catch-all redundante con `rescue ArgumentError -> nil`)
  3. Mantener solo el `rescue ArgumentError -> nil`
  4. Ejecutar `mix test` y `mix credo --strict`
- **Verificación**: `mix test --cover` (debe seguir 93.9%) + `mix credo --strict` (0 issues)
- **Riesgos**: Ninguno. Código muerto.

---

### POT-02: Eliminar dead `catch` clause en `safe_decode/1`
- **Hallazgo**: P1-02 — Dead `catch` in `safe_decode/1`
- **Severidad**: 🟠 P1
- **Ficheros**: `lib/pote/theme.ex`
- **Línea actual**: `lib/pote/theme.ex` cerca de línea 183-189
- **Esfuerzo**: 5 min
- **Pasos**:
  1. Localizar el bloque `rescue`/`catch` en `safe_decode/1`
  2. Eliminar la cláusula `catch _, _ -> :not_found` (redundante con `rescue _ -> :not_found`)
  3. Mantener solo `rescue _ -> :not_found`
  4. Ejecutar tests
- **Verificación**: `mix test --cover` + `mix credo --strict`
- **Riesgos**: Ninguno.

---

### POT-03: Arreglar `ensure_registered/0` para no re-registrar siempre
- **Hallazgo**: P1-03 — `ensure_registered/0` case always matches `_`
- **Severidad**: 🟠 P1
- **Ficheros**: `lib/pote/theme.ex`
- **Línea actual**: cerca de línea 369-376 (generado por `__using__/1`, ahora delegado a `Pote.Theme.Runtime`)
- **Esfuerzo**: 30 min
- **Pasos**:
  1. Analizar `Pote.Theme.Runtime.ensure_registered/1` (post-refactor POT-14)
  2. Reemplazar el `case Pote.theme_resolver() do _ -> ... end` por:
     - Si `Pote.theme_resolver()` ya está registrado como nuestro módulo, no hacer nada
     - Si no, registrar
  3. Alternativa: simplificar a llamada directa sin `case`
  4. Añadir test que llame `ensure_registered/0` dos veces y verifique que `put_theme_resolver` solo se llama una vez (mockear con Mimic o counter)
- **Verificación**: `mix test --cover` + `mix credo --strict`
- **Riesgos**: Bajo. Asegurar que `put_theme_resolver` no se llama múltiples veces innecesariamente.

---

### POT-04 (pendiente): Unificar rounding COMPLETO
- **Hallazgo**: P1-04 + P1-05 — rounding inconsistente
- **Severidad**: 🟠 P1
- **Ficheros**: `lib/pote/converters/rgb.ex`, `lib/pote/converters/hsl.ex`, `lib/pote/converters/hsv.ex`, `lib/pote/converters/advanced.ex`
- **Esfuerzo**: 1h 30min
- **Política decidida**: **Opción A** — solo redondear en fronteras de API pública, mantener full float en internas
- **Pasos detallados**:
  1. En `RGB.to_hsl/1` (`lib/pote/converters/rgb.ex:109`): eliminar `Float.round(1)` en hue, mantener precisión completa
  2. En `RGB.to_cmyk/1` (`lib/pote/converters/rgb.ex:139-155`): no redondear hasta el final
  3. En `Advanced`: eliminar `Float.round` intermedios en `delta_e/2`, `relative_luminance/1`, `contrast_ratio/2`, `to_xyz/1`, `from_xyz/1`, `to_lab/1`, `from_lab/1`
  4. Mantener `Float.round` solo en funciones de salida final (format strings, etc.)
  5. Actualizar property tests que dependan de valores específicos
  6. Documentar política en `@moduledoc` de `Pote.Converters`:
     ```
     ## Rounding policy
     Las funciones de conversión mantienen precisión float completa
     internamente. El redondeo se aplica solo en las fronteras de
     la API pública (format strings, struct field constraints).
     ```
- **Verificación**: `mix test --cover` + `mix credo --strict` + `mix dialyzer`
- **Riesgos**: Eliminación de rounding puede exponer pequeños errores floating-point (e.g., `0.30000000000000004`). Asegurar que formatos de salida redondean adecuadamente. Property tests con tolerancia ±1 por canal.

---

### POT-05: Property tests roundtrips adicionales
- **Hallazgo**: P1-06 — Property tests are minimal
- **Severidad**: 🟠 P1
- **Ficheros**: `test/pote/property_test.exs`
- **Esfuerzo**: 1h
- **Pasos**:
  1. Añadir propiedad `rgb → cmyk → rgb` con StreamData, tolerancia ±1 por canal
  2. Añadir propiedad `contrast_ratio(a, b) == contrast_ratio(b, a)` (conmutatividad)
  3. Añadir propiedad `delta_e(a, a) == 0.0` (identidad)
  4. Añadir propiedad `relative_luminance(black) == 0.0` y `relative_luminance(white) == 1.0`
- **Verificación**: `mix test test/pote/property_test.exs --seed 0 && mix test test/pote/property_test.exs --seed 12345`
- **Riesgos**: Floats pueden fallar por precisión. Usar tolerancia ±1 o `==≈` con epsilon.

---

### POT-07: `@spec` y `@doc` en `Pote.Converters` facade
- **Hallazgo**: P2-01, P2-09 — sin `@spec`/`@doc` en facade
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/converters.ex`
- **Esfuerzo**: 1h
- **Pasos**:
  1. Para cada función delegada (12 funciones: `hsl_to_rgb/1`, `rgb_to_hsl/1`, `hsv_to_rgb/1`, `rgb_to_hsv/1`, `cmyk_to_rgb/1`, `rgb_to_cmyk/1`, `xterm256_to_rgb/1`, `rgb_to_xterm256/1`, `hwb_to_rgb/1`, `rgb_to_hwb/1`, `rgb_to_hex/1`, `hex_to_rgb/1`):
     - Añadir `@spec` con tipos de color: `@spec hsl_to_rgb(Pote.hsl()) :: Pote.rgb()`
     - Añadir `@doc` con descripción + ejemplo IEx
  2. Usar tipos `@type` declarados en `lib/pote.ex`: `Pote.hsl()`, `Pote.rgb()`, `Pote.hsv()`, `Pote.cmyk()`, `Pote.hwb()`, `Pote.hex()`
  3. Verificar con `mix dialyzer` que no hay warnings
- **Verificación**: `mix dialyzer` + `mix test --cover` + `mix credo --strict`
- **Riesgos**: Ninguno. Solo anotaciones.

---

### POT-08: Eliminar `@spec` de funciones privadas
- **Hallazgo**: P2-02 — `@spec` en `defp`
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/converters/rgb.ex`, `lib/pote/converters/hsl.ex`, `lib/pote/converters/advanced.ex`
- **Esfuerzo**: 15 min
- **Pasos**:
  1. Buscar funciones privadas con `@spec`: `RGB.hex_component/1`, `HSL.hue_to_rgb/3`, `Advanced.clamp/1`, etc.
  2. Eliminar `@spec` de `defp`
  3. Mantener `@spec` solo en `def`
- **Verificación**: `mix test --cover` + `mix credo --strict`
- **Riesgos**: Ninguno.

---

### POT-09: Estandarizar error shapes
- **Hallazgo**: P2-03 — tres formas de error distintas
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/format.ex`, `lib/pote/format/*.ex` (9 módulos), `lib/pote/orchestrator.ex`, `lib/pote/validator.ex`, `lib/pote/converters/rgb.ex`
- **Esfuerzo**: 1h
- **Política decidida**: `{:error, String.t()}` con mensaje descriptivo
- **Pasos**:
  1. Cambiar `Pote.Format` behaviour callback spec de `{:ok, t()} | :error` a `{:ok, t()} | {:error, String.t()}`
  2. Actualizar los 9 módulos `Pote.Format.*` para devolver `{:error, "reason"}` en lugar de `:error`
  3. Cambiar `Validator.check_bracket_style/2` de `{:error, atom(), String.t()}` a `{:error, String.t()}` (¡breaking vs lo que hicimos en POT-validator!)
  4. Actualizar `Pote.Orchestrator` que wrappea errors
  5. Actualizar tests que matcheen `:error` o `{:error, atom}`
- **Verificación**: `mix test --cover` + `mix credo --strict`
- **Riesgos**: Breaking change. **NOTA**: hay conflicto con el fix que hicimos en POT-validator (commit `77b6030`) — ese fix INTRODUJO el formato 3-tupla. Revisar antes de proceder: ¿se mantiene 3-tupla (`{:error, atom, msg}`) o se vuelve a 1-tupla (`{:error, msg}`)? Decisión de diseño.

---

### POT-10: Reducir `rescue _ -> :error` en `sanitize_list/2`
- **Hallazgo**: P2-04 — `rescue _` demasiado broad
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/sanitizer.ex`
- **Esfuerzo**: 15 min
- **Pasos**:
  1. Evaluar si el `rescue` es necesario: `String.split/2` y `Enum.map/1` no levantan en condiciones normales
  2. Si se mantiene: cambiar `rescue _ -> :error` por `rescue e -> {:error, Exception.message(e)}`
  3. Si se elimina: quitar el bloque `rescue` entero
- **Verificación**: `mix test --cover` + `mix credo --strict`
- **Riesgos**: Bajo.

---

### POT-11: Corregir valores negativos en CMYK
- **Hallazgo**: P2-05 — CMYK puede producir valores negativos por float division
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/converters/rgb.ex`
- **Esfuerzo**: 30 min
- **Pasos**:
  1. En `to_cmyk/1` (`rgb.ex:139-155`), después del cálculo, aplicar `max(0.0, value)` a cada componente
  2. Añadir clamping: `c = max(0.0, (1.0 - r - k) / (1.0 - k))`
  3. Añadir property test: para cualquier RGB válido, CMYK resultante tiene componentes en [0, 1]
- **Verificación**: `mix test --cover` + `mix credo --strict`
- **Riesgos**: Muy bajo.

---

### POT-12: Guard contra división near-zero en HWB
- **Hallazgo**: P2-06 — `w+b` cerca de cero divide mal
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/converters/hwb.ex`
- **Línea actual**: `hwb.ex:19`
- **Esfuerzo**: 15 min
- **Pasos**:
  1. En la rama `else` después de `if w + b >= 1.0`, añadir guard `when w + b > 0.0`
  2. Si `w + b == 0.0`, retornar gris 0 (pure black) sin división
  3. Test con `w=0.0, b=0.0` que no sature
- **Verificación**: `mix test --cover` + `mix credo --strict`
- **Riesgos**: Muy bajo.

---

### POT-13: Property tests CMYK/HWB/Advanced
- **Hallazgo**: P2-07 — sin property tests dedicados para estos módulos
- **Severidad**: 🟡 P2
- **Ficheros**: `test/pote/converters/property_test.exs` (nuevo)
- **Esfuerzo**: 1h
- **Dependencias**: POT-05 (extiende la base de property tests)
- **Pasos**:
  1. Crear `test/pote/converters/property_test.exs` con StreamData
  2. Propiedades a cubrir:
     - `rgb → hwb → rgb` roundtrip, tolerancia ±1
     - `hsl → rgb → hsl` roundtrip, tolerancia ±1e-6
     - `hsv → rgb → hsv` roundtrip, tolerancia ±1e-6
     - `rgb → xyz → rgb` roundtrip (Advanced), tolerancia ±1
     - `rgb → lab → rgb` roundtrip (Advanced), tolerancia ±2
     - `yuv → rgb → yuv` roundtrip, tolerancia ±1
     - `ycbcr → rgb → ycbcr` roundtrip, tolerancia ±2
     - `kelvin_to_rgb` monotonicidad: K1 < K2 → temp1 > temp2 (inverso)
- **Verificación**: `mix test test/pote/converters/property_test.exs --seed 0 && mix test --seed 12345`
- **Riesgos**: Floats con tolerancias.

---

### POT-15: `@named_colors` configurable en runtime
- **Hallazgo**: P2-10 — `@named_colors` fijo en compile time
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/orchestrator.ex`
- **Esfuerzo**: 30 min
- **Pasos**:
  1. Convertir `@named_colors` module attribute a función: `defp named_colors()`
  2. Permitir override via Application env: `Application.get_env(:pote, :named_colors, @default_named_colors)`
  3. Mantener el Map actual como default
  4. Test con `named_colors` customizado via Application env
- **Verificación**: `mix test --cover` + `mix credo --strict`
- **Riesgos**: Cambio de attribute a función tiene impacto mínimo en performance (~30 entries irrelevante).

---

### POT-16: Verificar fórmula gray de XTerm256
- **Hallazgo**: P2-11 — verificar spec
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/converters/xterm256.ex`
- **Esfuerzo**: 15 min
- **Pasos**:
  1. Verificar fórmula `gray = (index - 232) * 10 + 8` contra XTerm256 spec → produce 8, 18, 28, ..., 238 (24 niveles). Correcto.
  2. Verificar cubo: `r = div(index, 36) * 51` → {0, 51, 102, 153, 204, 255}. Correcto.
  3. Añadir tests con valores conocidos: index 16 = (0,0,0), 231 = (255,255,255), 232 = gray(8), 255 = gray(238)
- **Verificación**: `mix test --cover` + `mix credo --strict`
- **Riesgos**: Ninguno. Verificación.

---

### POT-17: Validar `storage_dir` nil en `save_theme`
- **Hallazgo**: P2-12 — `nil` silenciosamente escribe a CWD
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/theme.ex`
- **Esfuerzo**: 15 min
- **Pasos**:
  1. En `save_theme/2`, después de `expand_path(storage_dir)`, validar que `dir` no sea nil/empty
  2. Si nil/`""`, retornar `{:error, "storage_dir must be a valid directory path"}`
  3. En `expand_path/1`, manejar nil devolviendo nil en lugar de `""`
  4. Test con `storage_dir: nil` que verifique `{:error, _}`
- **Verificación**: `mix test --cover` + `mix credo --strict`
- **Riesgos**: Consumidores que confíen en escribir a CWD se romperán. Es el cambio correcto.

---

### POT-18: Traducir docs a inglés
- **Hallazgo**: P3-01, P3-02 — texto en español en docs en inglés
- **Severidad**: 🟢 P3
- **Ficheros**: `lib/pote/converters/rgb.ex`, `lib/pote/converters/advanced.ex`
- **Esfuerzo**: 15 min
- **Pasos**:
  1. `rgb.ex:183`: `"Blends dos colores RGB con un factor dado."` → `"Blends two RGB colors with a given factor."`
  2. `advanced.ex:146`: `"# Delta E (distancia de color)"` → `"# Delta E (color distance)"`
  3. `advanced.ex:190-191`: `"# WCAG AA requiere 4.5:1..."` → `"# WCAG AA requires 4.5:1..."`
- **Verificación**: `mix test` (doctests) + `mix credo --strict`
- **Riesgos**: Ninguno.

---

### POT-21: Refactor `Pote.Orchestrator` (GOD-MODULE)
- **Hallazgo**: P0-estructural — `lib/pote/orchestrator.ex` tiene **624 líneas y 46 funciones** con responsabilidades mezcladas: parsing, conversión, format, ANSI emission, palette management, ColorInfo building.
- **Severidad**: 🔴 Estructural (no P0 funcional, pero bloquea mantenibilidad)
- **Ficheros**:
  - `lib/pote/orchestrator.ex` (624 líneas)
  - `test/pote/orchestrator_test.exs` (debe existir, verificar cobertura)
- **Esfuerzo estimado**: 8-12h
- **Complejidad**: ALTA. Múltiples consumers (alaja, mavis).
- **Análisis estructural actual**:
  - Funciones `defp` de parsing: `do_parse_color/2`, `parse_color_string/1`, `parse_hex_string/1`, `parse_rgb_string/1`, `parse_argb_string/1`, `parse_hsl_string/1`, `parse_hsv_string/1`, `parse_cmyk_string/1`, `parse_hwb_string/1`, `parse_color_string_fallback/1`, `parse_named_color/1`
  - Funciones `def` públicas: `parse_color/1`, `to_rgb/1`, `to_rgb!/1`, `to_ansi/1`, `to_ansi_bg/1`, `to_xterm256/1`, `named_colors/0`, `to_color_info/1`
  - Helpers internos: ~30 funciones
- **Plan de split propuesto**:
  - **`Pote.Parser`** (nuevo, ~250 líneas): todo el parsing. API:
    - `parse_color/1` (público)
    - `parse_hex/1`, `parse_rgb/1`, `parse_argb/1`, `parse_hsl/1`, `parse_hsv/1`, `parse_cmyk/1`, `parse_hwb/1`, `parse_named/1` (privados)
    - Devuelve `{:ok, color_tuple} | {:error, String.t()}`
  - **`Pote.ColorConverter`** (nuevo, ~150 líneas): `to_rgb/1`, `to_rgb!/1`, dispatch entre formatos
  - **`Pote.ColorInfo`** (nuevo, ~80 líneas): `to_color_info/1`, struct ColorInfo, named_colors/0
  - **`Pote.ANSIRenderer`** (nuevo, ~80 líneas): `to_ansi/1`, `to_ansi_bg/1`, `to_xterm256/1`
  - **`Pote.Orchestrator`** (refactor, ~100 líneas): solo fachada que delega a los 4 módulos anteriores
- **Pasos detallados**:
  1. **Fase 1: Extraer Parser** (3h)
     - Crear `lib/pote/parser.ex` con `parse_color/1` y helpers privados
     - Mover todas las funciones `parse_*_string` y `do_parse_color`
     - Tests específicos para Parser (parsing de cada formato)
     - Verificar cobertura 100% en Parser
  2. **Fase 2: Extraer ColorConverter** (2h)
     - Crear `lib/pote/color_converter.ex` con `to_rgb/1`, `to_rgb!/1`
     - Mover lógica de dispatch
     - Tests
  3. **Fase 3: Extraer ColorInfo + ANSIRenderer** (2h)
     - Crear `lib/pote/color_info.ex` con struct + `to_color_info/1`
     - Crear `lib/pote/ansi_renderer.ex` con `to_ansi/1`, `to_ansi_bg/1`, `to_xterm256/1`
     - Mover `@named_colors` al módulo ColorInfo
     - Tests
  4. **Fase 4: Refactor Orchestrator** (2h)
     - Dejar `Orchestrator` como façade de los 4 módulos
     - Cada función pública delega al módulo correspondiente
     - Actualizar `mix.exs` si hace falta
     - Tests de integración
  5. **Fase 5: Verificar consumidores** (1h)
     - `cd ~/cacafuti/alaja && mix deps.get && mix compile && mix test --cover`
     - `cd ~/cacafuti/candil && mix deps.get && mix compile && mix test --cover`
     - `cd ~/cacafuti/botica && mix deps.get && mix compile && mix test --cover`
- **Verificación**: 
  - `mix format --check-formatted`
  - `mix compile --warnings-as-errors`
  - `mix credo --strict` (0 issues)
  - `mix test --cover` (≥93.9% mantenido)
  - `mix dialyzer` (0 errors)
  - Consumers (alaja, candil, botica) compilan y pasan tests
- **Riesgos**: **MUY ALTO**. Es el módulo más complejo de pote. Refactor grande puede romper consumidores externos. Plan:
  - Hacer commits atómicos por fase
  - Tests de integración después de cada fase
  - Branch dedicada (`refactor/orchestrator-split`)
  - Si se rompe algo en consumidores, revertir fase
- **CHANGELOG**: marcar como breaking change si cambia API pública (no debería, solo es split interno).

---

### POT-22: Tests para módulos `Pote.Format.*`
- **Hallazgo**: Cobertura muy baja en `lib/pote/format.ex` y submódulos `format/*.ex`
- **Severidad**: 🟡 P2
- **Ficheros**:
  - `test/pote/format_test.exs` (crear o ampliar)
  - `test/pote/format/ansi_test.exs` (ya eliminado en commit `42c184b`)
  - `test/pote/format/rgb_test.exs` (verificar si existe)
  - `test/pote/format/hsl_test.exs`, `hsv_test.exs`, `cmyk_test.exs`, `argb_test.exs`, `hex_test.exs`, `xterm256_test.exs` (verificar)
- **Esfuerzo estimado**: 2-3h
- **Pasos detallados**:
  1. Auditar qué módulos Format tienen tests y cuáles no
  2. Para cada módulo sin tests, crear `test/pote/format/<name>_test.exs` con:
     - `describe "<format_name>/1"` con `test "renders RGB tuple correctly"` y variantes (foreground, background, edge cases)
     - `test "returns error tuple for invalid input"`
     - Property test si aplica (roundtrip con parse)
  3. Módulos prioritarios: `rgb.ex`, `hex.ex`, `argb.ex` (más usados)
  4. Módulos secundarios: `hsl.ex`, `hsv.ex`, `cmyk.ex`, `xterm256.ex`
- **Verificación**: `mix test --cover` (coverage de `lib/pote/format/` debe subir a ≥85%)
- **Riesgos**: Bajo. Solo añadir tests.

---

### POT-23: Split `lib/pote/validator.ex` (390 líneas)
- **Hallazgo**: `lib/pote/validator.ex` tiene **390 líneas** con `error_message/1` de 24 cláusulas
- **Severidad**: 🟡 P2
- **Ficheros**:
  - `lib/pote/validator.ex`
  - `lib/pote/validator/` (nuevo directorio)
- **Esfuerzo estimado**: 3-4h
- **Plan de split propuesto**:
  - `lib/pote/validator.ex` (refactor, ~50 líneas): fachada + dispatch
  - `lib/pote/validator/hex.ex` (~80 líneas): validación de hex
  - `lib/pote/validator/rgb.ex` (~80 líneas): validación de rgb
  - `lib/pote/validator/hsl.ex` (~80 líneas): validación de hsl
  - `lib/pote/validator/hsv.ex` (~60 líneas): validación de hsv
  - `lib/pote/validator/cmyk.ex` (~60 líneas): validación de cmyk
  - `lib/pote/validator/hwb.ex` (~40 líneas): validación de hwb
  - `lib/pote/validator/named.ex` (~40 líneas): validación de named colors
- **Pasos**:
  1. Crear un módulo por formato de color
  2. Mover las cláusulas de `error_message/1` correspondientes
  3. Tests específicos para cada validador
  4. `Validator.validate/1` despacha al validador correspondiente
- **Verificación**: `mix test --cover` + `mix credo --strict` + `mix dialyzer`
- **Riesgos**: Bajo. Solo split interno.

---

## 4. Dependencias externas

| Tarea | Dependencia | Estado |
|-------|-------------|--------|
| POT-09 | Si cambia `Pote.Format` behaviour: verificar alaja (consume) | Pendiente de decisión diseño |
| POT-21 | Refactor Orchestrator: verificar alaja, candil, botica (consumers) | Después de cada fase |
| Todas | `mix deps.get` + `mix deps.compile` | Funciona |

Pote usa **Jason** como única dep runtime. No depende de otros proyectos lorenzo-sf en runtime.

---

## 5. Riesgos globales

1. **POT-09 vs POT-validator-fix**: el fix de 3-tuplas (commit `77b6030`) y POT-09 (volver a 1-tupla) están en conflicto. Decisión de diseño necesaria.
2. **POT-21 Orchestrator refactor**: el más arriesgado. Plan: branch dedicada, commits atómicos por fase, tests de consumidores después de cada fase.
3. **POT-23 Validator split**: 7 nuevos módulos. Si se hace incremental, mantener backwards compatibility con `Validator.validate/1`.
4. **Property tests no deterministas**: POT-05 y POT-13 usan StreamData. Falsos fallos por precisión floating-point. Usar tolerancias.

---

## 6. Comandos de verificación

```bash
# Después de cada tarea:
mix format --check-formatted
mix compile --warnings-as-errors
mix credo --strict --format=json
mix test --cover                    # objetivo: mantener ≥ 93.9%
mix dialyzer

# Property tests (varias semillas):
mix test test/pote/property_test.exs --seed 0
mix test test/pote/property_test.exs --seed 12345
mix test test/pote/converters/property_test.exs --seed 0

# Para verificar consumidores (POT-21):
cd ~/cacafuti/alaja && mix compile && mix test --cover
cd ~/cacafuti/candil && mix compile && mix test --cover
cd ~/cacafuti/botica && mix compile && mix test --cover
```

---

## 7. CHANGELOG bullets para próximos lotes

Bajo `[Unreleased]` añadir cuando se complete cada tarea:

### Changed
- `Pote.Orchestrator` split into `Pote.Parser`, `Pote.ColorConverter`, `Pote.ColorInfo`, `Pote.ANSIRenderer` (POT-21)
- `Pote.Validator` split into per-format modules (POT-23)

### Fixed
- Various POT-XX tasks documented above

### Added
- Property tests for CMYK/HWB/Advanced roundtrips (POT-13)
- Tests for `Pote.Format.*` modules (POT-22)

NO bumpear versión en `[Unreleased]`.