# Pote v2.2.0 — Code Quality Audit

> Date: 2026-07-19
> Scope: Full source tree (`lib/`), test tree (`test/`), `mix.exs`
> Methods: Static analysis, `mix test --cover`, `mix credo --all`, manual review

---

## Summary

| Metric | Value |
|--------|-------|
| Modules | 30 source modules, 25 test files |
| Tests | 402 (including 6 properties) |
| Coverage | **93.2%** total |
| Credo | **0 issues** (57 checks, 51 files, 436 mods/funs) |
| Dependencies | 1 runtime (Jason ~> 1.4), 4 dev/test |

The codebase is in excellent health. Credo reports zero violations, coverage is
high, and the architecture is cleanly layered. Findings are mostly about
precision, dead code, and test gaps rather than correctness.

---

## 1. Typespec Completeness

| Module | Status | Details |
|--------|--------|---------|
| `Pote` | ✅ Complete | All public functions `@spec`'d |
| `Pote.Converters` | 🔶 **12 missing** | `hsl_to_rgb/1`, `rgb_to_hsl/1`, `hsv_to_rgb/1`, `rgb_to_hsv/1`, `cmyk_to_rgb/1`, `rgb_to_cmyk/1`, `xterm256_to_rgb/1`, `rgb_to_xterm256/1`, `hwb_to_rgb/1`, `rgb_to_hwb/1`, `rgb_to_hex/1`, `hex_to_rgb/1` — none have `@spec` |
| `Pote.Converters.RGB` | ✅ Complete | All public functions |
| `Pote.Converters.HSL` | ✅ Complete | |
| `Pote.Converters.HSV` | ✅ Complete | |
| `Pote.Converters.CMYK` | ✅ Complete | |
| `Pote.Converters.HWB` | ✅ Complete | |
| `Pote.Converters.XTerm256` | ✅ Complete | |
| `Pote.Converters.Advanced` | ✅ Complete | All 15+ public functions |
| `Pote.Format` | ✅ Complete | Callbacks have specs, `valid_via_parse/2` missing |
| `Pote.Format.*` (9 modules) | ✅ Complete | All `@impl` + `@spec` |
| `Pote.Orchestrator` | ✅ Complete | |
| `Pote.Harmonies` | ✅ Complete | Privates `rotate_hue/2`, `mix/3` lack specs (acceptable) |
| `Pote.Gradients` | ✅ Complete | Privates `interpolate/3` lacks spec |
| `Pote.ColorInfo` | ✅ Complete | |
| `Pote.Theme` | ✅ Complete | Generated functions via `__using__` have specs |
| `Pote.Theme.Theme` | ✅ Complete | |
| `Pote.Theme.Templates` | ✅ Complete | |
| `Pote.Validator` | ✅ Complete | |
| `Pote.Sanitizer` | ✅ Complete | |
| `Pote.Colors.Basic` | ✅ Complete | |

**Finding P2-01**: `Pote.Converters` facade (12 functions) lacks `@spec` annotations.
These are the most commonly used conversion entry points — missing specs means
Dialyzer cannot validate callers. Each should have:
```elixir
@spec hsl_to_rgb(Pote.hsl()) :: Pote.rgb()
```

**Finding P2-02**: Several private functions use `@spec` — harmless but
unconventional and may confuse tooling that expects specs only on public API.
Affects: `RGB.hex_component/1`, `HSL.hue_to_rgb/3`, `Advanced.clamp/1`, etc.

---

## 2. Error Handling

### 2.1 Dead catch clauses

**Finding P1-01 — Dead `catch` in `resolve_default_color/1`**
`lib/pote.ex:185-188`:
```elixir
rescue
  ArgumentError -> nil
catch
  :error, _ -> nil    # ← NEVER triggers: String.to_existing_atom/1 never throws
end
```
`String.to_existing_atom/1` either returns an atom or raises `ArgumentError`.
The `catch` clause is dead code. Remove it.

