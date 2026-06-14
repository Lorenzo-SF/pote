defmodule Pote.Format.HSV do
  @moduledoc """
  HSV format for colours ({h, s, v}).
  h: 0-360 (degrees), s: 0-100 (%), v: 0-100 (%)
  """

  use Pote.Format

  alias Pote.Converters

  @type parsed :: {number(), number(), number()}

  @impl true
  def parse({h, s, v}) when h >= 0 and h <= 360 and s >= 0 and s <= 100 and v >= 0 and v <= 100 do
    {:ok, {h, s, v}}
  end

  @impl true
  def parse([h, s, v]) when h >= 0 and h <= 360 and s >= 0 and s <= 100 and v >= 0 and v <= 100 do
    {:ok, {h, s, v}}
  end

  @impl true
  def parse(str) when is_binary(str) do
    sanitized = Pote.Sanitizer.sanitize(str)

    case String.split(sanitized, ",") |> Enum.map(&String.trim/1) do
      [h_str, s_str, v_str] ->
        with {h, ""} <- Float.parse(h_str),
             {s, ""} <- Float.parse(s_str),
             {v, ""} <- Float.parse(v_str),
             true <- h >= 0 and h <= 360 and s >= 0 and s <= 100 and v >= 0 and v <= 100 do
          {:ok, {h, s, v}}
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
  def valid?({h, s, v}) when h >= 0 and h <= 360 and s >= 0 and s <= 100 and v >= 0 and v <= 100,
    do: true

  def valid?([h, s, v]) when h >= 0 and h <= 360 and s >= 0 and s <= 100 and v >= 0 and v <= 100,
    do: true

  def valid?(_), do: false

  @impl true
  def to_rgb(hsv), do: Converters.HSV.to_rgb(hsv)

  @impl true
  def from_rgb(rgb), do: Converters.RGB.to_hsv(rgb)

  @impl true
  def to_hsv(hsv), do: hsv

  @impl true
  def to_hsl(hsv) do
    hsv |> to_rgb() |> Converters.RGB.to_hsl()
  end
end
