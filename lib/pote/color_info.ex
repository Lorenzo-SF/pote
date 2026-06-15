defmodule Pote.ColorInfo do
  @moduledoc """
  Structured representation of a color in all supported formats.

  `Pote.ColorInfo` holds a color's values across multiple color spaces
  (RGB, HEX, HSL, HSV, CMYK, XTerm256, ARGB) and provides convenient
  methods for harmonies, lightness adjustments, and ANSI output.

  Create a `ColorInfo` from any valid color input using `new/1`.

  ## Examples

      iex> ci = Pote.ColorInfo.new("#FF8000")
      iex> ci.rgb
      {255, 128, 0}
      iex> ci.hex
      "#FF8000"
  """

  alias Pote.Colors.Basic
  alias Pote.{Conversions, Harmonies, Orchestrator}

  @type rgb :: {0..255, 0..255, 0..255}
  @type argb :: {0..255, 0..255, 0..255, 0..255}
  @type hsl :: {number(), number(), number()}
  @type hsv :: {number(), number(), number()}
  @type cmyk :: {number(), number(), number(), number()}

  @type t :: %__MODULE__{
          rgb: rgb() | nil,
          hex: String.t() | nil,
          format: atom() | nil,
          argb: argb() | nil,
          hsl: hsl() | nil,
          hsv: hsv() | nil,
          cmyk: cmyk() | nil,
          xterm256: 0..255 | nil,
          name: atom() | nil,
          inverted: boolean(),
          display: any() | nil
        }

  defstruct rgb: nil,
            hex: nil,
            format: nil,
            argb: nil,
            hsl: nil,
            hsv: nil,
            cmyk: nil,
            xterm256: nil,
            name: nil,
            inverted: false,
            display: nil

  @doc "Creates a new empty ColorInfo structure."
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc "Creates a new ColorInfo from various inputs."
  @spec new(any(), keyword()) :: t()
  def new(color, opts \\ [])

  def new(%__MODULE__{} = color_info, opts) do
    inverted = Keyword.get(opts, :inverted, color_info.inverted)
    %{color_info | inverted: inverted}
  end

  def new(color, opts) do
    ci = Orchestrator.to_color_info(color)
    inverted = Keyword.get(opts, :inverted, false)
    %{ci | inverted: inverted}
  end

  @doc "Returns the map of basic ANSI colors."
  @spec basic_colors() :: %{atom() => {0..255, 0..255, 0..255}}
  def basic_colors, do: Basic.basic_colors()

  @doc """
  Finds the nearest basic ANSI color name for a given RGB value.

  ## Examples

      iex> Pote.ColorInfo.nearest_basic_color({255, 0, 0})
      :red

      iex> Pote.ColorInfo.nearest_basic_color({250, 10, 5})
      :red
  """
  @spec nearest_basic_color(rgb()) :: atom()
  def nearest_basic_color(rgb) do
    {name, _rgb} =
      Basic.basic_colors()
      |> Enum.min_by(fn {_name, color_rgb} ->
        Conversions.color_distance(rgb, color_rgb)
      end)

    name
  end

  @doc "Converts ColorInfo to ANSI escape code."
  @spec to_ansi(t()) :: String.t()
  def to_ansi(%__MODULE__{rgb: nil, xterm256: nil}), do: ""

  def to_ansi(%__MODULE__{rgb: {r, g, b}, inverted: inverted, name: name}) do
    code = if inverted, do: "48", else: "38"

    if basic_rgb = get_ansi_code(name, {r, g, b}) do
      base = if inverted, do: basic_rgb + 10, else: basic_rgb
      "\e[#{base}m"
    else
      "\e[#{code};2;#{r};#{g};#{b}m"
    end
  end

  def to_ansi(%__MODULE__{xterm256: xterm, inverted: inverted}) when is_integer(xterm) do
    code = if inverted, do: "48", else: "38"
    "\e[#{code};5;#{xterm}m"
  end

  def to_ansi(_), do: ""

  defp get_ansi_code(name, rgb) when is_atom(name) do
    if Basic.ansi_code(name) && Basic.basic_colors()[name] == rgb do
      Basic.ansi_code(name)
    end
  end

  defp get_ansi_code(_name, _rgb), do: nil

  @doc "Returns a lighter variant of the color blended with white."
  @spec lighter(t(), number()) :: t()
  def lighter(ci, factor) do
    rgb = ci.rgb || {0, 0, 0}
    blended = Conversions.blend(rgb, {255, 255, 255}, factor)
    Orchestrator.to_color_info(blended)
  end

  @doc "Returns a darker variant of the color blended with black."
  @spec darker(t(), number()) :: t()
  def darker(ci, factor) do
    rgb = ci.rgb || {255, 255, 255}
    blended = Conversions.blend(rgb, {0, 0, 0}, factor)
    Orchestrator.to_color_info(blended)
  end

  @doc "Returns the complementary color (180 opposite on the wheel)."
  @spec complementary(t()) :: t()
  def complementary(%__MODULE__{} = ci) do
    [{r, g, b} | _] = Harmonies.complementary(ci.rgb)
    %__MODULE__{ci | rgb: {r, g, b}}
  end

  @doc "Returns two analogous colors (offset by angle degrees)."
  @spec analogous(t(), number()) :: [t()]
  def analogous(%__MODULE__{} = ci, angle \\ 30.0) do
    rgb_tuples = Harmonies.analogous(ci.rgb, angle)
    Enum.map(rgb_tuples, fn {r, g, b} -> %__MODULE__{ci | rgb: {r, g, b}} end)
  end

  @doc "Returns the triad harmony (base + 120 + 240)."
  @spec triad(t()) :: [t()]
  def triad(%__MODULE__{} = ci) do
    rgb_tuples = Harmonies.triad(ci.rgb)
    Enum.map(rgb_tuples, fn {r, g, b} -> %__MODULE__{ci | rgb: {r, g, b}} end)
  end
end
