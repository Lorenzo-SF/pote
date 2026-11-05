defmodule Pote.Colors.Basic do
  @moduledoc """
  Unified map of basic color names to RGB values.

  This module provides a single source of truth for basic color definitions
  used across the Pote library.
  """

  @basic_colors %{
    # Standard 16 ANSI colours
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
    # Common aliases
    gray: {128, 128, 128},
    grey: {128, 128, 128},
    # Extended colours (common web/ui names)
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
    silver: {192, 192, 192}
  }

  @ansi_codes %{
    black: 30,
    red: 31,
    green: 32,
    yellow: 33,
    blue: 34,
    magenta: 35,
    cyan: 36,
    white: 37,
    bright_black: 90,
    bright_red: 91,
    bright_green: 92,
    bright_yellow: 93,
    bright_blue: 94,
    bright_magenta: 95,
    bright_cyan: 96,
    bright_white: 97
  }

  @doc """
  Returns the map of basic color names to RGB values.
  """
  @spec basic_colors() :: %{atom() => {0..255, 0..255, 0..255}}
  def basic_colors, do: @basic_colors

  @doc """
  Returns all named colors (basic + extended) for use in parsing.
  """
  @spec named_colors() :: %{atom() => {0..255, 0..255, 0..255}}
  def named_colors, do: @basic_colors

  @doc """
  Returns the ANSI code for a basic color name.
  """
  @spec ansi_code(atom()) :: non_neg_integer() | nil
  def ansi_code(color_name) do
    @ansi_codes[color_name]
  end
end