**Finding P1-02 — Dead `catch` in `safe_decode/1`**
`lib/pote/theme.ex:183-189`:
```elixir
rescue
  _ -> :not_found
catch
  _, _ -> :not_found   # ← Likely dead: Jason.decode/1 raises or returns {:ok,_}|{:error,_}
end
```
`Jason.decode/1` returns `{:ok, map}` | `{:error, reason}` or raises on invalid
UTF-8/binary. It never throws. Same pattern exported to `apero` as canonical
JSON wrapper. Dead catch; remove.

### 2.2 Useless case expression

**Finding P1-03 — `ensure_registered/0` case always matches `_`**
`lib/pote/theme.ex:369-376` (generated code):
```elixir
def ensure_registered do
  case Pote.theme_resolver() do
    _ ->
      Pote.put_theme_resolver(...)   # Always executes
  end
  :ok
end
```
The `case` is a no-op — `_` matches everything unconditionally. This means
`ensure_registered/0` **always** re-registers the resolver, even when it is
already registered. This is wasteful (pushes onto the resolver stack on every
call to `list/0`, `active/0`, `colors/0`, `color/1`). The original intent was
to check whether the resolver is already ours; replace with a guard or remove
the `case`.

### 2.3 Inconsistent error shapes

**Finding P2-03 — Three different error return shapes**

| Shape | Used by |
|-------|---------|
| `{:error, atom}` | `Validator.validate/1`, `Pote.Orchestrator`, `Converters.RGB.from_hex/1` |
| `{:error, String.t()}` | `Pote.Orchestrator.parse_color/1`, `to_rgb/1` |
| `:error` | `Pote.Format.*.parse/1` (return bare `:error`, not `{:error, _}`) |
| `{:error, atom(), String.t()}` | `Validator.check_bracket_style/2` |

**Problem**: `Pote.Format` behaviour callback returns `{:ok, t()} | :error`,
but `Pote.Orchestrator` wraps errors as `{:error, String.t()}`. The Format
modules return bare `:error` which loses information. The behaviour should
either standardise on `{:error, String.t()}` or make the difference explicit.

### 2.4 Broad rescue in `sanitize_list/2`

**Finding P2-04** — `lib/pote/sanitizer.ex:29-35`:
```elixir
def sanitize_list(input, separator) when is_binary(input) do
  case String.split(input, separator) |> Enum.map(&sanitize/1) do
    parts -> {:ok, parts}
  end
rescue
  _ -> :error
end
```
`String.split/2` and `Enum.map/2` never raise under normal conditions. If they
did, swallowing the error with `_ -> :error` hides the root cause. Remove the
rescue or narrow it to specific exceptions.

---

## 3. Floating Point Precision Issues in Color Math

### 3.1 `RGB.to_hsl/1` rounds hue to 1 decimal

**Finding P1-04** — `lib/pote/converters/rgb.ex:109`:
```elixir
|> Float.round(1)
```
This rounds hue to one decimal place (e.g., `30.1`). Callers downstream
(HSL → RGB, hue rotation in Harmonies) then operate on this truncated value.
The loss compounds:
- `RGB.to_hsl → HSL.to_rgb` property test must allow **±1 per channel**
- `rgb → hsl → rgb` roundtrip is **not lossless** by design

**Impact**: Harmonies that rotate hue (`complementary`, `analogous`, `triad`)
accumulate error. A rotation of 180° may land at 179.9° due to truncation,
producing a slightly off complement.

**Recommended fix**: Either keep full float precision in the intermediate and
only round at the final output, or document that HSL roundtrip has ±1 tolerance.

### 3.2 Inconsistent rounding strategies

| Function | Rounding | Line |
|----------|----------|------|
| `RGB.to_hsl/1` | `Float.round(1)` on h | rgb.ex:109 |
| `RGB.calculate_h/4` | `round()` for integer result | rgb.ex:108-109 |
| `HSL.to_rgb/1` | `round(r * 255)` | hsl.ex:37 |
| `HSV.to_rgb/1` | `round(r * 255)` | hsv.ex:35 |
| `Advanced.to_xyz/1` | `Float.round(x, 3)` | advanced.ex:47 |
| `Advanced.to_lab/1` | `Float.round(l, 2)` | advanced.ex:97 |
| `Advanced.delta_e/2` | `Float.round(2)` | advanced.ex:161 |
| `Advanced.contrast_ratio/2` | `Float.round(2)` | advanced.ex:201 |
| `Advanced.relative_luminance/1` | `Float.round(4)` | advanced.ex:185 |

