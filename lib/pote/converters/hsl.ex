defmodule Pote.Converters.HSL do
  @moduledoc """
  Conversions to/from HSL.
  """

  alias Pote.Converters.RGB

  @type rgb :: Pote.rgb()
  @type hsl :: Pote.hsl()

  @doc """
  Converts HSL to RGB.
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
  Creates HSL from RGB.
  """
  @spec from_rgb(rgb()) :: hsl()
  def from_rgb(rgb) do
    RGB.to_hsl(rgb)
  end
end
