defmodule Pote do
  @moduledoc """
  Pote — canonical color types, default palette, and top-level helpers.

  This module defines the core color type definitions used throughout the
  entire library and provides access to the built-in default color palette.
  """

  @type rgb :: {non_neg_integer(), non_neg_integer(), non_neg_integer()}
  @type hsl :: {float(), float(), float()}
  @type hsv :: {float(), float(), float()}
  @type cmyk :: {float(), float(), float(), float()}
  @type hex :: String.t()
  @type xterm256 :: 0..255
  @type argb :: {non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer()}
  @type color_input :: rgb() | hex() | hsl() | hsv() | cmyk() | xterm256() | atom() | String.t()
  @type color_output :: rgb() | nil

  @default_colors %{
    primary: {161, 231, 250},
    secondary: {58, 171, 163},
    ternary: {255, 128, 0},
    quaternary: {155, 66, 226},
    no_color: {248, 248, 242},
    background: {40, 44, 52},
    success: {151, 197, 60},
    warning: {253, 216, 8},
    error: {255, 91, 91},
    info: {0, 255, 255},
    menu: {171, 205, 241},
    alert: {253, 216, 8},
    critical: {255, 91, 91},
    debug: {176, 176, 176},
    happy: {238, 128, 195},
    sad: {129, 161, 193},
    gradient_1: {161, 231, 250},
    gradient_2: {136, 192, 208},
    gradient_3: {129, 161, 193},
    gradient_4: {94, 129, 172},
    gradient_5: {76, 86, 106},
    gradient_6: {67, 76, 94}
  }

  @doc "Returns the default color palette."
  @spec default_colors() :: map()
  def default_colors, do: @default_colors

  @doc "Looks up a color by atom name. Returns RGB tuple or nil."
  @spec get_color(atom()) :: {integer(), integer(), integer()} | nil
  def get_color(name) do
    Map.get(@default_colors, name)
  end

  @doc "Checks if a color name exists in the default palette."
  @spec color_exists?(atom()) :: boolean()
  def color_exists?(name) do
    Map.has_key?(@default_colors, name)
  end

  @doc "Returns all available color names."
  @spec color_names() :: [atom()]
  def color_names do
    Map.keys(@default_colors)
  end

  @doc "Returns a specific color by name (alias for get_color/1)."
  @spec color(atom()) :: {integer(), integer(), integer()} | nil
  def color(name), do: get_color(name)
end
