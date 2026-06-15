defmodule Pote.Conversions do
  @moduledoc """
  Color conversion functions between various color formats.

  ## Supported Formats

  * RGB - Red, Green, Blue (0-255)
  * Hex - Hexadecimal color codes (#RRGGBB)
  * HSL - Hue, Saturation, Lightness (H: 0-360°, S: 0-100%, L: 0-100%)
  * HSV - Hue, Saturation, Value (H: 0-360°, S: 0-100%, V: 0-100%)
  * CMYK - Cyan, Magenta, Yellow, Key (C: 0-100%, M: 0-100%, Y: 0-100%, K: 0-100%)
  * XTerm256 - 256-color terminal palette index

  ## Usage

      iex> Pote.Conversions.rgb_to_hex({255, 128, 0})
      "#FF8000"

      iex> Pote.Conversions.hex_to_rgb("#FF8000")
      {:ok, {255, 128, 0}}

  ## Contracts

  Type aliases defined here reference the canonical types in `Pote`.
  """
  alias Pote

  @type rgb :: Pote.rgb()
  @type hsl :: Pote.hsl()
  @type hsv :: Pote.hsv()
  @type cmyk :: Pote.cmyk()
  @type hex :: Pote.hex()
  @type xterm256 :: Pote.xterm256()

  @doc """
  Converts RGB color to hexadecimal string.

  ## Parameters

  - `rgb` - RGB tuple {r, g, b} where each value is 0-255

  ## Returns

  - Hex string in format "#RRGGBB"

  ## Examples

      iex> rgb_to_hex({255, 128, 0})
      "#FF8000"

      iex> rgb_to_hex({0, 0, 0})
      "#000000"
  """
  @spec rgb_to_hex(rgb()) :: hex()
  def rgb_to_hex({r, g, b}) do
    "##{hex_component(r)}#{hex_component(g)}#{hex_component(b)}" |> String.upcase()
  end

  defp hex_component(n), do: n |> Integer.to_string(16) |> String.pad_leading(2, "0")

  @doc """
  Converts hexadecimal string to RGB tuple.

  ## Parameters

  - `hex` - Hex string in format "#RRGGBB" or "RRGGBB"

  ## Returns

  - `{:ok, rgb}` - RGB tuple on success
  - `{:error, reason}` - Error tuple if conversion fails

  ## Examples

      iex> hex_to_rgb("#FF8000")
      {:ok, {255, 128, 0}}

      iex> hex_to_rgb("FF8000")
      {:ok, {255, 128, 0}}

      iex> hex_to_rgb("invalid")
      {:error, :invalid_hex_format}
  """
  @spec hex_to_rgb(hex()) :: {:ok, rgb()} | {:error, :invalid_hex_format}
  def hex_to_rgb(hex) when is_binary(hex) do
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
  Converts RGB to HSL (Hue, Saturation, Lightness).

  ## Parameters

  - `rgb` - RGB tuple {r, g, b} where each value is 0-255

  ## Returns

  - HSL tuple {h, s, l} where h is 0-360, s and l are 0-100

  ## Examples

      iex> rgb_to_hsl({255, 128, 0})
      {30.0, 100.0, 50.0}
  """
  @spec rgb_to_hsl(rgb()) :: hsl()
  def rgb_to_hsl({r, g, b}) do
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
      s = if l < 0.5, do: delta / (max + min), else: delta / (2 - max - min)
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
  Converts HSL to RGB.

  ## Parameters

  - `hsl` - HSL tuple {h, s, l} where h is 0-360, s and l are 0-100

  ## Returns

  - RGB tuple {r, g, b} where each value is 0-255

  ## Examples

      iex> hsl_to_rgb({30.0, 100.0, 50.0})
      {255, 128, 0}
  """
  @spec hsl_to_rgb(hsl()) :: rgb()
  def hsl_to_rgb({h, s, l}) do
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
      if t < 0 do
        t + 1
      else
        if t > 1 do
          t - 1
        else
          t
        end
      end

    cond do
      t < 1 / 6 -> p + (q - p) * 6 * t
      t < 1 / 2 -> q
      t < 2 / 3 -> p + (q - p) * (2 / 3 - t) * 6
      true -> p
    end
  end

  @doc """
  Converts RGB to HSV (Hue, Saturation, Value).

  ## Parameters

  - `rgb` - RGB tuple {r, g, b} where each value is 0-255

  ## Returns

  - HSV tuple {h, s, v} where h is 0-360, s and v are 0-100

  ## Examples

      iex> rgb_to_hsv({255, 128, 0})
      {30.0, 100.0, 100.0}
  """
  @spec rgb_to_hsv(rgb()) :: hsv()
  def rgb_to_hsv({r, g, b}) do
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
  Converts HSV to RGB.

  ## Parameters

  - `hsv` - HSV tuple {h, s, v} where h is 0-360, s and v are 0-100

  ## Returns

  - RGB tuple {r, g, b} where each value is 0-255

  ## Examples

      iex> hsv_to_rgb({30.0, 100.0, 100.0})
      {255, 128, 0}
  """
  @spec hsv_to_rgb(hsv()) :: rgb()
  def hsv_to_rgb({h, s, v}) do
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
  Converts RGB to CMYK.

  ## Parameters

  - `rgb` - RGB tuple {r, g, b} where each value is 0-255

  ## Returns

  - CMYK tuple {c, m, y, k} where each value is 0-100

  ## Examples

      iex> rgb_to_cmyk({255, 128, 0})
      {0.0, 49.8, 100.0, 0.0}
  """
  @spec rgb_to_cmyk(rgb()) :: cmyk()
  def rgb_to_cmyk({r, g, b}) do
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
  Converts CMYK to RGB.

  ## Parameters

  - `cmyk` - CMYK tuple {c, m, y, k} where each value is 0-100

  ## Returns

  - RGB tuple {r, g, b} where each value is 0-255

  ## Examples

      iex> cmyk_to_rgb({0.0, 49.8, 100.0, 0.0})
      {255, 128, 0}
  """
  @spec cmyk_to_rgb(cmyk()) :: rgb()
  def cmyk_to_rgb({c, m, y, k}) do
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
  Converts RGB to XTerm256 color index.

  Uses the closest match in the 256-color terminal palette.

  ## Parameters

  - `rgb` - RGB tuple {r, g, b} where each value is 0-255

  ## Returns

  - XTerm256 index (0-255)

  ## Examples

      iex> rgb_to_xterm256({255, 128, 0})
      208
  """
  @spec rgb_to_xterm256(rgb()) :: xterm256()
  def rgb_to_xterm256({r, g, b}) do
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
  Converts XTerm256 color index to RGB tuple.
  """
  @spec xterm256_to_rgb(xterm256()) :: rgb()
  def xterm256_to_rgb(index) when index in 232..255 do
    gray = (index - 232) * 10 + 8
    {gray, gray, gray}
  end

  def xterm256_to_rgb(index) when index in 16..231 do
    index = index - 16
    r = div(index, 36) * 51
    g = div(rem(index, 36), 6) * 51
    b = rem(index, 6) * 51
    {r, g, b}
  end

  def xterm256_to_rgb(index) when index in 0..15 do
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

  def xterm256_to_rgb(_index) do
    {0, 0, 0}
  end

  @doc """
  Converts HWB to RGB.

  ## Parameters

  - `hwb` - HWB tuple {h, w, b} where h is 0-360, w and b are 0.0-1.0

  ## Returns

  - RGB tuple {r, g, b} where each value is 0-255

  ## Examples

      iex> hwb_to_rgb({0.0, 0.0, 0.0})
      {255, 0, 0}

      iex> hwb_to_rgb({0.0, 0.5, 0.5})
      {128, 64, 64}
  """
  @spec hwb_to_rgb({number(), number(), number()}) :: rgb()
  def hwb_to_rgb({h, w, b}) do
    w = w / 1.0
    b = b / 1.0

    if w + b >= 1.0 do
      gray = round(w / (w + b) * 255)
      {gray, gray, gray}
    else
      {r, g, b_val} = hsv_to_rgb({h, 100.0, 100.0})
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
  Converts RGB to HWB (Hue, Whiteness, Blackness).

  ## Parameters

  - `rgb` - RGB tuple {r, g, b} where each value is 0-255

  ## Returns

  - HWB tuple {h, w, b} where h is 0-360, w and b are 0.0-1.0

  ## Examples

      iex> rgb_to_hwb({255, 0, 0})
      {0.0, 1.0, 0.0}

      iex> rgb_to_hwb({128, 128, 128})
      {0.0, 0.502, 0.498}
  """
  @spec rgb_to_hwb(rgb()) :: {float(), float(), float()}
  def rgb_to_hwb({r, g, b}) do
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

  @doc """
  Blends two RGB colors with a given factor.

  ## Parameters

  - `color1` - First RGB color tuple
  - `color2` - Second RGB color tuple
  - `factor` - Blend factor (0.0 = color1, 1.0 = color2)

  ## Returns

  - Blended RGB color tuple

  ## Examples

      iex> blend({255, 0, 0}, {0, 0, 255}, 0.5)
      {128, 0, 128}
  """
  @spec blend({integer(), integer(), integer()}, {integer(), integer(), integer()}, float()) ::
          {integer(), integer(), integer()}
  def blend({r1, g1, b1}, {r2, g2, b2}, factor) do
    r = round(r1 + (r2 - r1) * factor)
    g = round(g1 + (g2 - g1) * factor)
    b = round(b1 + (b2 - b1) * factor)
    {r, g, b}
  end

  # ---------------------------------------------------------------------------
  # Advanced color spaces & accessibility
  # ---------------------------------------------------------------------------

  @doc """
  Converts RGB to CIE XYZ using the sRGB D65 matrix.

  ## Parameters

  - `rgb` - RGB tuple {r, g, b} where each value is 0-255

  ## Returns

  - XYZ tuple {x, y, z}

  ## Examples

      iex> rgb_to_xyz({255, 128, 0})
      {0.487, 0.356, 0.041}
  """
  @spec rgb_to_xyz(rgb()) :: {float(), float(), float()}
  def rgb_to_xyz({r, g, b}) do
    [rn, gn, bn] =
      [r, g, b]
      |> Enum.map(fn v -> v / 255.0 end)
      |> Enum.map(fn v ->
        if v <= 0.04045 do
          v / 12.92
        else
          :math.pow((v + 0.055) / 1.055, 2.4)
        end
      end)

    x = rn * 0.4124564 + gn * 0.3575761 + bn * 0.1804375
    y = rn * 0.2126729 + gn * 0.7151522 + bn * 0.0721750
    z = rn * 0.0193339 + gn * 0.1191920 + bn * 0.9503041

    {Float.round(x, 3), Float.round(y, 3), Float.round(z, 3)}
  end

  @doc """
  Converts CIE XYZ to RGB (sRGB D65).

  ## Parameters

  - `xyz` - XYZ tuple {x, y, z}

  ## Returns

  - RGB tuple {r, g, b} where each value is 0-255
  """
  @spec xyz_to_rgb({float(), float(), float()}) :: rgb()
  def xyz_to_rgb({x, y, z}) do
    rn = x * 3.2404542 + y * -1.5371385 + z * -0.4985314
    gn = x * -0.9692660 + y * 1.8760108 + z * 0.0415560
    bn = x * 0.0556434 + y * -0.2040259 + z * 1.0572252

    [r, g, b] =
      [rn, gn, bn]
      |> Enum.map(fn v ->
        if v <= 0.0031308 do
          v * 12.92
        else
          :math.pow(v, 1.0 / 2.4) * 1.055 - 0.055
        end
      end)
      |> Enum.map(fn v -> round(v * 255) end)
      |> Enum.map(fn v -> min(max(v, 0), 255) end)

    {r, g, b}
  end

  @doc """
  Converts RGB to CIELAB (D65 illuminant).

  ## Parameters

  - `rgb` - RGB tuple {r, g, b} where each value is 0-255

  ## Returns

  - Lab tuple {l, a, b} where L is 0-100, a and b are roughly -128 to 127

  ## Examples

      iex> rgb_to_lab({255, 128, 0})
      {66.89, 37.14, 75.29}
  """
  @spec rgb_to_lab(rgb()) :: {float(), float(), float()}
  def rgb_to_lab(rgb) do
    {x, y, z} = rgb_to_xyz(rgb)

    xn = 95.047
    yn = 100.0
    zn = 108.883

    fx = lab_f(x * 100.0 / xn)
    fy = lab_f(y * 100.0 / yn)
    fz = lab_f(z * 100.0 / zn)

    l = 116.0 * fy - 16.0
    a = 500.0 * (fx - fy)
    b = 200.0 * (fy - fz)

    {Float.round(l, 2), Float.round(a, 2), Float.round(b, 2)}
  end

  defp lab_f(t) do
    delta = 6.0 / 29.0

    if t > :math.pow(delta, 3) do
      :math.pow(t, 1.0 / 3.0)
    else
      t / (3.0 * :math.pow(delta, 2)) + 4.0 / 29.0
    end
  end

  @doc """
  Converts CIELAB to RGB (sRGB D65).

  ## Parameters

  - `lab` - Lab tuple {l, a, b}

  ## Returns

  - RGB tuple {r, g, b} where each value is 0-255
  """
  @spec lab_to_rgb({float(), float(), float()}) :: rgb()
  def lab_to_rgb({l, a, b}) do
    delta = 6.0 / 29.0

    fy = (l + 16.0) / 116.0
    fx = a / 500.0 + fy
    fz = fy - b / 200.0

    x =
      if fx > delta do
        :math.pow(fx, 3)
      else
        3.0 * :math.pow(delta, 2) * (fx - 4.0 / 29.0)
      end

    y =
      if fy > delta do
        :math.pow(fy, 3)
      else
        3.0 * :math.pow(delta, 2) * (fy - 4.0 / 29.0)
      end

    z =
      if fz > delta do
        :math.pow(fz, 3)
      else
        3.0 * :math.pow(delta, 2) * (fz - 4.0 / 29.0)
      end

    xyz_to_rgb({x * 0.95047, y * 1.0, z * 1.08883})
  end

  @doc """
  Computes the Delta E 1976 distance between two colors.

  This is the Euclidean distance in CIELAB space.

  ## Parameters

  - `rgb1` - First RGB color tuple
  - `rgb2` - Second RGB color tuple

  ## Returns

  - Delta E value (float). Values < 1.0 are imperceptible.

  ## Examples

      iex> delta_e({255, 0, 0}, {255, 0, 0})
      0.0
  """
  @deprecated "Use Pote.Converters.Advanced.delta_e/2"
  defdelegate delta_e(rgb1, rgb2), to: Pote.Converters.Advanced

  @doc """
  Computes the WCAG 2.1 relative luminance of a color.

  ## Parameters

  - `rgb` - RGB tuple {r, g, b} where each value is 0-255

  ## Returns

  - Luminance value between 0.0 and 1.0

  ## Examples

      iex> relative_luminance({255, 255, 255})
      1.0
  """
  @spec relative_luminance(rgb()) :: float()
  def relative_luminance({r, g, b}) do
    [rn, gn, bn] =
      [r, g, b]
      |> Enum.map(fn v -> v / 255.0 end)
      |> Enum.map(fn v ->
        if v <= 0.03928 do
          v / 12.92
        else
          :math.pow((v + 0.055) / 1.055, 2.4)
        end
      end)

    (0.2126 * rn + 0.7152 * gn + 0.0722 * bn)
    |> Float.round(4)
  end

  @doc """
  Computes the WCAG 2.1 contrast ratio between two colors.

  ## Parameters

  - `rgb1` - First RGB color tuple
  - `rgb2` - Second RGB color tuple

  ## Returns

  - Contrast ratio (float). WCAG AA requires 4.5:1 for normal text, 7:1 for AAA.

  ## Examples

      iex> contrast_ratio({255, 255, 255}, {0, 0, 0})
      21.0
  """
  @spec contrast_ratio(rgb(), rgb()) :: float()
  def contrast_ratio(rgb1, rgb2) do
    l1 = relative_luminance(rgb1)
    l2 = relative_luminance(rgb2)

    lighter = max(l1, l2)
    darker = min(l1, l2)

    ((lighter + 0.05) / (darker + 0.05))
    |> Float.round(2)
  end

  # ---------------------------------------------------------------------------
  # Color temperature (Kelvin)
  # ---------------------------------------------------------------------------

  @doc """
  Approximates the correlated color temperature (CCT) in Kelvin from an RGB color.

  Uses an iterative search over the kelvin_to_rgb/1 function to find the
  closest matching temperature. Returns `nil` for colors that are not
  reasonably close to a black-body radiator.

  ## Examples

      iex> rgb_to_kelvin({255, 160, 60})
      3200
  """
  @spec rgb_to_kelvin(rgb()) :: pos_integer() | nil
  def rgb_to_kelvin(rgb) do
    search_kelvin(rgb, 1000, 40_000, 20)
  end

  defp search_kelvin(_rgb, low, high, _iterations) when low >= high do
    low
  end

  defp search_kelvin(_rgb, _low, _high, 0) do
    nil
  end

  defp search_kelvin(rgb, low, high, iterations) do
    mid = div(low + high, 2)
    mid_rgb = kelvin_to_rgb(mid)

    {h1, s1, l1} = rgb_to_hsl(rgb)
    {h2, s2, l2} = rgb_to_hsl(mid_rgb)

    # Compare primarily on hue, then saturation, then lightness
    cond do
      h1 < h2 -> search_kelvin(rgb, low, mid, iterations - 1)
      h1 > h2 -> search_kelvin(rgb, mid + 1, high, iterations - 1)
      s1 < s2 -> search_kelvin(rgb, low, mid, iterations - 1)
      s1 > s2 -> search_kelvin(rgb, mid + 1, high, iterations - 1)
      l1 < l2 -> search_kelvin(rgb, low, mid, iterations - 1)
      true -> search_kelvin(rgb, mid + 1, high, iterations - 1)
    end
  end

  @doc """
  Converts a color temperature in Kelvin to an RGB approximation.

  Based on Tanner Helland's algorithm for black-body radiation approximation.

  ## Parameters

  - `kelvin` - Temperature in Kelvin (1000-40000)

  ## Returns

  - RGB tuple {r, g, b}

  ## Examples

      iex> kelvin_to_rgb(6500)
      {255, 249, 253}
  """
  @spec kelvin_to_rgb(pos_integer()) :: rgb()
  def kelvin_to_rgb(kelvin) when kelvin < 1000, do: kelvin_to_rgb(1000)
  def kelvin_to_rgb(kelvin) when kelvin > 40_000, do: kelvin_to_rgb(40_000)

  def kelvin_to_rgb(kelvin) do
    k = kelvin / 100.0

    r = if k <= 66, do: 255, else: kelvin_red_component(k)

    g =
      if k <= 66,
        do: kelvin_green_low(k),
        else: kelvin_green_high(k)

    b =
      cond do
        k >= 66 -> 255
        k <= 19 -> 0
        true -> kelvin_blue_mid(k)
      end

    {r, g, b}
  end

  defp kelvin_red_component(k) do
    t = k - 60.0
    v = 329.698_727_446 * :math.pow(t, -0.133_204_759_2)
    clamp(round(v))
  end

  defp kelvin_green_low(k) do
    v = 99.470_802_586_1 * :math.log(k) - 161.119_568_166_1
    clamp(round(v))
  end

  defp kelvin_green_high(k) do
    t = k - 60.0
    v = 288.122_169_528_3 * :math.pow(t, -0.075_514_849_2)
    clamp(round(v))
  end

  defp kelvin_blue_mid(k) do
    t = k - 10.0
    v = 138.517_731_223_1 * :math.log(t) - 305.044_792_730_7
    clamp(round(v))
  end

  # ---------------------------------------------------------------------------
  # Broadcast / Video color spaces
  # ---------------------------------------------------------------------------

  @doc """
  Converts RGB to YUV (BT.601, PAL/NTSC broadcast).

  ## Parameters

  - `rgb` - RGB tuple {r, g, b} where each value is 0-255

  ## Returns

  - YUV tuple {y, u, v} where Y is 0-255, U and V are -128 to 127

  ## Examples

      iex> rgb_to_yuv({255, 128, 0})
      {165, 13, 146}
  """
  @spec rgb_to_yuv(rgb()) :: {integer(), integer(), integer()}
  def rgb_to_yuv({r, g, b}) do
    y = round(0.299 * r + 0.587 * g + 0.114 * b)
    u = round(-0.147 * r - 0.289 * g + 0.436 * b)
    v = round(0.615 * r - 0.515 * g - 0.100 * b)
    {clamp(y), clamp(u + 128) - 128, clamp(v + 128) - 128}
  end

  @doc """
  Converts YUV (BT.601) to RGB.

  ## Parameters

  - `yuv` - YUV tuple {y, u, v}

  ## Returns

  - RGB tuple {r, g, b}
  """
  @spec yuv_to_rgb({integer(), integer(), integer()}) :: rgb()
  def yuv_to_rgb({y, u, v}) do
    u = u + 128
    v = v + 128

    r = round(y + 1.140 * (v - 128))
    g = round(y - 0.395 * (u - 128) - 0.581 * (v - 128))
    b = round(y + 2.032 * (u - 128))

    {clamp(r), clamp(g), clamp(b)}
  end

  @doc """
  Converts RGB to YCbCr (BT.601, digital video).

  ## Parameters

  - `rgb` - RGB tuple {r, g, b} where each value is 0-255

  ## Returns

  - YCbCr tuple {y, cb, cr} where Y is 16-235, Cb/Cr are 16-240

  ## Examples

      iex> rgb_to_ycbcr({255, 128, 0})
      {165, 69, 224}
  """
  @spec rgb_to_ycbcr(rgb()) :: {integer(), integer(), integer()}
  def rgb_to_ycbcr({r, g, b}) do
    y = round(16 + 65.481 * r / 255 + 128.553 * g / 255 + 24.966 * b / 255)
    cb = round(128 - 37.797 * r / 255 - 74.203 * g / 255 + 112.0 * b / 255)
    cr = round(128 + 112.0 * r / 255 - 93.786 * g / 255 - 18.214 * b / 255)

    {min(max(y, 16), 235), min(max(cb, 16), 240), min(max(cr, 16), 240)}
  end

  @doc """
  Converts YCbCr (BT.601) to RGB.

  ## Parameters

  - `ycbcr` - YCbCr tuple {y, cb, cr}

  ## Returns

  - RGB tuple {r, g, b}
  """
  @spec ycbcr_to_rgb({integer(), integer(), integer()}) :: rgb()
  def ycbcr_to_rgb({y, cb, cr}) do
    r = round(255.0 / 219.0 * (y - 16) + 255.0 / 112.0 * 0.701 * (cr - 128))

    g =
      round(
        255.0 / 219.0 * (y - 16) - 255.0 / 112.0 * 0.886 * (cb - 128) / 1.772 -
          255.0 / 112.0 * 0.701 * (cr - 128) / 1.402
      )

    b = round(255.0 / 219.0 * (y - 16) + 255.0 / 112.0 * 0.886 * (cb - 128))

    {clamp(r), clamp(g), clamp(b)}
  end

  @doc """
  Finds the closest Pantone match for an RGB color.

  > #### Deprecated {: .warning}
  > Use `Pote.Converters.Advanced.nearest_pantone/1` instead.
  """
  @deprecated "Use Pote.Converters.Advanced.nearest_pantone/1"
  @spec rgb_to_pantone_approx(rgb()) :: {String.t(), float()} | nil
  defdelegate rgb_to_pantone_approx(rgb), to: Pote.Converters.Advanced, as: :nearest_pantone

  @doc """
  Clamps an integer value to the 0-255 range.

  ## Examples

      iex> Pote.Conversions.clamp(300)
      255

      iex> Pote.Conversions.clamp(-10)
      0

      iex> Pote.Conversions.clamp(128)
      128
  """
  @spec clamp(integer()) :: 0..255
  def clamp(value), do: min(max(value, 0), 255)

  @doc """
  Calculates Manhattan distance between two RGB colors.
  Used to find nearest color match.
  """
  @spec color_distance(rgb(), rgb()) :: non_neg_integer()
  def color_distance({r1, g1, b1}, {r2, g2, b2}) do
    abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
  end
end
