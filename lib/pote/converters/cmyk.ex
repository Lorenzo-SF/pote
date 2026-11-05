defmodule Pote.Converters.CMYK do
  @moduledoc """
  Conversions to/from CMYK.
  """
  alias Pote.Converters.RGB

  @type rgb :: Pote.rgb()
  @type cmyk :: Pote.cmyk()

  @doc """
  Converts CMYK to RGB.
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
  Creates CMYK from RGB.
  """
  @spec from_rgb(rgb()) :: cmyk()
  def from_rgb(rgb), do: RGB.to_cmyk(rgb)
end
