# Pote — Colorimetry and theme management for Elixir

[![Hex Version](https://img.shields.io/hexpm/v/pote.svg)](https://hex.pm/packages/pote)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3.svg)](https://hexdocs.pm/pote)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.md)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/Lorenzo-SF/pote)

Pote is an Elixir library for comprehensive color manipulation: parsing, conversion
between all major color spaces, harmony generation, gradient creation, accessibility
checks, and terminal ANSI output.

## Quick Start

Add `pote` to your `mix.exs`:

```elixir
def deps do
  [
    {:pote, "~> 1.0.0"}
  ]
end
```

Basic usage:

```elixir
# Parse a color from any format into RGB
{:ok, rgb} = Pote.Orchestrator.parse_color("#FF8000")
{:ok, rgb} = Pote.Orchestrator.parse_color("hsl:30,100,50")
{:ok, rgb} = Pote.Orchestrator.parse_color(:red)

# Generate harmonies
Pote.Harmonies.complementary({255, 87, 51})
# => [{51, 219, 255}]

Pote.Harmonies.triad({255, 87, 51})
# => [{51, 255, 87}, {87, 51, 255}]

# Create gradients
Pote.Gradients.linear({255, 0, 0}, {0, 0, 255}, 5)
# => [{255, 0, 0}, {191, 0, 64}, {128, 0, 128}, {64, 0, 191}, {0, 0, 255}]

# Apply gradient to text for terminal output
Pote.Gradients.apply_to_text("Hello, world!", {255, 0, 0}, {0, 0, 255})
```

## Features

- **Color parsing** — Accept RGB, HEX, HSL, HSV, CMYK, HWB, XTerm256, named colors,
  ARGB, and theme colors from strings, tuples, or atoms.
- **Conversion** — Bidirectional conversion between RGB, HEX, HSL, HSV, CMYK,
  XTerm256, CIE XYZ, CIELAB, YUV, YCbCr, HWB, and Kelvin.
- **Harmonies** — Complementary, analogous, triad, square,
  split-complementary, compound, and monochromatic color schemes.
- **Gradients** — Linear, multi-stop gradients; apply foreground/background
  gradients to text for terminal UIs; vertical gradient fills.
- **ANSI output** — Generate true-color and 256-color ANSI escape sequences
  for foreground and background.
- **Accessibility** — WCAG 2.1 relative luminance, contrast ratio, and
  Delta E 1976 color distance.
- **Validation** — Validate color format strings with descriptive error messages.
- **Pantone approximation** — Find the closest Pantone match for any RGB color.
- **Named colors** — Built-in palette of basic, bright, light, and theme colors
  with custom theme support.
- **ColorInfo struct** — Convenient struct for storing a color in all formats
  with harmony helpers.

## Supported Color Formats

| Format     | Input Examples                          | Range                                     |
|------------|-----------------------------------------|-------------------------------------------|
| RGB        | `{255, 128, 0}`, `"rgb:255,128,0"`      | 0–255 per channel                         |
| ARGB       | `"argb:255,255,128,0"`                  | 0–255 per channel (alpha ignored)         |
| HEX        | `"#FF8000"`, `"FF8000"`, `"#F80"`       | `#RRGGBB`, `#RGB`                         |
| HSL        | `{30.0, 100.0, 50.0}`, `"hsl:30,100,50"` | H: 0–360°, S/L: 0–100%                  |
| HSV        | `{30.0, 100.0, 100.0}`, `"hsv:30,100,100"` | H: 0–360°, S/V: 0–100%                 |
| CMYK       | `"cmyk:0,50,100,0"`                     | 0–100% per channel                        |
| HWB        | `"hwb:30,0.2,0.3"`                      | H: 0–360°, W/B: 0.0–1.0                   |
| XTerm256   | `208`, `"xterm:208"`                    | 0–255                                     |
| Named      | `:red`, `"cyan"`, `"bright_green"`      | —                                         |
| Theme      | `"theme:primary"`, `"theme:error"`      | —                                         |
| XYZ        | — (conversion output)                   | —                                         |
| CIELAB     | — (conversion output)                   | L: 0–100, a/b: ~–128–127                  |
| YUV        | — (conversion output)                   | Y: 0–255, U/V: –128–127                   |
| YCbCr      | — (conversion output)                   | Y: 16–235, Cb/Cr: 16–240                  |
| Kelvin     | `Pote.Conversions.kelvin_to_rgb(6500)`  | 1000–40000                                |

## Usage Examples

### Parse any color into RGB

```elixir
alias Pote.Orchestrator

Orchestrator.parse_color("#FF8000")
# => {:ok, {255, 128, 0}}

Orchestrator.parse_color("rgb:255,128,0")
# => {:ok, {255, 128, 0}}

Orchestrator.parse_color("hsl:30,100,50")
# => {:ok, {255, 128, 0}}

Orchestrator.parse_color(:magenta)
# => {:ok, {255, 0, 255}}

Orchestrator.parse_color("theme:primary")
# => {:ok, {161, 231, 250}}

# Bang (!) variant
Orchestrator.to_rgb!("#FF8000")
# => {255, 128, 0}
```

### Convert between color spaces

```elixir
alias Pote.Conversions

Conversions.rgb_to_hex({255, 128, 0})
# => "#FF8000"

Conversions.rgb_to_hsl({255, 128, 0})
# => {30.0, 100.0, 50.0}

Conversions.rgb_to_cmyk({255, 128, 0})
# => {0.0, 49.8, 100.0, 0.0}

Conversions.rgb_to_xterm256({255, 128, 0})
# => 208

Conversions.hsl_to_rgb({30.0, 100.0, 50.0})
# => {255, 128, 0}

# Advanced: color temperature
Conversions.kelvin_to_rgb(6500)
# => {255, 249, 253}

Conversions.rgb_to_kelvin({255, 160, 60})
# => 3200

# Advanced: video color spaces
Conversions.rgb_to_yuv({255, 128, 0})
# => {165, 13, 146}

Conversions.rgb_to_ycbcr({255, 128, 0})
# => {165, 69, 224}
```

### Terminal ANSI output

```elixir
alias Pote.Orchestrator

# Foreground ANSI escape code
Orchestrator.to_ansi({255, 128, 0})
# => "\e[38;2;255;128;0m"

Orchestrator.to_ansi("#FF8000")
# => "\e[38;2;255;128;0m"

# Background ANSI escape code
Orchestrator.to_ansi_bg({255, 128, 0})
# => "\e[48;2;255;128;0m"

# Convert to XTerm256 index
Orchestrator.to_xterm256({255, 128, 0})
# => {:ok, 208}

# Print colored text in terminal
IO.puts("#{Orchestrator.to_ansi({255, 128, 0})}Hello in orange!#{IO.ANSI.reset()}")
```

### Color harmonies

```elixir
alias Pote.Harmonies

color = {255, 87, 51}

Harmonies.complementary(color)
# => [{51, 219, 255}]

Harmonies.analogous(color)
# => [{255, 128, 0}, {255, 0, 128}]

Harmonies.triad(color)
# => [{51, 255, 87}, {87, 51, 255}]

Harmonies.square(color)
# => [{179, 255, 51}, {51, 219, 255}, {87, 51, 255}]

Harmonies.monochromatic(color, 5)
# => [darker...to...lighter variations]

Harmonies.split_complementary(color)
# => [{87, 255, 51}, {219, 51, 255}]

# Lightness utilities
Harmonies.lighter(color, 0.2)
# => blends with white

Harmonies.darker(color, 0.4)
# => blends with black
```

### Gradients

```elixir
alias Pote.Gradients

# Linear gradient between two colors
Gradients.linear({255, 0, 0}, {0, 0, 255}, 5)
# => [{255, 0, 0}, {191, 0, 64}, {128, 0, 128}, {64, 0, 191}, {0, 0, 255}]

# Multi-stop gradient
Gradients.multicolor([{255, 0, 0}, {0, 255, 0}, {0, 0, 255}], 5)
# => [{255, 0, 0}, {128, 128, 0}, {0, 255, 0}, {0, 128, 128}, {0, 0, 255}]

# Gradient text (terminal)
Gradients.apply_to_text("Pote", {255, 0, 0}, {0, 0, 255})
# => iodata with gradient-colored characters

# Gradient background for text
Gradients.apply_bg_to_text("Pote", {255, 0, 0}, {0, 0, 255})

# Vertical gradient fill
Gradients.vertical_fill({0, 0, 100}, {100, 0, 0}, 5, 10)
```

### Accessibility

```elixir
alias Pote.Conversions

# WCAG 2.1 contrast ratio
Conversions.contrast_ratio({255, 255, 255}, {0, 0, 0})
# => 21.0

# WCAG 2.1 relative luminance
Conversions.relative_luminance({0, 128, 0})
# => 0.25016

# Delta E 1976 color distance (< 1.0 is imperceptible)
Conversions.delta_e({255, 0, 0}, {254, 0, 0})
# => ~0.4
```

### Validation

```elixir
alias Pote.Validator

Validator.validate("hex:FF0000")
# => :ok

Validator.validate("rgb:256,0,0")
# => {:error, :rgb_value_out_of_range}

Validator.error_message(:rgb_value_out_of_range)
# => "RGB values must be integers between 0 and 255"
```

### ColorInfo struct

```elixir
alias Pote.ColorInfo

# Create from any color input
ci = ColorInfo.new({255, 128, 0})
%ColorInfo{rgb: {255, 128, 0}, hex: "#FF8000", hsl: {30.0, 100.0, 50.0}, ...}

# ANSI escape
ColorInfo.to_ansi(ci)

# Harmony methods on the struct
ColorInfo.complementary(ci)
ColorInfo.triad(ci)
ColorInfo.analogous(ci, 15.0)
ColorInfo.lighter(ci, 0.3)
ColorInfo.darker(ci, 0.3)
```

### Default palette

```elixir
Pote.default_colors()
# => %{primary: {161, 231, 250}, secondary: {58, 171, 163}, ...}

Pote.get_color(:primary)
# => {161, 231, 250}

Pote.color_names()
# => [:primary, :secondary, :ternary, ...]
```

## Installation

Add `pote` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pote, "~> 1.0.0"}
  ]
end
```

Generate documentation with ExDoc:

```sh
mix docs
```

## License

MIT License. See [LICENSE](LICENSE) for details.
