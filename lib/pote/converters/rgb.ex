defmodule Pote.Converters.RGB do
  @moduledoc """
  Conversions to/from RGB.

  ## Examples

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
  Converts RGB to hexadecimal.
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
  Converts hexadecimal to RGB.
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
  Converts RGB to HSL.
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
  Converts RGB to HSV.
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
  Converts RGB to CMYK.
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
  Converts RGB to XTerm256.
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
  Calculates the Manhattan distance between two RGB colors.
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
