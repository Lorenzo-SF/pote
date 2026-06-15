defmodule Pote.Format.ARGB do
  @moduledoc """
  ARGB format for colours ({a, r, g, b}).
  """

  use Pote.Format

  @type parsed :: {0..255, 0..255, 0..255, 0..255}

  @impl true
  def parse({a, r, g, b}) when a in 0..255 and r in 0..255 and g in 0..255 and b in 0..255 do
    {:ok, {a, r, g, b}}
  end

  @impl true
  def parse([a, r, g, b]) when a in 0..255 and r in 0..255 and g in 0..255 and b in 0..255 do
    {:ok, {a, r, g, b}}
  end

  @impl true
  def parse(str) when is_binary(str) do
    sanitized = Pote.Sanitizer.sanitize(str)

    case String.split(sanitized, ",") |> Enum.map(&String.trim/1) do
      [a_str, r_str, g_str, b_str] ->
        with {a, ""} <- Integer.parse(a_str),
             {r, ""} <- Integer.parse(r_str),
             {g, ""} <- Integer.parse(g_str),
             {b, ""} <- Integer.parse(b_str),
             true <- a in 0..255 and r in 0..255 and g in 0..255 and b in 0..255 do
          {:ok, {a, r, g, b}}
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
  def valid?({a, r, g, b}) when a in 0..255 and r in 0..255 and g in 0..255 and b in 0..255,
    do: true

  def valid?([a, r, g, b]) when a in 0..255 and r in 0..255 and g in 0..255 and b in 0..255,
    do: true

  def valid?(_), do: false

  @impl true
  def to_rgb({_a, r, g, b}), do: {r, g, b}

  @impl true
  def to_argb(argb), do: argb

  @impl true
  def from_rgb({r, g, b}), do: {255, r, g, b}
end
