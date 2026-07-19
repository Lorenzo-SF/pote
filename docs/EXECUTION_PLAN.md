# Pote v2.2.0 — Execution Plan

> Generado desde `AUDIT.md` (2026-07-19). Plan detallado para ejecución autónoma.

---

## 1. Resumen

| Severidad | Cantidad | Esfuerzo estimado |
|-----------|----------|-------------------|
| 🔴 P0 | 0 | — |
| 🟠 P1 | 7 | ~5h |
| 🟡 P2 | 12 | ~7h 15min |
| 🟢 P3 | 4 | ~45min |
| **Total** | **23** | **~13h** |

**Nota**: Pote no tiene hallazgos P0. La base de código está en excelente estado (93.2% cobertura, 0 credo violations).

---

## 2. Orden de ejecución recomendado

```
FASE 2 (P1):   POT-01 → POT-02 → POT-03 → POT-04 → POT-05 ──→ POT-06
                                                              ↓
FASE 3 (P2):   POT-07  POT-08  POT-09  POT-10  POT-11  POT-12  POT-13*  POT-14  POT-15  POT-16  POT-17
                                                                  ↓
FASE 4 (P3):   POT-18 → POT-19 → POT-20
```

\* POT-13 extiende POT-05 (property tests). Hacer POT-05 primero, luego ampliar en POT-13.

Orden interno recomendado sin dependencias (Fase 2): POT-07 → POT-08 → POT-09 → POT-10 → POT-11 → POT-12 → POT-13 → POT-14 → POT-15 → POT-16 → POT-17.
Orden interno recomendado (Fase 3): cualquiera, son independientes.

---

## 3. Fases

### Fase 1: Críticos (P0)

No hay hallazgos P0. Pasar a Fase 2.

---

### Fase 2: Alta prioridad (P1)

---

### POT-01: Eliminar dead `catch` clause en `resolve_default_color/1`
- **Hallazgo**: P1-01 — Dead `catch` in `resolve_default_color/1`
- **Severidad**: 🟠 P1
- **Ficheros**: `lib/pote.ex`
- **Esfuerzo**: 5 min
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Localizar el bloque `rescue`/`catch` en `resolve_default_color/1` (líneas 185-188)
  2. Eliminar la cláusula `catch :error, _ -> nil`
  3. Mantener el `rescue ArgumentError -> nil`
  4. Ejecutar tests
- **Verificación**: `mix test --cover` + `mix credo --all`
- **Riesgos**: Ninguno. Código muerto.

---

### POT-02: Eliminar dead `catch` clause en `safe_decode/1`
- **Hallazgo**: P1-02 — Dead `catch` in `safe_decode/1`
- **Severidad**: 🟠 P1
- **Ficheros**: `lib/pote/theme.ex`
- **Esfuerzo**: 5 min
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Localizar el bloque `rescue`/`catch` en `safe_decode/1` (líneas 183-189)
  2. Eliminar la cláusula `catch _, _ -> :not_found`
  3. Mantener `rescue _ -> :not_found`
  4. Ejecutar tests
- **Verificación**: `mix test --cover` + `mix credo --all`
- **Riesgos**: Ninguno. Código muerto.

---

### POT-03: Arreglar `ensure_registered/0` para no re-registrar siempre
- **Hallazgo**: P1-03 — `ensure_registered/0` case always matches `_`
- **Severidad**: 🟠 P1
- **Ficheros**: `lib/pote/theme.ex`
- **Esfuerzo**: 30 min
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Analizar `ensure_registered/0` (generado por `__using__/1`, líneas 369-376)
  2. Reemplazar el `case Pote.theme_resolver() do _ -> ... end` con una guarda real:
     - Si `Pote.theme_resolver()` ya es nuestro módulo, no hacer nada
     - Si no, registrar
  3. Alternativa: simplificar a llamada directa `Pote.put_theme_resolver(...)` sin `case`
  4. Añadir test que llame `ensure_registered/0` dos veces y verifique que el resolver solo se registra una vez (mockear `put_theme_resolver` con contador)
