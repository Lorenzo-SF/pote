# Pote — Architectural Reference

> Colorimetry and theme/palette management for Elixir — v2.2.0

---

## 1. What is Pote

Pote is the **color management and theme system** of the Lorenzo-SF ecosystem.
It parses colors from any format (hex, RGB, HSL, HSV, CMYK, HWB, XTerm256,
named), converts between color spaces, generates harmonies and gradients,
and provides a pluggable theme system that other projects use to resolve
color keys at runtime.

---

## 2. Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                        Pote (Facade)                          │
│  lib/pote.ex — parse/1, color/1, theme_resolver/0            │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐    │
│  │ Orchestrator│  │   Validator  │  │    Sanitizer     │    │
│  │             │  │              │  │                  │    │
│  │ parse_color │  │ validate/1   │  │ sanitize/1       │    │
│  │ to_rgb      │  │ error_msg   │  │ strip suffixes   │    │
│  │ to_color_info│  │              │  │                  │    │
│  └──────┬──────┘  └──────────────┘  └──────────────────┘    │
│         │                                                     │
│  ┌──────▼──────────────────────────────────────────────────┐ │
│  │                     Format Handlers                       │ │
│  │  (Pote.Format behaviour + 9 implementations)             │ │
│  │                                                          │ │
│  │  RGB  HEX  HSL  HSV  CMYK  ARGB  Atom  ANSI  XTerm256   │ │
│  │  Each implements: parse, to_rgb, from_rgb, valid?,       │ │
│  │  to_hex, to_hsl, to_cmyk, to_xterm256, name, info       │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                    Converters                             │ │
│  │  (Pote.Converters facade + 9 implementations)            │ │
│  │                                                          │ │
│  │  RGB ←→ HEX  ←→ HSL  ←→ HSV  ←→ CMYK  ←→ XTerm256      │ │
│  │  RGB ←→ HWB  CIE XYZ  CIELAB  Delta E                   │ │
│  │  WCAG Contrast  YUV  YCbCr  Kelvin ←→ RGB               │ │
│  │  Pantone matching (~140 colors, Delta E nearest)         │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ Harmonies│  │  Gradients   │  │     Theme System      │   │
│  │          │  │              │  │                       │   │
│  │ complem  │  │ linear       │  │ Pote.Theme (struct)   │   │
│  │ analogous│  │ multicolor   │  │   behaviour via use   │   │
│  │ triad    │  │ apply_to_text│  │   5 built-in themes   │   │
│  │ monochr  │  │ vertical_fill│  │   JSON persistence    │   │
│  └──────────┘  └──────────────┘  │   resolver stack      │   │
│                                  └──────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐│
│  │                 Color Data                                ││
│  │  Pote.Colors.Basic: 16 ANSI + extended named colors      ││
│  │  Pote.ColorInfo: struct across all formats               ││
│  └──────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────┘
```

---

## 3. Subsystems

### 3.1 Orchestrator (Pote.Orchestrator)
- Central color parsing hub (607 lines)
- `parse_color/1` — detects input format, dispatches to correct `Pote.Format` handler
- `to_rgb/1`, `to_ansi/1`, `to_xterm256/1` — conversion endpoints
- `to_color_info/1` — builds `Pote.ColorInfo` with all format representations
- Parses prefix-tagged strings: `hex:`, `rgb:`, `argb:`, `hsl:`, `hsv:`, `cmyk:`, `hwb:`, `xterm:`, `theme:`

### 3.2 Validator (Pote.Validator)
- Validates prefixed color strings before parsing
- Checks value ranges, decimal places, bracket style
- `validate/1` → `:ok` or `{:error, message}`

### 3.3 Sanitizer (Pote.Sanitizer)
- Strips unit suffixes (`º`, `deg`, `%`) from color strings
- `sanitize/1` → cleaned string ready for parsing

### 3.4 Format Handlers (Pote.Format behaviour)
- 9 implementations: RGB, HEX, HSL, HSV, CMYK, ARGB, Atom, ANSI, XTerm256
- Each implements: `parse/1`, `to_rgb/1`, `from_rgb/1`, `valid?/1`, `to_hex/1`,
  `to_argb/1`, `to_hsl/1`, `to_hsv/1`, `to_cmyk/1`, `to_xterm256/1`, `name/1`, `info/1`
- Default implementations provided via `__using__` macro

### 3.5 Converters (Pote.Converters)
- **RGB converter** (the hub, 206 lines): conversions RGB ↔ all other formats
  `to_hex`, `from_hex`, `to_hsl`, `to_hsv`, `to_cmyk`, `to_xterm256`
  Also: `blend/3`, `color_distance/2`, `clamp/1`
- **HSL/HSV/CMYK/HWB converters**: `to_rgb` / `from_rgb`
- **XTerm256 converter**: 0-15 system, 16-231 cube, 232-255 grayscale
- **Advanced converter** (580 lines): CIE XYZ, CIELAB, Delta E 1976,
  WCAG contrast ratio (luminance), YUV (BT.601), YCbCr (BT.601),
  Color temperature (Kelvin ↔ RGB), Pantone matching (~140 colors)

### 3.6 Harmonies (Pote.Harmonies)
- Pure functions on RGB tuples via hue rotation in HSL space
- `complementary`, `analogous`, `triad`, `square`, `monochromatic`,
  `split_complementary`, `compound`, `lighter`, `darker`

### 3.7 Gradients (Pote.Gradients)
- `linear/3` — two-color gradient
- `multicolor/2` — multi-stop gradient
- `apply_to_text/4` — ANSI-colored text
- `vertical_fill/5` — vertical terminal fill

### 3.8 Theme System (Pote.Theme)
- `Pote.Theme` struct: `name`, `description`, `colors` (22+ color keys)
- **Behaviour** via `__using__` macro:
  - Host app calls `use Pote.Theme, config_app: :my_app, defaults: %{...}`
  - Generates: `list/0`, `active/0`, `activate/1`, `color/1`, `colors/0`,
    `install!/1`, `install_template/1`, `templates/0`
  - Auto-registers theme resolver with `Pote`
- **5 built-in templates**: `default`, `dracula`, `monokai`, `nord`, `light`
- **JSON persistence**: atomic writes, path expansion, resolver stack
- **Resolver stack** allows multiple themes to compose (e.g., app theme + user override)

---

## 4. Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| Jason | ~> 1.4 | JSON encoding/decoding for theme files |

**Pote has NO internal Lorenzo-SF dependencies.** It is the root color
library of the ecosystem, consumed by Alaja and any app that needs colors.

---

## 5. Consumed by

| Project | What it uses |
|---------|--------------|
| **Alaja** | `Pote.Theme` (via `use Pote.Theme`), `Pote.Converters`, `Pete.Orchestrator` for ANSI rendering, cell colors, gradient generation, syntax highlighting themes |
| **Delfos** | (indirectly via Alaja — Alaja resolves theme colors through Pote) |
| Any Lorenzo-SF app | Theme system via `use Pote.Theme` |

---

## 6. Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **RGB as canonical format** | All conversions go RGB → target or target → RGB. Single hub simplifies the conversion graph from O(n²) to O(n). |
| **Prefix-tagged input strings** | `hex:#ff0000`, `rgb:255,0,0`, `theme:primary` — unambiguous format detection without guessing. |
| **`Pote.Format` behaviour** | Adding a new color format = implement 1 behaviour + register in Orchestrator. No core changes needed. |
| **Theme as `__using__` macro** | Host apps get a zero-boilerplate theme facade. `config_app`, `defaults` parameters tune the generated code. |
| **Resolver stack** | Multiple themes can coexist. App theme → user theme → built-in defaults. Each layer overrides the previous. |
| **JSON file persistence** | Themes are human-editable JSON. Atomic writes prevent corruption. |
| **No runtime deps besides Jason** | Pote is deliberately dependency-light. Color math is pure Elixir. |

---

## 7. Current State (v2.2.0 — Jul 2026)

- 30 source modules
- 24 test files with property-based tests (StreamData)
- Pending: `Pote.Converters.Generic` refactor (eliminate duplicated conversion logic)
- Pending: Dedicated per-converter test files for HSL, HSV, CMYK, XTerm256, HWB

---

## 8. Usage Example

```elixir
# Parse a color from any format
{:ok, rgb} = Pote.parse("hex:#ff0000")

# Convert between formats
hex = Pote.Converters.rgb_to_hex({255, 0, 0})

# Generate harmonies
harmonies = Pote.Harmonies.complementary({255, 0, 0})

# Theme system
use Pote.Theme, config_app: :my_app, defaults: %{primary: {0, 120, 255}}
MyApp.Theme.color(:primary)        # → {0, 120, 255}
MyApp.Theme.activate(:dracula)     # → :ok
```
