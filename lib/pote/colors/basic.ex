defmodule Pote.Colors.Basic do
  @moduledoc """
  Unified map of basic color names to RGB values.

  This module provides a single source of truth for basic color definitions
  used across the Pote library.
  """

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
    bright_white: {255, 255, 255}
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
  Returns the ANSI code for a basic color name.
  """
  @spec ansi_code(atom()) :: non_neg_integer() | nil
  def ansi_code(color_name) do
    @ansi_codes[color_name]
  end
end