- **Verificación**: `mix test --cover` + `mix credo --all`
- **Riesgos**: Si se elimina el case completamente, se pierde la intención original de no apilar resolvers. Asegurar que `put_theme_resolver` no se llama múltiples veces innecesariamente.

---

### POT-04: Unificar política de rounding en conversiones de color
- **Hallazgo**: P1-04 — `Float.round(1)` on hue loses precision; P1-05 — No consistent rounding policy
- **Severidad**: 🟠 P1
- **Ficheros**: `lib/pote/converters/rgb.ex`, `lib/pote/converters/hsl.ex`, `lib/pote/converters/hsv.ex`, `lib/pote/converters/advanced.ex`
- **Esfuerzo**: 1h 30min
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Decidir política: **Opción A** (recomendada) — solo redondear en fronteras de API pública, mantener full float en internas
  2. En `RGB.to_hsl/1` (`rgb.ex:109`): eliminar `Float.round(1)` en hue, mantener precisión completa. El hue redondeado solo debe ocurrir en la salida final (e.g., formato HSL string)
  3. En `Advanced`: eliminar `Float.round` intermedios, conservar solo `Float.round` en funciones de salida final (`delta_e`, `contrast_ratio`, `relative_luminance`)
  4. Actualizar propiedades de roundtrip: `rgb → hsl → rgb` puede necesitar tolerancia ±1 si se redondea a la salida
  5. Actualizar tests que dependan de valores redondeados específicos
  6. Documentar política en `@moduledoc` de `Pote.Converters`
- **Verificación**: `mix test --cover` (especialmente property tests) + `mix credo --all`
- **Riesgos**: Eliminar rounding puede exponer pequeños errores floating-point (e.g., `0.30000000000000004`). Asegurar que los formatos de salida (string) redondean adecuadamente.

---

### POT-05: Añadir property tests básicos para roundtrips de color
- **Hallazgo**: P1-06 — Property tests are minimal
- **Severidad**: 🟠 P1
- **Ficheros**: `test/pote/property_test.exs` (ampliar)
- **Esfuerzo**: 1h
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Añadir propiedad `rgb → cmyk → rgb` con StreamData (generar RGB aleatorios, convertir a CMYK, volver a RGB, verificar ±1 por canal)
  2. Añadir propiedad `rgb → hsl → rgb` (ya existe, verificar tolerancia)
  3. Añadir propiedad `rgb → hsv → rgb` (ya existe, verificar tolerancia)
  4. Añadir propiedad `hwb → rgb → hwb` roundtrip
  5. Añadir propiedad `rgb → hex → rgb` (ya existe)
  6. Añadir propiedad `contrast_ratio(a, b) == contrast_ratio(b, a)` (conmutatividad)
  7. Ejecutar `mix test --cover` y verificar cobertura en módulos de conversión
- **Verificación**: `mix test --cover` + `mix credo --all` + `mix test test/pote/property_test.exs` (ejecutar varias veces por StreamData)
- **Riesgos**: Propiedades con floats pueden tener falsos fallos por precisión. Usar tolerancia ±1 o `==≈` con epsilon.

---

### POT-06: Arreglar segment count en `Gradients.multicolor/2`
- **Hallazgo**: P1-07 — `div(steps-1, segment_count)` truncation can under-count gradient stops
- **Severidad**: 🟠 P1
- **Ficheros**: `lib/pote/gradients.ex`
- **Esfuerzo**: 30 min
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Reemplazar `steps_per_segment = max(1, div(steps - 1, segment_count))` con distribución float que garantice exactamente `steps` stops totales
  2. Algoritmo sugerido: distribuir `steps` entre segmentos proporcionalmente, redondear acumulativamente (Bresenham-style) para que la suma sea exacta
  3. Añadir property test: `multicolor(N colores, S steps)` produce exactamente S stops
  4. Casos borde: `steps = 2`, `steps = 3`, `steps = segment_count`
- **Verificación**: `mix test --cover` + `mix credo --all` (ver especialmente `test/pote/gradients_test.exs`)
- **Riesgos**: Cambio en la distribución de stops puede alterar ligeramente el espaciado visual de gradientes existentes.

