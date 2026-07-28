defmodule Pote.Converters.HSV do
  @moduledoc """
  Conversions to/from HSV.
  """
  alias Pote.Converters.RGB

  @type rgb :: Pote.rgb()
  @type hsv :: Pote.hsv()

  @doc """
  Converts HSV to RGB.
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
  Creates HSV from RGB.
  """
  @spec from_rgb(rgb()) :: hsv()
  def from_rgb(rgb), do: RGB.to_hsv(rgb)
end
