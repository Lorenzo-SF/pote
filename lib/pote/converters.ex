defmodule Pote.Converters do
  @moduledoc """
  Módulo de conversiones de color.

  Este módulo actúa como namespace para los conversores específicos
  y mantiene backward compatibility con `Pote.Conversions`.

  ## Conversores disponibles

  - `Pote.Converters.RGB` - Conversiones hacia/desde RGB
  - `Pote.Converters.HSL` - Conversiones hacia/desde HSL
  - `Pote.Converters.HSV` - Conversiones hacia/desde HSV
  - `Pote.Converters.CMYK` - Conversiones hacia/desde CMYK
  - `Pote.Converters.XTerm256` - Conversiones hacia/desde XTerm256
  - `Pote.Converters.HWB` - Conversiones hacia/desde HWB
  - `Pote.Converters.XYZ` - Conversiones hacia/desde CIE XYZ
  - `Pote.Converters.LAB` - Conversiones hacia/desde CIELAB
  - `Pote.Converters.YUV` - Conversiones hacia/desde YUV
  - `Pote.Converters.YCbCr` - Conversiones hacia/desde YCbCr
  - `Pote.Converters.Kelvin` - Conversiones de temperatura de color

  ## Uso

      iex> Pote.Converters.RGB.to_hex({255, 128, 0})
      "#FF8000"

      iex> Pote.Converters.HSL.from_rgb({255, 128, 0})
      {30.0, 100.0, 50.0}

  Para backward compatibility, las funciones de `Pote.Conversions`
  siguen disponibles directamente en este módulo.
  """

  defmodule RGB do
    @moduledoc """
    Conversiones hacia/desde RGB.

    ## Ejemplos

        iex> Pote.Converters.RGB.to_hex({255, 128, 0})
        "#FF8000"

        iex> Pote.Converters.RGB.to_cmyk({255, 128, 0})
        {0.0, 49.8, 100.0, 0.0}
    """

    @type rgb :: Pote.rgb()
    @type hex :: Pote.hex()
    @type hsl :: Pote.hsl()
    @type hsv :: Pote.hsv()
    @type cmyk :: Pote.cmyk()
    @type xterm256 :: Pote.xterm256()

    @doc """
    Convierte RGB a hexadecimal.
    """
    @spec to_hex(rgb()) :: hex()
    def to_hex({r, g, b}) do
      "##{hex_component(r)}#{hex_component(g)}#{hex_component(b)}"
      |> String.upcase()
    end

    defp hex_component(n) do
      n
      |> Integer.to_string(16)
      |> String.pad_leading(2, "0")
    end

    @doc """
    Convierte hexadecimal a RGB.
    """
    @spec from_hex(hex()) :: {:ok, rgb()} | {:error, :invalid_hex_format}
    def from_hex(hex) when is_binary(hex) do
      hex = hex |> String.replace("#", "")

      hex =
        if String.length(hex) == 3 do
          hex |> String.graphemes() |> Enum.map_join(&(&1 <> &1))
        else
          hex
        end

      with {:ok, r} <- hex_part_to_int(String.slice(hex, 0, 2)),
           {:ok, g} <- hex_part_to_int(String.slice(hex, 2, 2)),
           {:ok, b} <- hex_part_to_int(String.slice(hex, 4, 2)) do
        {:ok, {r, g, b}}
      else
        _ -> {:error, :invalid_hex_format}
      end
    end

    defp hex_part_to_int(""), do: {:error, :invalid_hex_format}

    defp hex_part_to_int(part) do
      case Integer.parse(part, 16) do
        {value, ""} when value in 0..255 -> {:ok, value}
        _ -> {:error, :invalid_hex_format}
      end
    end

    @doc """
    Convierte RGB a HSL.
    """
    @spec to_hsl(rgb()) :: hsl()
    def to_hsl({r, g, b}) do
      r = r / 255
      g = g / 255
      b = b / 255

      max = Enum.max([r, g, b])
      min = Enum.min([r, g, b])
      delta = max - min

      l = (max + min) / 2

      if delta == 0 do
        {0.0, 0.0, l * 100.0}
      else
        s =
          if l < 0.5,
            do: delta / (max + min),
            else: delta / (2 - max - min)

        {calculate_h(r, g, b, delta), s * 100.0, l * 100.0}
      end
    end

    defp calculate_h(_r, _g, _b, delta) when delta == 0.0, do: 0.0

    defp calculate_h(r, g, b, delta) do
      h =
        cond do
          r >= g and r >= b -> (g - b) / delta
          g >= r and g >= b -> (b - r) / delta + 2
          b >= r and b >= g -> (r - g) / delta + 4
          true -> 0.0
        end

      h
      |> Kernel.*(60.0)
      |> normalize_h()
      |> Float.round(1)
    end

    defp normalize_h(h) when h < 0, do: h + 360
    defp normalize_h(h), do: h

    @doc """
    Convierte RGB a HSV.
    """
    @spec to_hsv(rgb()) :: hsv()
    def to_hsv({r, g, b}) do
      r = r / 255
      g = g / 255
      b = b / 255

      max = Enum.max([r, g, b])
      min = Enum.min([r, g, b])
      delta = max - min

      v = max
      s = if max == 0, do: 0.0, else: delta / max

      h = calculate_h(r, g, b, delta)
      {h, s * 100.0, v * 100.0}
    end

    @doc """
    Convierte RGB a CMYK.
    """
    @spec to_cmyk(rgb()) :: cmyk()
    def to_cmyk({r, g, b}) do
      r = r / 255.0
      g = g / 255.0
      b = b / 255.0

      k = 1.0 - Enum.max([r, g, b])

      if k == 1.0 do
        {0.0, 0.0, 0.0, 100.0}
      else
        c = (1.0 - r - k) / (1.0 - k)
        m = (1.0 - g - k) / (1.0 - k)
        y = (1.0 - b - k) / (1.0 - k)

        {c * 100.0, m * 100.0, y * 100.0, k * 100.0}
      end
    end

    @doc """
    Convierte RGB a XTerm256.
    """
    @spec to_xterm256(rgb()) :: xterm256()
    def to_xterm256({r, g, b}) do
      r = r / 255.0
      g = g / 255.0
      b = b / 255.0

      if r == g and g == b do
        cond do
          r < 0.031 -> 16
          r > 0.973 -> 231
          true -> round((r - 0.031) / 0.942 * 23.0) + 232
        end
      else
        r_idx = round(r * 5.0)
        g_idx = round(g * 5.0)
        b_idx = round(b * 5.0)

        16 + r_idx * 36 + g_idx * 6 + b_idx
      end
    end

    @doc """
    Blends dos colores RGB con un factor dado.
    """
    @spec blend(rgb(), rgb(), float()) :: rgb()
    def blend({r1, g1, b1}, {r2, g2, b2}, factor) do
      r = round(r1 + (r2 - r1) * factor)
      g = round(g1 + (g2 - g1) * factor)
      b = round(b1 + (b2 - b1) * factor)

      {r, g, b}
    end

    @doc """
    Calcula la distancia Manhattan entre dos colores RGB.
    """
    @spec color_distance(rgb(), rgb()) :: non_neg_integer()
    def color_distance({r1, g1, b1}, {r2, g2, b2}) do
      abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
    end

    @doc """
    Clamps un valor al rango 0-255.
    """
    @spec clamp(integer()) :: 0..255
    def clamp(value), do: min(max(value, 0), 255)
  end

  defmodule HSL do
    @moduledoc """
    Conversiones hacia/desde HSL.
    """

    alias Pote.Converters.HSV

    @type rgb :: Pote.rgb()
    @type hsl :: Pote.hsl()

    @doc """
    Convierte HSL a RGB.
    """
    @spec to_rgb(hsl()) :: rgb()
    def to_rgb({h, s, l}) do
      h = h / 360.0
      s = s / 100.0
      l = l / 100.0

      if s == 0 do
        v = round(l * 255)
        {v, v, v}
      else
        q =
          if l < 0.5 do
            l * (1 + s)
          else
            l + s - l * s
          end

        p = 2 * l - q

        r = hue_to_rgb(p, q, h + 1.0 / 3.0)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1.0 / 3.0)

        {round(r * 255), round(g * 255), round(b * 255)}
      end
    end

    defp hue_to_rgb(p, q, t) do
      t =
        cond do
          t < 0 -> t + 1
          t > 1 -> t - 1
          true -> t
        end

      cond do
        t < 1 / 6 -> p + (q - p) * 6 * t
        t < 1 / 2 -> q
        t < 2 / 3 -> p + (q - p) * (2 / 3 - t) * 6
        true -> p
      end
    end

    @doc """
    Crea HSL desde RGB.
    """
    @spec from_rgb(rgb()) :: hsl()
    def from_rgb(rgb), do: RGB.to_hsl(rgb)
  end

  defmodule HSV do
    @moduledoc """
    Conversiones hacia/desde HSV.
    """

    alias Pote.Converters.HSL

    @type rgb :: Pote.rgb()
    @type hsv :: Pote.hsv()

    @doc """
    Convierte HSV a RGB.
    """
    @spec to_rgb(hsv()) :: rgb()
    def to_rgb({h, s, v}) do
      h = h / 60.0
      s = s / 100.0
      v = v / 100.0

      i = Integer.mod(floor(h), 6)
      f = h - floor(h)
      p = v * (1 - s)
      q = v * (1 - f * s)
      t = v * (1 - (1 - f) * s)

      {r, g, b} =
        case i do
          0 -> {v, t, p}
          1 -> {q, v, p}
          2 -> {p, v, t}
          3 -> {p, q, v}
          4 -> {t, p, v}
          5 -> {v, p, q}
        end

      {round(r * 255), round(g * 255), round(b * 255)}
    end

    @doc """
    Crea HSV desde RGB.
    """
    @spec from_rgb(rgb()) :: hsv()
    def from_rgb(rgb), do: RGB.to_hsv(rgb)
  end

  defmodule CMYK do
    @moduledoc """
    Conversiones hacia/desde CMYK.
    """

    @type rgb :: Pote.rgb()
    @type cmyk :: Pote.cmyk()

    @doc """
    Convierte CMYK a RGB.
    """
    @spec to_rgb(cmyk()) :: rgb()
    def to_rgb({c, m, y, k}) do
      c = c / 100.0
      m = m / 100.0
      y = y / 100.0
      k = k / 100.0

      r = (255.0 * (1.0 - c) * (1.0 - k)) |> round()
      g = (255.0 * (1.0 - m) * (1.0 - k)) |> round()
      b = (255.0 * (1.0 - y) * (1.0 - k)) |> round()

      {r, g, b}
    end

    @doc """
    Crea CMYK desde RGB.
    """
    @spec from_rgb(rgb()) :: cmyk()
    def from_rgb(rgb), do: RGB.to_cmyk(rgb)
  end

  defmodule XTerm256 do
    @moduledoc """
    Conversiones hacia/desde XTerm256.
    """

    @type rgb :: Pote.rgb()
    @type xterm256 :: Pote.xterm256()

    @doc """
    Convierte XTerm256 a RGB.
    """
    @spec to_rgb(xterm256()) :: rgb()
    def to_rgb(index) when index in 232..255 do
      gray = (index - 232) * 10 + 8
      {gray, gray, gray}
    end

    def to_rgb(index) when index in 16..231 do
      index = index - 16
      r = div(index, 36) * 51
      g = div(rem(index, 36), 6) * 51
      b = rem(index, 6) * 51
      {r, g, b}
    end

    def to_rgb(index) when index in 0..15 do
      colors = [
        {0, 0, 0},
        {128, 0, 0},
        {0, 128, 0},
        {128, 128, 0},
        {0, 0, 128},
        {128, 0, 128},
        {0, 128, 128},
        {128, 128, 128},
        {192, 192, 192},
        {255, 0, 0},
        {0, 255, 0},
        {255, 255, 0},
        {0, 0, 255},
        {255, 0, 255},
        {0, 255, 255},
        {255, 255, 255}
      ]

      Enum.at(colors, index, {0, 0, 0})
    end

    def to_rgb(_index), do: {0, 0, 0}

    @doc """
    Crea XTerm256 desde RGB.
    """
    @spec from_rgb(rgb()) :: xterm256()
    def from_rgb(rgb), do: RGB.to_xterm256(rgb)
  end

  defmodule HWB do
    @moduledoc """
    Conversiones hacia/desde HWB (Hue, Whiteness, Blackness).
    """

    alias Pote.Converters.HSV

    @type rgb :: Pote.rgb()
    @type hwb :: {float(), float(), float()}

    @doc """
    Convierte HWB a RGB.
    """
    @spec to_rgb(hwb()) :: rgb()
    def to_rgb({h, w, b}) do
      w = w / 1.0
      b = b / 1.0

      if w + b >= 1.0 do
        gray = round(w / (w + b) * 255)
        {gray, gray, gray}
      else
        {r, g, b_val} = HSV.to_rgb({h, 100.0, 100.0})
        r = r / 255.0
        g = g / 255.0
        b_val = b_val / 255.0

        factor = 1.0 - w - b

        r = r * factor + w
        g = g * factor + w
        b_val = b_val * factor + w

        {round(r * 255), round(g * 255), round(b_val * 255)}
      end
    end

    @doc """
    Convierte RGB a HWB.
    """
    @spec from_rgb(rgb()) :: hwb()
    def from_rgb({r, g, b}) do
      r_norm = r / 255.0
      g_norm = g / 255.0
      b_norm = b / 255.0

      max_val = max(r_norm, max(g_norm, b_norm))
      min_val = min(r_norm, min(g_norm, b_norm))
      diff = max_val - min_val

      h = hwb_hue(r_norm, g_norm, b_norm, max_val, diff) |> normalize_hue()

      w = min_val
      v = max_val
      b_val = 1.0 - v

      {h, w, b_val}
    end

    defp hwb_hue(_rn, _gn, _bn, _max, +0.0), do: 0.0

    defp hwb_hue(rn, gn, bn, _max, diff) when diff > 0.0 do
      max_val = max(rn, max(gn, bn))

      cond do
        max_val == rn ->
          ratio = (gn - bn) / diff
          h_raw = 60.0 * ratio
          h_raw = if h_raw < 0, do: h_raw + 360.0, else: h_raw
          h_raw - trunc(h_raw / 360.0) * 360.0

        max_val == gn ->
          h_temp = 60.0 * ((bn - rn) / diff + 2)
          if h_temp < 0, do: h_temp + 360.0, else: h_temp

        true ->
          h_temp = 60.0 * ((rn - gn) / diff + 4)
          if h_temp < 0, do: h_temp + 360.0, else: h_temp
      end
    end

    defp hwb_hue(_rn, _gn, _bn, _max, _diff), do: 0.0

    defp normalize_hue(h) when h < 0, do: h + 360.0
    defp normalize_hue(h) when h >= 360.0, do: h - 360.0
    defp normalize_hue(h), do: h
  end

  # ============================================================================
  # Funciones de backward compatibility que delegan a Pote.Conversions
  # ============================================================================

  # Por ahora, las funciones antiguas siguen disponibles en Pote.Conversions
  # En el futuro podrían deprecarse en favor de estas

  @doc """
  Convierte HSL a RGB (alias de `HSL.to_rgb/1`).
  """
  def hsl_to_rgb(hsl), do: HSL.to_rgb(hsl)

  @doc """
  Convierte RGB a HSL (alias de `RGB.to_hsl/1`).
  """
  def rgb_to_hsl(rgb), do: RGB.to_hsl(rgb)

  @doc """
  Convierte HSV a RGB (alias de `HSV.to_rgb/1`).
  """
  def hsv_to_rgb(hsv), do: HSV.to_rgb(hsv)

  @doc """
  Convierte RGB a HSV (alias de `RGB.to_hsv/1`).
  """
  def rgb_to_hsv(rgb), do: RGB.to_hsv(rgb)

  @doc """
  Convierte CMYK a RGB (alias de `CMYK.to_rgb/1`).
  """
  def cmyk_to_rgb(cmyk), do: CMYK.to_rgb(cmyk)

  @doc """
  Convierte RGB a CMYK (alias de `RGB.to_cmyk/1`).
  """
  def rgb_to_cmyk(rgb), do: RGB.to_cmyk(rgb)

  @doc """
  Convierte XTerm256 a RGB (alias de `XTerm256.to_rgb/1`).
  """
  def xterm256_to_rgb(index), do: XTerm256.to_rgb(index)

  @doc """
  Convierte RGB a XTerm256 (alias de `RGB.to_xterm256/1`).
  """
  def rgb_to_xterm256(rgb), do: RGB.to_xterm256(rgb)

  @doc """
  Convierte HWB a RGB (alias de `HWB.to_rgb/1`).
  """
  def hwb_to_rgb(hwb), do: HWB.to_rgb(hwb)

  @doc """
  Convierte RGB a HWB (alias de `HWB.from_rgb/1`).
  """
  def rgb_to_hwb(rgb), do: HWB.from_rgb(rgb)

  @doc """
  Convierte RGB a hexadecimal (alias de `RGB.to_hex/1`).
  """
  def rgb_to_hex(rgb), do: RGB.to_hex(rgb)

  @doc """
  Convierte hexadecimal a RGB (alias de `RGB.from_hex/1`).
  """
  def hex_to_rgb(hex), do: RGB.from_hex(hex)
end