---

### Fase 3: Media (P2)

---

### POT-07: Añadir `@spec` y `@doc` a `Pote.Converters` facade
- **Hallazgo**: P2-01 — 12 functions without `@spec` annotations; P2-09 — Zero per-function `@doc` on facade delegation
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/converters.ex`
- **Esfuerzo**: 1h
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Para cada una de las 12 funciones delegadas (`hsl_to_rgb/1`, `rgb_to_hsl/1`, `hsv_to_rgb/1`, `rgb_to_hsv/1`, `cmyk_to_rgb/1`, `rgb_to_cmyk/1`, `xterm256_to_rgb/1`, `rgb_to_xterm256/1`, `hwb_to_rgb/1`, `rgb_to_hwb/1`, `rgb_to_hex/1`, `hex_to_rgb/1`):
     - Añadir `@spec` con tipos de color (e.g., `@spec hsl_to_rgb(Pote.hsl()) :: Pote.rgb()`)
     - Añadir `@doc` con descripción breve y ejemplos
  2. Usar tipos definidos en `Pote` module: `Pote.hsl()`, `Pote.rgb()`, etc.
  3. Verificar con `mix dialyzer` que no hay warnings
- **Verificación**: `mix dialyzer` + `mix test --cover` + `mix credo --all`
- **Riesgos**: Ninguno. Solo anotaciones y documentación.

---

### POT-08: Eliminar `@spec` de funciones privadas
- **Hallazgo**: P2-02 — Private functions with `@spec` annotations
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/converters/rgb.ex`, `lib/pote/converters/hsl.ex`, `lib/pote/converters/advanced.ex`
- **Esfuerzo**: 15 min
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Buscar funciones privadas con `@spec`: `RGB.hex_component/1`, `HSL.hue_to_rgb/3`, `Advanced.clamp/1`, etc.
  2. Eliminar `@spec` de funciones `defp`
  3. Mantener `@spec` solo en funciones públicas (`def`)
- **Verificación**: `mix test --cover` + `mix credo --all`
- **Riesgos**: Ninguno. Solo limpieza de código.

---

