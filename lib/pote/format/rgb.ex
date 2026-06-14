defmodule Pote.Format.RGB do
  @moduledoc """
  RGB format for colours ({r, g, b}).

  Implements the `Pote.Format` behaviour to provide
  all conversion operations from/to RGB.
  """

  use Pote.Format

  @type parsed :: {0..255, 0..255, 0..255}

  @impl true
  @spec parse(any()) :: {:ok, parsed()} | :error
  def parse({r, g, b}) when r in 0..255 and g in 0..255 and b in 0..255 do
    {:ok, {r, g, b}}
  end

  @impl true
  def parse([r, g, b]) when r in 0..255 and g in 0..255 and b in 0..255 do
    {:ok, {r, g, b}}
  end

  @impl true
  def parse(str) when is_binary(str) do
    sanitized = Pote.Sanitizer.sanitize(str)

    case String.split(sanitized, ",") |> Enum.map(&String.trim/1) do
      [r_str, g_str, b_str] ->
        with {r, ""} <- Integer.parse(r_str),
             {g, ""} <- Integer.parse(g_str),
             {b, ""} <- Integer.parse(b_str),
             true <- r in 0..255 and g in 0..255 and b in 0..255 do
          {:ok, {r, g, b}}
        else
          _ -> :error
        end

      _ ->
        :error
    end
  end

  @impl true
  def parse(_), do: :error

  @impl true
  @spec valid?(any()) :: boolean()
  def valid?({r, g, b}) when r in 0..255 and g in 0..255 and b in 0..255, do: true
  def valid?([r, g, b]) when r in 0..255 and g in 0..255 and b in 0..255, do: true
  def valid?(_), do: false

  @impl true
  @spec to_rgb(parsed()) :: {0..255, 0..255, 0..255}
  def to_rgb(rgb), do: rgb

  @impl true
  @spec from_rgb({0..255, 0..255, 0..255}) :: parsed()
  def from_rgb(rgb), do: rgb

  # Las demás funciones usan las implementaciones por defecto del behaviour
end