**Finding P1-05**: There is no single rounding policy. Some functions round
intermediates (losing precision that downstream calculations depend on),
others round only the final output. The `Advanced` converters round
intermediate values multiple times (xyz → lab → delta_e), compounding error.

**Recommendation**: Adopt one policy:
- **Option A**: Only round at public API boundaries. Internals keep full float.
- **Option B**: Use a precision wrapper (e.g., a `Float` extension) and apply
  consistently (round to 4 decimals everywhere).

### 3.3 CMYK roundtrip

`RGB.to_cmyk/1` (`rgb.ex:139-155`) converts via:
```elixir
k = 1.0 - Enum.max([r, g, b])
c = (1.0 - r - k) / (1.0 - k)
```
**Finding P2-05**: CMYK values can produce tiny negative values (e.g., `-0.0`)
or exceed 100 slightly due to floating point division. The test at line 106
`assert result == rgb` passes only because the test values are carefully
chosen. Property tests with `StreamData` would catch regressions.

### 3.4 HWB division by near-zero

**Finding P2-06** — `lib/pote/converters/hwb.ex:19`:
```elixir
if w + b >= 1.0 do
  gray = round(w / (w + b) * 255)
```
When `w + b == 0.0` (both zero), this path is never taken. When `w + b` is
extremely small (e.g., `1.0e-16`), the division produces a huge value followed
by `round/1`. Add a guard for `w + b == 0.0`.

---

## 4. Test Coverage (per-module)

### 4.1 Coverage by module

```
 91.4%  lib/pote.ex                         3 missed
 94.2%  lib/pote/color_info.ex               2 missed
100.0%  lib/pote/colors/basic.ex             0 missed
100.0%  lib/pote/converters.ex              0 missed
 86.5%  lib/pote/converters/advanced.ex     17 missed
100.0%  lib/pote/converters/cmyk.ex          0 missed
100.0%  lib/pote/converters/hsl.ex           0 missed
100.0%  lib/pote/converters/hsv.ex           0 missed
 85.7%  lib/pote/converters/hwb.ex           6 missed
 91.8%  lib/pote/converters/rgb.ex           6 missed
 90.9%  lib/pote/converters/xterm256.ex      1 missed
  0.0%  lib/pote/format.ex                   3 missed
100.0%  lib/pote/format/ansi.ex             0 missed
 94.1%  lib/pote/format/argb.ex              1 missed
100.0%  lib/pote/format/atom.ex              0 missed
100.0%  lib/pote/format/cmyk.ex              0 missed
 95.4%  lib/pote/format/hex.ex               1 missed
100.0%  lib/pote/format/hsl.ex               0 missed
100.0%  lib/pote/format/hsv.ex               0 missed
100.0%  lib/pote/format/rgb.ex               0 missed
 92.8%  lib/pote/format/xterm256.ex          1 missed
100.0%  lib/pote/gradients.ex               0 missed
100.0%  lib/pote/harmonies.ex               0 missed
 97.9%  lib/pote/orchestrator.ex             3 missed
100.0%  lib/pote/sanitizer.ex               0 missed
 85.7%  lib/pote/theme.ex                    9 missed
100.0%  lib/pote/theme/templates.ex          0 missed
 90.2%  lib/pote/validator.ex               11 missed
─────────────────────────────────────────────────────
 93.2%  TOTAL
```

### 4.2 Uncovered lines analysis

| Module | Missed | Likely cause |
|--------|--------|--------------|
| `advanced.ex` | 17 | YUV/YCbCr edge cases (`from_yuv`, `from_ycbcr`), Kelvin binary search branches, Pantone nil case |
| `hwb.ex` | 6 | `hwb_hue` clauses for `diff > 0.0` on green/blue max |
| `rgb.ex` | 6 | Edge cases in `to_xterm256` grayscale boundary, `calculate_h` non-max branches |
| `theme.ex` | 9 | Error paths: `expand_path(nil)`, `File.exists?` false, `save_theme` failure modes |
| `validator.ex` | 11 | `parse_hue`, `parse_normalized` edge cases, some `valid_decimals?` paths |
| `format.ex` | 3 | Behaviour module itself (expected — only callbacks) |

