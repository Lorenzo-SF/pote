defmodule Pote.Format.HSL do
  @moduledoc """
  HSL format for colours ({h, s, l}).
  h: 0-360 (degrees), s: 0-100 (%), l: 0-100 (%)
  """

  use Pote.Format

  alias Pote.Converters

  @type parsed :: {number(), number(), number()}

  @impl true
  def parse({h, s, l}) when h >= 0 and h <= 360 and s >= 0 and s <= 100 and l >= 0 and l <= 100 do
    {:ok, {h, s, l}}
  end

  @impl true
  def parse([h, s, l]) when h >= 0 and h <= 360 and s >= 0 and s <= 100 and l >= 0 and l <= 100 do
    {:ok, {h, s, l}}
  end

  @impl true
  def parse(str) when is_binary(str) do
    sanitized = Pote.Sanitizer.sanitize(str)

    case String.split(sanitized, ",") |> Enum.map(&String.trim/1) do
      [h_str, s_str, l_str] ->
        with {h, ""} <- Float.parse(h_str),
             {s, ""} <- Float.parse(s_str),
             {l, ""} <- Float.parse(l_str),
             true <- h >= 0 and h <= 360 and s >= 0 and s <= 100 and l >= 0 and l <= 100 do
          {:ok, {h, s, l}}
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
  def valid?({h, s, l}) when h >= 0 and h <= 360 and s >= 0 and s <= 100 and l >= 0 and l <= 100,
    do: true

  def valid?([h, s, l]) when h >= 0 and h <= 360 and s >= 0 and s <= 100 and l >= 0 and l <= 100,
    do: true

  def valid?(_), do: false

  @impl true
  def to_rgb(hsl), do: Converters.HSL.to_rgb(hsl)

  @impl true
  def from_rgb(rgb), do: Converters.RGB.to_hsl(rgb)

  @impl true
  def to_hsl(hsl), do: hsl

  @impl true
  def to_hsv(hsl) do
    hsl |> to_rgb() |> Converters.RGB.to_hsv()
  end
end