### POT-09: Estandarizar formas de error
- **Hallazgo**: P2-03 — Three different error return shapes
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/format.ex`, `lib/pote/format/*.ex` (9 módulos), `lib/pote/orchestrator.ex`, `lib/pote/validator.ex`, `lib/pote/converters/rgb.ex`
- **Esfuerzo**: 1h
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Decidir formato estándar: `{:error, String.t()}` con mensaje descriptivo
  2. Cambiar `Pote.Format` behaviour callback spec de `{:ok, t()} | :error` a `{:ok, t()} | {:error, String.t()}`
  3. Actualizar los 9 módulos `Pote.Format.*` para devolver `{:error, "reason"}` en lugar de `:error`
  4. Cambiar `Validator.check_bracket_style/2` de `{:error, atom(), String.t()}` a `{:error, String.t()}`
  5. Actualizar `Pote.Orchestrator` que wrappea errors
  6. Actualizar tests que matcheen `:error` o `{:error, atom}`
- **Verificación**: `mix test --cover` + `mix credo --all`
- **Riesgos**: Breaking change para consumidores que matcheen `:error` directamente. Afecta a la behaviour `Pote.Format`. Requiere actualizar alaja si lo consume.

---

### POT-10: Reducir `rescue _ -> :error` en `sanitize_list/2`
- **Hallazgo**: P2-04 — Overly broad `rescue _ -> :error`
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/sanitizer.ex`
- **Esfuerzo**: 15 min
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Evaluar si el `rescue` es necesario: `String.split/2` y `Enum.map/1` no levantan en condiciones normales
  2. Si se decide mantener: cambiar `rescue _ -> :error` por `rescue e -> {:error, Exception.message(e)}`
  3. Si se decide eliminar: quitar todo el bloque `rescue`
  4. Opcional: cambiar return de `:error` a `{:error, reason}` (consistente con POT-09)
- **Verificación**: `mix test --cover` + `mix credo --all`
- **Riesgos**: Bajo. `String.split/2` solo falla con argumentos inválidos (non-binary separator).

---

### POT-11: Corregir valores negativos en CMYK
- **Hallazgo**: P2-05 — CMYK can produce tiny negative values from float division
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/converters/rgb.ex`
- **Esfuerzo**: 30 min
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. En `to_cmyk/1` (`rgb.ex:139-155`), después del cálculo, aplicar `max(0.0, value)` a cada componente
  2. Añadir clamping: `c = max(0.0, (1.0 - r - k) / (1.0 - k))`
  3. Añadir property test: para cualquier RGB válido, CMYK resultante tiene todos los componentes en [0, 1]
  4. Verificar que el test `assert result == rgb` sigue pasando
- **Verificación**: `mix test --cover` + `mix credo --all`
- **Riesgos**: Muy bajo. Solo clamp a valores negativos que son artifact de precisión.

---

### POT-12: Guard contra división por near-zero en HWB
- **Hallazgo**: P2-06 — Division by near-zero when `w+b` is extremely small
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/converters/hwb.ex`
- **Esfuerzo**: 15 min
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. En `hwb.ex:19`, después de `if w + b >= 1.0`, la rama `else` calcula `gray = round(w / (w + b) * 255)`
  2. Añadir guard para `w + b == 0.0`: en ese caso, el gris es 0 (o el valor que corresponda)
  3. Escribir test con `w=0.0, b=0.0` que no sature
- **Verificación**: `mix test --cover` + `mix credo --all`
- **Riesgos**: Muy bajo. Caso borde extremo.

---

### POT-13: Añadir property tests para CMYK/HWB/Advanced
- **Hallazgo**: P2-07 — No dedicated property tests for CMYK/HWB/Advanced
- **Severidad**: 🟡 P2
- **Ficheros**: `test/pote/converters/` (nuevo fichero o ampliar existente)
- **Esfuerzo**: 1h
- **Dependencias**: POT-05 (extiende la base de property tests)
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Añadir `test/pote/converters/property_test.exs` con StreamData
  2. Propiedades a cubrir:
     - `rgb → hwb → rgb` roundtrip
     - `hsl → rgb → hsl` roundtrip
     - `hsv → rgb → hsv` roundtrip
     - `rgb → xyz → rgb` roundtrip (Advanced)
     - `rgb → lab → rgb` roundtrip (Advanced)
     - `yuv → rgb → yuv` roundtrip
     - `ycbcr → rgb → ycbcr` roundtrip
     - `kelvin_to_rgb` monotonicidad: K1 < K2 → temp1 > temp2 (inverso)
  3. Ejecutar varias veces: `mix test test/pote/converters/property_test.exs --seed 0`
- **Verificación**: `mix test --cover` + `mix credo --all` + ejecución repetida de property tests
- **Riesgos**: Floats pueden requerir tolerancias. Usar `≈` con epsilon 1.0e-6 para no-floating channels, ±1 para 0-255 channels.

---

### POT-14: Refactorizar `Pote.Theme.__using__/1` macro
- **Hallazgo**: P2-08 — Very large `__using__/1` macro (160 lines, 15+ generated functions)
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/theme.ex`
- **Esfuerzo**: 2h
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Analizar `__using__/1` macro (líneas 262-420) y listar funciones generadas: `colors/0`, `active/0`, `color/1`, `list/0`, `ensure_registered/0`, etc.
  2. Extraer la lógica de cada función a un módulo de runtime (e.g., `Pote.Theme.Runtime`) que recibe el módulo host como argumento
  3. Dejar en `__using__/1` solo las delegaciones a `Pote.Theme.Runtime`
  4. Mover las funciones individuales a `Pote.Theme.Runtime` como módulo separado
  5. Escribir tests para `Pote.Theme.Runtime` directamente (sin macro)
  6. Verificar que todos los tests de Theme existentes siguen pasando
- **Verificación**: `mix test --cover` + `mix credo --all` + `mix test test/pote/theme_test.exs`
- **Riesgos**: Refactor grande. El macro genera código que se inyecta en el módulo del usuario — la extracción a runtime cambia el scope (las funciones ya no tienen acceso directo al `__MODULE__` del host). Pasar `host_module` como argumento. Asegurar backward compatibility.

---

### POT-15: Hacer `@named_colors` configurable en runtime
- **Hallazgo**: P2-10 — `@named_colors` fixed at compile time
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/orchestrator.ex`
- **Esfuerzo**: 30 min
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Convertir `@named_colors` de module attribute a función: `defp named_colors()`
  2. Permitir configuración via Application env o argumento de módulo
  3. Mantener el Map actual como default
  4. Escribir test con `named_colors` customizado
- **Verificación**: `mix test --cover` + `mix credo --all`
- **Riesgos**: Cambiar de `@named_colors` a función puede tener impacto mínimo en performance (se computa cada vez vs una vez). Para 30 entradas es irrelevante.

---

### POT-16: Verificar fórmula gray de XTerm256
- **Hallazgo**: P2-11 — XTerm256 gray formula — verify against spec
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/converters/xterm256.ex`
- **Esfuerzo**: 15 min
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Revisar fórmula `gray = (index - 232) * 10 + 8` contra especificación XTerm256: produce 8, 18, 28, ..., 238 (24 niveles). Correcto.
  2. Revisar fórmula del cubo: `r = div(index, 36) * 51` produce {0, 51, 102, 153, 204, 255}. Correcto.
  3. Añadir test que verifique valores conocidos: index 16 = RGB(0,0,0), index 231 = RGB(255,255,255), index 232 = gray(8), index 255 = gray(238)
  4. Si todo es correcto, cerrar como "verificado sin cambios"
- **Verificación**: `mix test --cover` + `mix credo --all`
- **Riesgos**: Ninguno.

---

### POT-17: Validar `storage_dir` nil en `save_theme`
- **Hallazgo**: P2-12 — `storage_dir = nil` silently writes to CWD
- **Severidad**: 🟡 P2
- **Ficheros**: `lib/pote/theme.ex`
- **Esfuerzo**: 15 min
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. En `save_theme/2`, después de `expand_path(storage_dir)`, validar que `dir` no sea nil ni vacío
  2. Si `dir` es nil o `""`, retornar `{:error, "storage_dir must be a valid directory path"}`
  3. En `expand_path/1`, manejar nil devolviendo nil en lugar de `""`
  4. Escribir test con `storage_dir: nil` que verifique `{:error, _}`
- **Verificación**: `mix test --cover` + `mix credo --all` (especialmente `test/pote/theme_test.exs`)
- **Riesgos**: Consumidores que confíen en el comportamiento actual (guardar en CWD) se romperán. Es el cambio correcto — era un bug.

---

### Fase 4: Baja (P3)

---

### POT-18: Traducir documentación y comentarios en español a inglés
- **Hallazgo**: P3-01 — Spanish text in English docs; P3-02 — Spanish comments
- **Severidad**: 🟢 P3
- **Ficheros**: `lib/pote/converters/rgb.ex`, `lib/pote/converters/advanced.ex`
- **Esfuerzo**: 15 min
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. En `rgb.ex:183`: cambiar `"Blends dos colores RGB con un factor dado."` a `"Blends two RGB colors with a given factor."`
  2. En `advanced.ex:146`: cambiar `"# Delta E (distancia de color)"` a `"# Delta E (color distance)"`
  3. En `advanced.ex:190-191`: cambiar `"# WCAG AA requiere 4.5:1 para texto normal, 7:1 para AAA."` a `"# WCAG AA requires 4.5:1 for normal text, 7:1 for AAA."`
- **Verificación**: `mix test` (doctests) + `mix credo --all`
- **Riesgos**: Ninguno.

---

### POT-19: Añadir `@deprecated` a `Pote.Format.ANSI`
- **Hallazgo**: P3-03 — Deprecated module still live without `@deprecated` annotation
- **Severidad**: 🟢 P3
- **Ficheros**: `lib/pote/format/ansi.ex`
- **Esfuerzo**: 15 min
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Añadir `@deprecated "Use Pote.Format.RGB or another format module instead"` al módulo
  2. Añadir `@doc deprecated: "Use Pote.Format.RGB or another format module instead"` para mantener documentación
  3. Verificar que `mix compile` muestra warnings de deprecación
- **Verificación**: `mix compile --warnings-as-errors` (debe fallar si hay consumidores internos) + `mix test`
- **Riesgos**: Si hay consumidores internos de `Pote.Format.ANSI`, el compilador emitirá warnings de deprecación. Evaluar si es necesario mantener compatibilidad.

---

### POT-20: Eliminar branches muertos en `Gradients.linear/3`
- **Hallazgo**: P3-04 — Dead branches for `steps=0` and `steps=1`
- **Severidad**: 🟢 P3
- **Ficheros**: `lib/pote/gradients.ex`
- **Esfuerzo**: 15 min
- **Dependencias**: Ninguna
- **Dependencias externas**: Ninguna
- **Pasos**:
  1. Eliminar las cláusulas `def linear(_from, _to, 0), do: []` y `def linear(from, _to, 1), do: [from]` (líneas 50-51)
  2. Verificar que la cláusula principal con guard `when steps >= 2` cubre todos los casos de uso reales
  3. Ejecutar tests de gradientes
- **Verificación**: `mix test --cover` + `mix credo --all`
- **Riesgos**: Si algún caller llama `linear/3` con `steps=0` o `steps=1`, obtendrá `FunctionClauseError`. Verificar que ningún caller lo hace.

---

## 4. Dependencias externas

| Tarea | Dependencia externa | Proyecto |
|-------|---------------------|----------|
| POT-09 | Si se cambia `Pote.Format` behaviour, verificar alaja (consume format) | Alaja |
| POT-14 | Refactor grande de `Theme.__using__/1` — verificar alaja que usa el macro | Alaja |
| Todas | `mix deps.get` y `mix deps.compile` exitosos | — |

Pote usa **Jason** como única dependencia runtime. No depende de apero ni de ningún otro proyecto Lorenzo-SF en runtime (la dependencia con apero es solo para persistencia JSON de temas, y usa Jason directamente).

Si se modifica una interfaz pública de Pote (tipos, `Pote.Format` behaviour, `Pote.Theme` macro), verificar que alaja sigue compilando:

```bash
cd ~/cacafuti/alaja
mix deps.get
mix compile
mix test --cover
```

---

## 5. Riesgos globales

1. **Sin tests para comportamiento existente en algunos módulos**: Aunque la cobertura global es 93.2%, algunos módulos tienen 0% (format.ex). Las tareas POT-09 (error shapes) tocan format.ex sin tests que verifiquen regresión.
2. **Property tests no deterministas**: POT-05 y POT-13 usan StreamData. Ejecutar con `--seed 0` y varias iteraciones. Falsos fallos por tolerancia floating-point.
3. **Breaking changes en behaviour `Pote.Format`**: POT-09 cambia el callback de `{:ok, t()} | :error` a `{:ok, t()} | {:error, String.t()}`. Afecta a cualquier módulo que implemente el behaviour (9 módulos Format + consumidores externos).
4. **Refactor grande del macro Theme**: POT-14 es el cambio más arriesgado (2h estimadas). Hacerlo al final si el tiempo lo permite. Asegurar 100% cobertura de tests de Theme antes y después.
5. **Sin P0**: Esto significa que se puede priorizar calidad sobre parches urgentes. Aprovechar para hacer las cosas bien.

---

## 6. Comandos de verificación

```bash
# Después de cada tarea:
mix test --cover                              # Tests + cobertura (objetivo: mantener ≥ 93.2%)
mix credo --all                               # Estilo (0 violaciones)
mix format --check-formatted                  # Formato
mix compile --warnings-as-errors              # Compilación limpia
mix dialyzer                                  # Tipos (opcional por lentitud)

# Property tests (varias semillas):
mix test test/pote/property_test.exs --seed 0
mix test test/pote/property_test.exs --seed 12345

# Full QA (alias del proyecto):
mix qa                                        # format + compile + dialyzer + test --cover

# Para verificar consumidores:
cd ~/cacafuti/alaja && mix compile && mix test --cover
```
