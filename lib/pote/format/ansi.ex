defmodule Pote.Format.ANSI do
  @moduledoc """
  ANSI format for basic terminal colours.

  **Deprecated**: Use `Pote.ColorInfo.nearest_basic_color/1` instead for finding
  the nearest basic color, and `Pote.ColorInfo.to_ansi/1` for ANSI escape codes.
  This module will be removed in a future version.
  """

  use Pote.Format

  alias Pote.Colors.Basic
  alias Pote.Converters

  @type parsed :: atom()

  @basic_colors %{
    black: {0, 0, 0},
    red: {255, 0, 0},
    green: {0, 255, 0},
    yellow: {255, 255, 0},
    blue: {0, 0, 255},
    magenta: {255, 0, 255},
    cyan: {0, 255, 255},
    white: {255, 255, 255},
    bright_black: {128, 128, 128},
    bright_red: {255, 128, 128},
    bright_green: {128, 255, 128},
    bright_yellow: {255, 255, 128},
    bright_blue: {128, 128, 255},
    bright_magenta: {255, 128, 255},
    bright_cyan: {128, 255, 255},
    bright_white: {255, 255, 255},
    # Extended colors (common aliases)
    orange: {255, 165, 0},
    purple: {128, 0, 128},
    pink: {255, 192, 203},
    violet: {238, 130, 238},
    indigo: {75, 0, 130},
    teal: {0, 128, 128},
    lime: {0, 255, 0},
    navy: {0, 0, 128},
    maroon: {128, 0, 0},
    olive: {128, 128, 0},
    aqua: {0, 255, 255},
    fuchsia: {255, 0, 255},
    silver: {192, 192, 192},
    gray: {128, 128, 128},
    grey: {128, 128, 128}
  }

  @impl true
  def parse(color) when is_atom(color) do
    if Map.has_key?(@basic_colors, color) do
      {:ok, color}
    else
      :error
    end
  end

  @impl true
  def parse(color) when is_binary(color), do: parse_binary_color(color)
  def parse(_), do: :error

  defp parse_binary_color(color) do
    atom_color = String.to_existing_atom(color)

    if Map.has_key?(@basic_colors, atom_color),
      do: {:ok, atom_color},
      else: :error
  rescue
    ArgumentError -> :error
  end

  @impl true
  def valid?(color) when is_atom(color), do: Map.has_key?(@basic_colors, color)
  def valid?(color) when is_binary(color), do: valid_binary_color?(color)
  def valid?(_), do: false

  defp valid_binary_color?(color) do
    atom_color = String.to_existing_atom(color)
    Map.has_key?(@basic_colors, atom_color)
  rescue
    ArgumentError -> false
  end

  @impl true
  def to_rgb(color) do
    Map.get(@basic_colors, color, {128, 128, 128})
  end

  @impl true
  def from_rgb(rgb) do
    Enum.min_by(Basic.basic_colors(), fn {_name, color_rgb} ->
      Converters.RGB.color_distance(rgb, color_rgb)
    end)
    |> elem(0)
  end

  @impl true
  def to_xterm256(color) do
    # Mapeo básico de ANSI a XTerm
    ansi_to_xterm = %{
      black: 0,
      red: 1,
      green: 2,
      yellow: 3,
      blue: 4,
      magenta: 5,
      cyan: 6,
      white: 7,
      bright_black: 8,
      bright_red: 9,
      bright_green: 10,
      bright_yellow: 11,
      bright_blue: 12,
      bright_magenta: 13,
      bright_cyan: 14,
      bright_white: 15,
      # Extended colors - approximate XTerm256 equivalents
      orange: 208,
      purple: 128,
      pink: 217,
      violet: 177,
      indigo: 62,
      teal: 44,
      lime: 10,
      navy: 18,
      maroon: 88,
      olive: 142,
      aqua: 50,
      fuchsia: 201,
      silver: 250,
      gray: 240,
      grey: 240
    }

    Map.get(ansi_to_xterm, color, 245)
  end

  @impl true
  def name(color), do: color
end
