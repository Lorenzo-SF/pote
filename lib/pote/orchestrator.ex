defmodule Pote.Orchestrator do
  @moduledoc """
  Color orchestration module for parsing, converting, and formatting colors.

  This module provides a unified interface for working with various color
  formats, converting between them, and generating ANSI escape codes.

  Parsing logic is delegated to `Pote.Orchestrator.Parser`.

  ## Supported Color Formats

  * RGB tuples: `{r, g, b}` where each value is 0-255
  * Hex strings: `"#RRGGBB"` or `"RRGGBB"`
  * HSL tuples: `{h, s, l}` where h is 0-360°, s and l are 0-100%
  * HSV tuples: `{h, s, v}` where h is 0-360°, s and v are 0-100%
  * CMYK tuples: `{c, m, y, k}` where each value is 0-100%
  * XTerm256: Integer 0-255
  * Atom colors: `:red`, `:green`, `:blue`, etc.
  * Named colors: `"red"`, `"green"`, `"blue"`, etc.

  ## Usage

      iex> Pote.Orchestrator.parse_color("#FF8000")
      {:ok, {255, 128, 0}}

      iex> Pote.Orchestrator.to_ansi({255, 128, 0})
      "\\e[38;2;255;128;0m"
  """

  alias Pote.ColorInfo
  alias Pote.Converters
  alias Pote.Orchestrator.Parser

  @type rgb :: Pote.rgb()
  @type hex :: Pote.hex()
  @type hsl :: Pote.hsl()
  @type hsv :: Pote.hsv()
  @type cmyk :: Pote.cmyk()
  @type xterm256 :: Pote.xterm256()

  @type color_input :: Pote.color_input()
  @type color_output :: Pote.color_output()

  # ── Parsing ──────────────────────────────────────────────────────

  @doc """
  Parses a color from various input formats.

  Delegates to `Pote.Orchestrator.Parser.parse_color/1`.

  ## Parameters

  - `input` - Color in any supported format

  ## Returns

  - `{:ok, rgb}` - RGB tuple on success
  - `{:error, message}` - Error string with explanation
  """
  @spec parse_color(color_input()) ::
          {:ok, rgb()} | {:error, String.t()}
  def parse_color(input), do: Parser.parse_color(input)

  @doc """
  Converts any color format to RGB tuple.

  ## Parameters

  - `input` - Color in any supported format

  ## Returns

  - `{:ok, rgb}` - RGB tuple on success
  - `{:error, reason}` - Error tuple if conversion fails
  """
  @spec to_rgb(color_input()) :: {:ok, rgb()} | {:error, String.t()}
  def to_rgb(input), do: parse_color(input)

  @doc """
  Converts any color format to RGB tuple (raises on error).

  ## Parameters

  - `input` - Color in any supported format

  ## Returns

  - RGB tuple
  """
  @spec to_rgb!(color_input()) :: rgb()
  def to_rgb!(input) do
    case to_rgb(input) do
      {:ok, rgb} -> rgb
      {:error, reason} -> raise ArgumentError, "failed to convert color: #{inspect(reason)}"
    end
  end

  # ── ANSI formatting ──────────────────────────────────────────────

  @doc """
  Converts a color to its ANSI escape code for foreground.

  ## Parameters

  - `input` - Color in any supported format

  ## Returns

  - ANSI escape code string
  """
  @spec to_ansi(color_input() | nil) :: String.t()
  def to_ansi(nil), do: ""

  def to_ansi(input) do
    case to_rgb(input) do
      {:ok, {r, g, b}} -> "\e[38;2;#{r};#{g};#{b}m"
      {:error, _} -> ""
    end
  end

  @doc """
  Converts a color to its ANSI escape code for background.

  ## Parameters

  - `input` - Color in any supported format

  ## Returns

  - ANSI escape code string for background color
  """
  @spec to_ansi_bg(color_input() | nil) :: String.t()
  def to_ansi_bg(nil), do: ""

  def to_ansi_bg(input) do
    case to_rgb(input) do
      {:ok, {r, g, b}} -> "\e[48;2;#{r};#{g};#{b}m"
      {:error, _} -> ""
    end
  end

  # ── Conversions ──────────────────────────────────────────────────

  @doc """
  Converts a color to XTerm256 index.

  ## Parameters

  - `input` - Color in any supported format

  ## Returns

  - `{:ok, xterm256}` - XTerm256 index on success
  - `{:error, reason}` - Error tuple if conversion fails
  """
  @spec to_xterm256(color_input()) :: {:ok, xterm256()} | {:error, String.t()}
  def to_xterm256(input) do
    case to_rgb(input) do
      {:ok, rgb} -> {:ok, Converters.rgb_to_xterm256(rgb)}
      {:error, reason} -> {:error, reason}
    end
  end

  # ── Named colors ─────────────────────────────────────────────────

  @doc """
  Returns the list of supported named colors.
  """
  @spec named_colors() :: keyword()
  def named_colors do
    Parser.named_colors_map()
    |> Enum.map(fn {k, v} -> {k, v} end)
  end

  # ── Color info ───────────────────────────────────────────────────

  @doc """
  Converts a color value to a `Pote.ColorInfo` struct.
  """
  @spec to_color_info(atom() | String.t() | tuple()) :: ColorInfo.t()
  def to_color_info(color) when is_atom(color) do
    case parse_color(color) do
      {:ok, rgb} -> %ColorInfo{rgb: rgb, name: color}
      {:error, _} -> ColorInfo.new()
    end
  end

  def to_color_info(color) do
    case parse_color(color) do
      {:ok, rgb} -> %ColorInfo{rgb: rgb}
      {:error, _} -> ColorInfo.new()
    end
  end
end