### 4.3 Property tests

**Finding P1-06 — Property tests are minimal**. Only 3 properties:

1. `rgb → hex → rgb` (identity)
2. `rgb → hsl → rgb` (±1 tolerance)
3. `rgb → hsv → rgb` (±1 tolerance)
4. Grayscale invariants

**Missing property tests**:
- ✗ `rgb → cmyk → rgb` roundtrip
- ✗ `hsl → rgb → hsl` roundtrip
- ✗ `hsv → rgb → hsv` roundtrip
- ✗ `hwb → rgb → hwb` roundtrip
- ✗ `xyz → rgb → xyz` roundtrip (Advanced)
- ✗ `lab → rgb → lab` roundtrip (Advanced)
- ✗ `yuv → rgb → yuv` roundtrip
- ✗ `ycbcr → rgb → ycbcr` roundtrip
- ✗ `kelvin_to_rgb` monotonicity (higher K → bluer)
- ✗ `contrast_ratio` commutativity
- ✗ `delta_e` triangle inequality
- ✗ Harmony functions: applying complementary twice returns original
- ✗ `linear` gradient with steps = 2 returns `[from, to]`
- ✗ `multicolor` segment count consistency

### 4.4 Test file gaps

**Finding P2-07**: No dedicated property test file for converters beyond RGB.
The `converters_test.exs` file has hand-picked example values but no
`StreamData`-driven roundtrip tests for CMYK, HWB, or Advanced converters.

---

## 5. Code Complexity

### 5.1 Complex functions

| Function | Lines | Complexity | Risk |
|----------|-------|------------|------|
| `Pote.Theme.__using__/1` | ~160 gen | Macro generates 15+ functions | Hard to test/maintain. Changes require recompilation of all host modules. |
| `Pote.Advanced.search_kelvin/4` | 16 | Binary search on HSL values | **Questionable correctness**: compares hue, then saturation, then lightness as a multi-dimensional sort. Two colors with same hue but different saturation are treated as "less than/greater than" which is meaningless for temperature search. |
| `Pote.Orchestrator.parse_color/1` + dispatch | ~40 | 15+ pattern match arms | Well-structured, but long. Each new format requires adding a dispatch arm. |
| `Pote.Gradients.multicolor/2` | 12 + helpers | Segment step distribution | The `process_segment/6` math is subtle. Rounding errors in `steps_per_segment` can produce one fewer or one more stop than requested. |
| `Pote.Validator.validate/1` | ~250 | 15+ private dispatch funcs | Well-structured. `check_bracket_style/2` duplicates similar messages across 5 formats. |

### 5.2 Graph complexity (risk indicators)

**Finding P2-08 — `Pote.Theme.__using__/1` macro is very large**.
The generated module exposes ~10 public functions, 3 of which (`active/0`,
`color/1`, `ensure_registered/0`) each contain complex logic. The macro mixes
code generation with runtime concerns (file I/O, application env). A
`__before_compile__` hook or a dedicated behaviour module would be cleaner.

---

## 6. Documentation Quality

### 6.1 What's good

- All 30 source modules have `@moduledoc`
- All public/spec'd functions have `@doc` (except `Converters` facade)
- `Pote.Format` behaviour provides default implementations + docs
- `Pote.Theme.__using__/1` docs include a **full Quick Start** code example
- `ARCHITECTURE.md` and `INDEX.md` are present and up to date
- Doctest examples in `Pote.Harmonies`, `Pote.Gradients`, `Pote.ColorInfo`

### 6.2 What needs improvement

**Finding P2-09 — `Pote.Converters` facade has no per-function docs**.
`lib/pote/converters.ex:13-24` has 12 delegated functions with zero `@doc`
annotations. Callers see no documentation for `hsl_to_rgb/1` etc. in their
editor. Add `@doc` delegations or use `defdelegate` with `doc: false`.

