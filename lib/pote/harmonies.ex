defmodule Pote.Harmonies do
  @moduledoc """
  Color harmony generation based on color theory principles.

  All functions take an RGB tuple and return lists of RGB tuples.
  Operations are purely mathematical — no I/O, no state.

  ## Supported Harmonies

  - **Complementary**: Color opposite on the wheel (180°)
  - **Analogous**: Adjacent colors (±30°)
  - **Triad**: Three colors equidistant at 120°
  - **Square**: Four colors at 90° intervals
  - **Monochromatic**: Lightness variations of the same hue
  - **Split Complementary**: Complement ± flanking colors
  - **Compound**: Complement plus analogous neighbors

  Type aliases defined here reference the canonical types in `Pote`.

  ## Usage

      iex> Pote.Harmonies.complementary({255, 87, 51})
      [{51, 219, 255}]

      iex> Pote.Harmonies.triad({255, 87, 51})
      [{51, 255, 87}, {87, 51, 255}]
  """

  alias Pote
  alias Pote.Conversions

  @type rgb :: Pote.rgb()

  @doc """
  Returns the complementary color (opposite on the hue wheel, +180°).

  ## Examples

      iex> complementary({255, 0, 0})
      [{0, 255, 255}]
  """
  @spec complementary(rgb()) :: [rgb()]
  def complementary(rgb) do
    [rotate_hue(rgb, 180)]
  end

  @doc """
  Returns analogous colors (±30° adjacent on the wheel).

  Returns 2 colors: one at -30° and one at +30°.

  ## Examples

      iex> analogous({255, 0, 0})
      [{255, 128, 0}, {255, 0, 128}]
  """
  @spec analogous(rgb()) :: [rgb()]
  def analogous(rgb) do
    [rotate_hue(rgb, -30), rotate_hue(rgb, 30)]
  end

  @doc """
  Returns the analogous colors with custom angle.

  ## Parameters

  - `rgb` - RGB color tuple
  - `angle` - Angle in degrees (default: 30)

  ## Returns

  - List of 2 RGB color tuples
  """
  @spec analogous(rgb(), float()) :: [rgb()]
  def analogous(rgb, angle) do
    [rotate_hue(rgb, -angle), rotate_hue(rgb, angle)]
  end

  @doc """
  Returns the triad colors (three colors equally spaced at 120°).

  Returns 2 additional colors (the original is implied as the third).

  ## Examples

      iex> triad({255, 0, 0}) |> length()
      2
  """
  @spec triad(rgb()) :: [rgb()]
  def triad(rgb) do
    [rotate_hue(rgb, 120), rotate_hue(rgb, 240)]
  end

  @doc """
  Returns square harmony colors (four colors equally spaced at 90°).

  Returns 3 additional colors (the original is implied as the first).

  ## Examples

      iex> square({255, 0, 0}) |> length()
      3
  """
  @spec square(rgb()) :: [rgb()]
  def square(rgb) do
    [rotate_hue(rgb, 90), rotate_hue(rgb, 180), rotate_hue(rgb, 270)]
  end

  @doc """
  Returns monochromatic variations (same hue, different lightness).

  Generates `steps` variations evenly distributed in lightness from 20% to 80%.

  ## Parameters

  - `rgb` - Source color
  - `steps` - Number of variations to generate (default: 5)

  ## Examples

      iex> monochromatic({255, 0, 0}, 3) |> length()
      3
  """
  @spec monochromatic(rgb(), pos_integer()) :: [rgb()]
  def monochromatic(rgb, steps \\ 5) do
    {h, s, _l} = Conversions.rgb_to_hsl(rgb)

    step_size = 60.0 / (steps - 1)

    Enum.map(0..(steps - 1), fn i ->
      lightness = 20.0 + i * step_size
      Conversions.hsl_to_rgb({h, s, lightness})
    end)
  end

  @doc """
  Returns split complementary colors.

  Takes the complement (180°) then flanks it with ±30°.
  Returns 2 colors: complement-30° and complement+30°.

  ## Examples

      iex> split_complementary({255, 0, 0}) |> length()
      2
  """
  @spec split_complementary(rgb()) :: [rgb()]
  def split_complementary(rgb) do
    [rotate_hue(rgb, 150), rotate_hue(rgb, 210)]
  end

  @doc """
  Returns compound (double complementary) harmony colors.

  Combines complementary and analogous: produces 4 colors forming
  two complementary pairs offset by 30°.

  ## Examples

      iex> compound({255, 0, 0}) |> length()
      4
  """
  @spec compound(rgb()) :: [rgb()]
  def compound(rgb) do
    [
      rotate_hue(rgb, 30),
      rotate_hue(rgb, 180),
      rotate_hue(rgb, 210)
    ] ++
      [rotate_hue(rgb, -30)]
  end

  @doc """
  Lightens a color by mixing it with white.

  ## Parameters

  - `rgb` - Source color
  - `amount` - Amount to lighten (0.0–1.0, default: 0.2)

  ## Examples

      iex> lighter({100, 100, 100}, 0.5)
      {178, 178, 178}
  """
  @spec lighter(rgb(), float()) :: rgb()
  def lighter({r, g, b}, amount \\ 0.2) when amount >= 0.0 and amount <= 1.0 do
    mix({r, g, b}, {255, 255, 255}, amount)
  end

  @doc """
  Darkens a color by mixing it with black.

  ## Parameters

  - `rgb` - Source color
  - `amount` - Amount to darken (0.0–1.0, default: 0.2)

  ## Examples

      iex> darker({200, 200, 200}, 0.5)
      {100, 100, 100}
  """
  @spec darker(rgb(), float()) :: rgb()
  def darker({r, g, b}, amount \\ 0.2) when amount >= 0.0 and amount <= 1.0 do
    mix({r, g, b}, {0, 0, 0}, amount)
  end

  @spec rotate_hue(rgb(), number()) :: rgb()
  defp rotate_hue(rgb, degrees) do
    {h, s, l} = Conversions.rgb_to_hsl(rgb)
    new_h = :math.fmod(h + degrees + 360, 360)
    Conversions.hsl_to_rgb({new_h, s, l})
  end

  @spec mix(rgb(), rgb(), float()) :: rgb()
  defp mix({r1, g1, b1}, {r2, g2, b2}, amount) do
    r = round(r1 + (r2 - r1) * amount)
    g = round(g1 + (g2 - g1) * amount)
    b = round(b1 + (b2 - b1) * amount)

    {Conversions.clamp(r), Conversions.clamp(g), Conversions.clamp(b)}
  end
end
