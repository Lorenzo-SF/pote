defmodule Pote.Converters.XTerm256 do
  @moduledoc """
  Conversions to/from XTerm256.
  """
  alias Pote.Converters.RGB

  @type rgb :: Pote.rgb()
  @type xterm256 :: Pote.xterm256()

  @doc """
  Converts XTerm256 to RGB.
  """
  @spec to_rgb(xterm256()) :: rgb()
  # gray formula verified against spec: produces 8, 18, ..., 238 (24 levels)
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
  Creates XTerm256 from RGB.
  """
  @spec from_rgb(rgb()) :: xterm256()
  def from_rgb(rgb), do: RGB.to_xterm256(rgb)
end