**Finding P3-01 — Languages mixed in documentation**.
`lib/pote/converters/rgb.ex:183`:
```
Blends dos colores RGB con un factor dado.
```
Spanish in an otherwise English codebase. `lib/pote/converters/advanced.ex:146`:
```
# Delta E (distancia de color)
```
and `lib/pote/converters/advanced.ex:190-191`:
```
# WCAG AA requiere 4.5:1 para texto normal, 7:1 para AAA.
```
These should be in English for consistency.

**Finding P3-02 — `Pote.Format.ANSI` is deprecated but remains active**.
Module is marked `@doc "**Deprecated**"` but still implements all callbacks and
is fully tested. If truly deprecated, add `@deprecated` annotations and a
compile-time warning, or remove it.

---

## 7. Additional Findings

### 7.1 `Pote.Orchestrator` module attribute `@named_colors` at compile time

**Finding P2-10** — `lib/pote/orchestrator.ex:46-67`:
```elixir
@named_colors Basic.named_colors()
              |> Map.merge(%{
                ...
                success: :theme_color,
                ...
              })
```
This embeds ~30 color entries + 9 `:theme_color` sentinels in the compiled
module attribute. For runtime theme resolution, the `:theme_color` sentinels
always hit the resolver path. This is correct but means the named-colors map
is **fixed at compile time** — adding new theme-aware colors requires a
recompile. Consider making this a runtime function if dynamic extension is
needed.

### 7.2 `Gradients.multicolor/2` segment rounding

**Finding P1-07** — `lib/pote/gradients.ex:75`:
```elixir
steps_per_segment = max(1, div(steps - 1, segment_count))
```
Integer division truncates, so the total stops can be **less than** `steps`.
For example, `multicolor(3 colors, 4 steps)`:
- `segment_count = 2`
- `steps_per_segment = div(3, 2) = 1`
- Produces: segment 0 → 1 stop, segment 1 → 1 stop = **2 total** instead of 4

This is a correctness bug.

### 7.3 Dead branch in `Gradients.linear/3`

`lib/pote/gradients.ex:50-51`:
```elixir
def linear(_from, _to, 0), do: []
def linear(from, _to, 1), do: [from]
```
These are unreachable because the guard `when steps >= 2` on the first clause
means these later clauses match when `steps < 2`. However, they are never
called with `steps=0` or `steps=1` from the public API (the guard on the
primary clause prevents it). These clauses are defensive but technically dead
for the public interface.

### 7.4 XTerm256 cube edge cases

**Finding P2-11** — `lib/pote/converters/xterm256.ex:16-17`:
```elixir
def to_rgb(index) when index in 232..255 do
  gray = (index - 232) * 10 + 8
```
This produces greys from 8 to 238. The XTerm256 spec has greys from 8 to 238,
which is correct. However, the cube formula at line 21:
```elixir
r = div(index, 36) * 51
```
produces values `{0, 51, 102, 153, 204, 255}` for R/G/B channels. This is the
standard 6×6×6 cube. Correct.

### 7.5 Theme JSON persistence robustness

**Finding P2-12** — `lib/pote/theme.ex:199-214`:
```elixir
def save_theme(%Theme{} = theme, storage_dir) do
  dir = expand_path(storage_dir) || ""
  ...
```
When `storage_dir` is `nil`, `expand_path(nil)` returns `nil`, then `dir`
becomes `""`. Writing to `Path.join("", "#{name}.json")` produces just
`"name.json"` — the current working directory. This is a data-loss risk:
silently writing to CWD instead of failing loudly. Raise or return an error
when `storage_dir` is nil/empty.

---

## 8. Detailed Issue Register

