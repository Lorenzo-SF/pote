defmodule Pote.Format.CMYK do
  @moduledoc """
  CMYK format for colours ({c, m, y, k}).
  All values: 0-100 (%)
  """

  use Pote.Format

  alias Pote.Converters

  @type parsed :: {number(), number(), number(), number()}

  @impl true
  def parse({c, m, y, k})
      when c >= 0 and c <= 100 and m >= 0 and m <= 100 and y >= 0 and y <= 100 and
             k >= 0 and k <= 100 do
    {:ok, {c, m, y, k}}
  end

  @impl true
  def parse([c, m, y, k])
      when c >= 0 and c <= 100 and m >= 0 and m <= 100 and y >= 0 and y <= 100 and
             k >= 0 and k <= 100 do
    {:ok, {c, m, y, k}}
  end

  @impl true
  def parse(str) when is_binary(str) do
    sanitized = Pote.Sanitizer.sanitize(str)

    case String.split(sanitized, ",") |> Enum.map(&String.trim/1) do
      [c_str, m_str, y_str, k_str] ->
        parse_cmyk_strings(c_str, m_str, y_str, k_str)

      _ ->
        :error
    end
  end

  @impl true
  def parse(_), do: :error

  defp parse_cmyk_strings(c_str, m_str, y_str, k_str) do
    with {c, ""} <- Float.parse(c_str),
         {m, ""} <- Float.parse(m_str),
         {y, ""} <- Float.parse(y_str),
         {k, ""} <- Float.parse(k_str),
         true <- valid_cmyk?(c, m, y, k) do
      {:ok, {c, m, y, k}}
    else
      _ -> :error
    end
  end

  defp valid_cmyk?(c, m, y, k) do
    c >= 0 and c <= 100 and
      m >= 0 and m <= 100 and
      y >= 0 and y <= 100 and
      k >= 0 and k <= 100
  end

  @impl true
  def valid?({c, m, y, k})
      when c >= 0 and c <= 100 and m >= 0 and m <= 100 and y >= 0 and y <= 100 and
             k >= 0 and k <= 100,
      do: true

  def valid?([c, m, y, k])
      when c >= 0 and c <= 100 and m >= 0 and m <= 100 and y >= 0 and y <= 100 and
             k >= 0 and k <= 100,
      do: true

  def valid?(_), do: false

  @impl true
  def to_rgb(cmyk), do: Converters.CMYK.to_rgb(cmyk)

  @impl true
  def from_rgb(rgb), do: Converters.RGB.to_cmyk(rgb)

  @impl true
  def to_cmyk(cmyk), do: cmyk
end
