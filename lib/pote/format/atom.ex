defmodule Pote.Format.Atom do
  @moduledoc """
  Atom format for colours by name.

  Supports custom colours defined in the default palette:
  primary, secondary, ternary, quaternary, success, warning, error, info,
  debug, happy, critical, alert, background, menu,
  no_color, gradient_1 through gradient_6
  """

  use Pote.Format

  alias Pote.Converters

  @type parsed :: atom()

  @impl true
  def parse(color) when is_atom(color) do
    if Map.has_key?(Pote.default_colors(), color) do
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
    parse(atom_color)
  rescue
    ArgumentError -> :error
  end

  @impl true
  def valid?(color) when is_atom(color) do
    Map.has_key?(Pote.default_colors(), color)
  end

  def valid?(color) when is_binary(color), do: valid_binary_color?(color)
  def valid?(_), do: false

  defp valid_binary_color?(color) do
    atom_color = String.to_existing_atom(color)
    Map.has_key?(Pote.default_colors(), atom_color)
  rescue
    ArgumentError -> false
  end

  @impl true
  def to_rgb(color) do
    case Pote.default_colors() do
      %{^color => rgb} -> rgb
      _ -> {128, 128, 128}
    end
  end

  @impl true
  def from_rgb(rgb) do
    Pote.default_colors()
    |> Enum.min_by(fn {_name, color_rgb} ->
      Converters.RGB.color_distance(rgb, color_rgb)
    end)
    |> elem(0)
  end

  @impl true
  def name(color), do: color
end