| ID | Severity | File | Line | Description |
|----|----------|------|------|-------------|
| P1-01 | 🟠 | `lib/pote.ex` | 185-188 | Dead `catch` clause in `resolve_default_color/1` |
| P1-02 | 🟠 | `lib/pote/theme.ex` | 183-189 | Dead `catch` clause in `safe_decode/1` |
| P1-03 | 🟠 | `lib/pote/theme.ex` | 369-376 | `ensure_registered/0` case always matches `_`, re-registers on every call |
| P1-04 | 🟠 | `lib/pote/converters/rgb.ex` | 109 | `Float.round(1)` on hue loses precision, compounds through harmonies |
| P1-05 | 🟠 | multiple | see §3.2 | No consistent rounding policy across color math |
| P1-06 | 🟠 | `test/pote/property_test.exs` | 1-76 | Only 3 property tests, no CMYK/HSL/HSV/HWB/Advanced roundtrips |
| P1-07 | 🟠 | `lib/pote/gradients.ex` | 75 | `div(steps-1, segment_count)` truncation can under-count gradient stops |
| P2-01 | 🟡 | `lib/pote/converters.ex` | 13-24 | 12 functions without `@spec` annotations |
| P2-02 | 🟡 | multiple | — | Private functions with `@spec` annotations |
| P2-03 | 🟡 | multiple | — | Three different error return shapes (`:error`, `{:error, atom}`, `{:error, String.t()}`) |
| P2-04 | 🟡 | `lib/pote/sanitizer.ex` | 29-35 | Overly broad `rescue _ -> :error` |
| P2-05 | 🟡 | `lib/pote/converters/rgb.ex` | 139-155 | CMYK can produce tiny negative values from float division |
| P2-06 | 🟡 | `lib/pote/converters/hwb.ex` | 19 | Division by near-zero when `w+b` is extremely small |
| P2-07 | 🟡 | `test/pote/converters/` | — | No dedicated property tests for CMYK/HWB/Advanced |
| P2-08 | 🟡 | `lib/pote/theme.ex` | 262-420 | Very large `__using__/1` macro (160 lines, 15+ generated functions) |
| P2-09 | 🟡 | `lib/pote/converters.ex` | 13-24 | Zero per-function `@doc` on facade delegation |
| P2-10 | 🟡 | `lib/pote/orchestrator.ex` | 46-67 | `@named_colors` fixed at compile time |
| P2-11 | 🟡 | `lib/pote/converters/xterm256.ex` | 16-17 | XTerm256 gray formula — verify against spec (currently correct) |
| P2-12 | 🟡 | `lib/pote/theme.ex` | 199-200 | `storage_dir = nil` silently writes to CWD |
| P3-01 | 🟢 | `lib/pote/converters/rgb.ex` | 183 | Spanish text in English docs |
| P3-02 | 🟢 | `lib/pote/converters/advanced.ex` | 146, 190 | Spanish comments |
| P3-03 | 🟢 | `lib/pote/format/ansi.ex` | 1-108 | Deprecated module still live without `@deprecated` annotation |
| P3-04 | 🟢 | `lib/pote/gradients.ex` | 50-51 | Dead branches for `steps=0` and `steps=1` |

---

## 9. Dependency Analysis

| Dependency | Version | Type | Audit |
|------------|---------|------|-------|
| `jason` | ~> 1.4 | runtime | ✅ Mature, well-tested. Used only in `Pote.Theme` for theme JSON persistence. |
| `credo` | ~> 1.7 | dev/test | ✅ Zero violations. |
| `dialyxir` | ~> 1.4 | dev/test | ⚠️ Not run in this audit. Run `mix dialyzer` to catch typespec issues (esp. P2-01). |
| `ex_doc` | ~> 0.34 | dev | ✅ |
| `excoveralls` | ~> 0.18 | test | ✅ |
| `stream_data` | ~> 1.0 | test | ✅ Used for 3 properties. |

**Pote has ZERO internal Lorenzo-SF dependencies.** It is the root color
library — consumed by Alaja, indirectly by Delfos and Arrea.

---

## 10. Recommendations by Priority

### Immediate (P1)

1. **Remove dead catch clauses** (P1-01, P1-02) — 5 minutes. No test changes needed.
2. **Fix `ensure_registered/0`** (P1-03) — Replace `case` with direct call or
   add a real guard checking if resolver is already registered.
