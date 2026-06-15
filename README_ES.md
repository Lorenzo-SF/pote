# Pote — Colorimetría y gestión de temas para Elixir

[![Versión en Hex](https://img.shields.io/hexpm/v/pote.svg)](https://hex.pm/packages/pote)
[![Documentación Hex](https://img.shields.io/badge/hex-docs-ffaff3.svg)](https://hexdocs.pm/pote)
[![Licencia](https://img.shields.io/badge/licencia-MIT-blue.svg)](LICENSE.md)

Pote es una biblioteca para Elixir de manipulación completa de colores: parseo,
conversión entre todos los espacios de color principales, generación de armonías,
creación de gradientes, comprobaciones de accesibilidad y salida ANSI para terminal.

## Inicio rápido

Añade `pote` a tu `mix.exs`:

```elixir
def deps do
  [
    {:pote, "~> 1.0.0"}
  ]
end
```

Uso básico:

```elixir
# Parsea un color desde cualquier formato a RGB
{:ok, rgb} = Pote.Orchestrator.parse_color("#FF8000")
{:ok, rgb} = Pote.Orchestrator.parse_color("hsl:30,100,50")
{:ok, rgb} = Pote.Orchestrator.parse_color(:red)

# Genera armonías
Pote.Harmonies.complementary({255, 87, 51})
# => [{51, 219, 255}]

Pote.Harmonies.triad({255, 87, 51})
# => [{51, 255, 87}, {87, 51, 255}]

# Crea gradientes
Pote.Gradients.linear({255, 0, 0}, {0, 0, 255}, 5)
# => [{255, 0, 0}, {191, 0, 64}, {128, 0, 128}, {64, 0, 191}, {0, 0, 255}]

# Aplica gradiente a texto para salida en terminal
Pote.Gradients.apply_to_text("¡Hola mundo!", {255, 0, 0}, {0, 0, 255})
```

## Características

- **Parseo de colores** — Acepta RGB, HEX, HSL, HSV, CMYK, HWB, XTerm256,
  colores con nombre, ARGB y colores de tema desde strings, tuplas o átomos.
- **Conversión** — Conversión bidireccional entre RGB, HEX, HSL, HSV, CMYK,
  XTerm256, CIE XYZ, CIELAB, YUV, YCbCr, HWB y Kelvin.
- **Armonías** — Esquemas complementarios, análogos, triádicos, cuadrados,
  tetrádicos, complementarios divididos, compuestos y monocromáticos.
- **Gradientes** — Gradientes lineales, multi-parada; aplicación de
  gradientes de primer plano/fondo a texto para UIs de terminal; rellenos
  de gradiente vertical.
- **Salida ANSI** — Genera secuencias de escape ANSI true-color y de 256
  colores para primer plano y fondo.
- **Accesibilidad** — Luminancia relativa WCAG 2.1, ratio de contraste y
  distancia Delta E 1976.
- **Validación** — Valida cadenas de formato de color con mensajes de error
  descriptivos.
- **Aproximación Pantone** — Encuentra la coincidencia Pantone más cercana
  para cualquier color RGB.
- **Colores con nombre** — Paleta integrada de colores básicos, brillantes,
  claros y de tema con soporte para temas personalizados.
- **Struct ColorInfo** — Struct práctico para almacenar un color en todos
  los formatos con helpers de armonía.

## Formatos de color soportados

| Formato    | Ejemplos de entrada                      | Rango                                     |
|------------|------------------------------------------|-------------------------------------------|
| RGB        | `{255, 128, 0}`, `"rgb:255,128,0"`       | 0–255 por canal                           |
| ARGB       | `"argb:255,255,128,0"`                   | 0–255 por canal (alpha ignorado)          |
| HEX        | `"#FF8000"`, `"FF8000"`, `"#F80"`        | `#RRGGBB`, `#RGB`                         |
| HSL        | `{30.0, 100.0, 50.0}`, `"hsl:30,100,50"` | H: 0–360°, S/L: 0–100%                   |
| HSV        | `{30.0, 100.0, 100.0}`, `"hsv:30,100,100"` | H: 0–360°, S/V: 0–100%                  |
| CMYK       | `"cmyk:0,50,100,0"`                      | 0–100% por canal                          |
| HWB        | `"hwb:30,0.2,0.3"`                       | H: 0–360°, W/B: 0.0–1.0                   |
| XTerm256   | `208`, `"xterm:208"`                     | 0–255                                     |
| Con nombre | `:red`, `"cyan"`, `"bright_green"`       | —                                         |
| Tema       | `"theme:primary"`, `"theme:error"`       | —                                         |
| XYZ        | — (salida de conversión)                 | —                                         |
| CIELAB     | — (salida de conversión)                 | L: 0–100, a/b: ~–128–127                  |
| YUV        | — (salida de conversión)                 | Y: 0–255, U/V: –128–127                   |
| YCbCr      | — (salida de conversión)                 | Y: 16–235, Cb/Cr: 16–240                  |
| Kelvin     | `Pote.Conversions.kelvin_to_rgb(6500)`   | 1000–40000                                |

## Ejemplos de uso

### Parsear cualquier color a RGB

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

# Variante con bang (!)
Orchestrator.to_rgb!("#FF8000")
# => {255, 128, 0}
```

### Convertir entre espacios de color

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

# Avanzado: temperatura de color
Conversions.kelvin_to_rgb(6500)
# => {255, 249, 253}

Conversions.rgb_to_kelvin({255, 160, 60})
# => 3200

# Avanzado: espacios de color de video
Conversions.rgb_to_yuv({255, 128, 0})
# => {165, 13, 146}

Conversions.rgb_to_ycbcr({255, 128, 0})
# => {165, 69, 224}
```

### Salida ANSI para terminal

```elixir
alias Pote.Orchestrator

# Código de escape ANSI para primer plano
Orchestrator.to_ansi({255, 128, 0})
# => "\e[38;2;255;128;0m"

Orchestrator.to_ansi("#FF8000")
# => "\e[38;2;255;128;0m"

# Código de escape ANSI para fondo
Orchestrator.to_ansi_bg({255, 128, 0})
# => "\e[48;2;255;128;0m"

# Convertir a índice XTerm256
Orchestrator.to_xterm256({255, 128, 0})
# => {:ok, 208}

# Imprimir texto coloreado en la terminal
IO.puts("#{Orchestrator.to_ansi({255, 128, 0})}¡Hola en naranja!#{IO.ANSI.reset()}")
```

### Armonías de color

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
# => [variaciones de más oscuro...a...más claro]

Harmonies.split_complementary(color)
# => [{87, 255, 51}, {219, 51, 255}]

# Utilidades de luminosidad
Harmonies.lighter(color, 0.2)
# => mezcla con blanco

Harmonies.darker(color, 0.4)
# => mezcla con negro
```

### Gradientes

```elixir
alias Pote.Gradients

# Gradiente lineal entre dos colores
Gradients.linear({255, 0, 0}, {0, 0, 255}, 5)
# => [{255, 0, 0}, {191, 0, 64}, {128, 0, 128}, {64, 0, 191}, {0, 0, 255}]

# Gradiente multi-parada
Gradients.multicolor([{255, 0, 0}, {0, 255, 0}, {0, 0, 255}], 5)
# => [{255, 0, 0}, {128, 128, 0}, {0, 255, 0}, {0, 128, 128}, {0, 0, 255}]

# Texto con gradiente (terminal)
Gradients.apply_to_text("Pote", {255, 0, 0}, {0, 0, 255})
# => iodata con caracteres coloreados en gradiente

# Fondo con gradiente para texto
Gradients.apply_bg_to_text("Pote", {255, 0, 0}, {0, 0, 255})

# Relleno de gradiente vertical
Gradients.vertical_fill({0, 0, 100}, {100, 0, 0}, 5, 10)
```

### Accesibilidad

```elixir
alias Pote.Conversions

# Ratio de contraste WCAG 2.1
Conversions.contrast_ratio({255, 255, 255}, {0, 0, 0})
# => 21.0

# Luminancia relativa WCAG 2.1
Conversions.relative_luminance({0, 128, 0})
# => 0.25016

# Distancia Delta E 1976 (< 1.0 es imperceptible)
Conversions.delta_e({255, 0, 0}, {254, 0, 0})
# => ~0.4
```

### Validación

```elixir
alias Pote.Validator

Validator.validate("hex:FF0000")
# => :ok

Validator.validate("rgb:256,0,0")
# => {:error, :rgb_value_out_of_range}

Validator.error_message(:rgb_value_out_of_range)
# => "RGB values must be integers between 0 and 255"
```

### Struct ColorInfo

```elixir
alias Pote.ColorInfo

# Crear desde cualquier entrada de color
ci = ColorInfo.new({255, 128, 0})
%ColorInfo{rgb: {255, 128, 0}, hex: "#FF8000", hsl: {30.0, 100.0, 50.0}, ...}

# Escape ANSI
ColorInfo.to_ansi(ci)

# Métodos de armonía en el struct
ColorInfo.complementary(ci)
ColorInfo.triad(ci)
ColorInfo.analogous(ci, 15.0)
ColorInfo.lighter(ci, 0.3)
ColorInfo.darker(ci, 0.3)
```

### Paleta por defecto

```elixir
Pote.default_colors()
# => %{primary: {161, 231, 250}, secondary: {58, 171, 163}, ...}

Pote.get_color(:primary)
# => {161, 231, 250}

Pote.color_names()
# => [:primary, :secondary, :ternary, ...]
```

## Instalación

Añade `pote` a tu lista de dependencias en `mix.exs`:

```elixir
def deps do
  [
    {:pote, "~> 1.0.0"}
  ]
end
```

Genera la documentación con ExDoc:

```sh
mix docs
```

## Licencia

Licencia MIT. Consulta [LICENSE](LICENSE.md) para más detalles.