3. **Add missing property tests** (P1-06) — Add roundtrip properties for CMYK,
   HSL, HSV, HWB using `StreamData`. ~1 hour.
4. **Fix `multicolor` segment count** (P1-07) — Replace integer `div` with
   float-based distribution that guarantees exact `steps` output. ~30 minutes.
5. **Standardise rounding policy** (P1-05) — Document and apply consistently.
   Remove intermediate `Float.round()` calls in `Advanced` converters. ~1 hour.

### Next cycle (P2)

1. **Add `@spec` to `Converters` facade** (P2-01).
2. **Unify error shapes** (P2-03) — Standardise format parse errors.
3. **Guard HWB division by zero** (P2-06).
4. **Guard nil `storage_dir`** (P2-12) — Raise on nil instead of CWD write.
5. **Refactor `Theme.__using__/1`** (P2-08) — Extract generated logic into a
   runtime module.

### Boy-scout (P3)

1. Translate Spanish docs/comments to English (P3-01, P3-02).
2. Add `@deprecated` to `Pote.Format.ANSI` (P3-03).
3. Remove dead branches from `Gradients.linear/3` (P3-04).

---

## Cómo usar esta auditoría

### Interpretación

- **P0 (🔴)**: Debe corregirse antes de cualquier release. Riesgo de crash, seguridad, o pérdida de datos.
- **P1 (🟠)**: Debe corregirse en el próximo ciclo. Degradación significativa de calidad o seguridad.
- **P2 (🟡)**: Debe corregirse cuando se toque el módulo afectado. Deuda técnica.
- **P3 (🟢)**: Conveniencia o estilo. Bajo impacto.

### Flujo de trabajo autónomo

Este documento, junto con `ARCHITECTURE.md` (diseño del proyecto) e `INDEX.md` (navegación de docs), contiene toda la información necesaria para abordar las correcciones de forma autónoma:

1. **Lee ARCHITECTURE.md** primero — entiende el diseño, subsistemas y decisiones clave.
2. **Lee INDEX.md** — localiza los archivos y módulos relevantes.
3. **Vuelve a esta auditoría** — prioriza por severidad (P0 → P1 → P2 → P3).
4. **Para cada hallazgo**: el fichero y línea están indicados. El código fuente relevante está en `lib/`.
5. **Ejecuta `mix test --cover`** antes y después para medir el impacto.
6. **Ejecuta `mix credo --all`** para garantizar que no introduces nuevas violaciones.
7. **Si el hallazgo implica cambiar una interfaz pública**, verifica los proyectos consumidores (listados en ARCHITECTURE.md §consumed-by).

### Dependencias entre proyectos

Pote depende de **apero** (para persistencia JSON de temas). Se recomienda leer la auditoría de apero primero (`../apero/docs/AUDIT.md`) para entender cualquier limitación en la capa de persistencia.

Pote es consumido por **alaja** (UI/TUI rendering) y, a través de este, por **arrea** y **delfos**. Si modificas una interfaz pública de pote (tipos de color, estructura de temas, funciones de conversión), verifica que alaja sigue compilando y pasando sus tests.

### Checklist por severidad

**Al corregir un P0**:
- [ ] Aísla la causa raíz (línea exacta)
- [ ] Escribe un test que reproduzca el fallo **antes** de corregir
- [ ] Aplica la corrección
- [ ] Verifica que el test pasa
- [ ] Ejecuta `mix test --cover` — la cobertura no debe disminuir
- [ ] Ejecuta `mix credo --all` — cero nuevas violaciones
- [ ] Si cambia una interfaz pública, verifica proyectos consumidores

**Al corregir un P1**:
- [ ] Identifica todos los lugares donde se aplica el patrón (grep por el código similar)
- [ ] Testea el cambio (unitario + integración si aplica)
- [ ] Verifica `mix test --cover` no baja
- [ ] Si afecta a consumidores, actualiza sus tests también

**Al corregir P2/P3**:
- [ ] Corrige cuando toques el módulo por otra razón (boy-scout rule)
- [ ] No merecen un esfuerzo dedicado si no hay un bug reportado
