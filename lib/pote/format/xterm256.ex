defmodule Pote.Format.XTerm256 do
  @moduledoc """
  XTerm256 format for colours (0-255).
  """

  use Pote.Format

  alias Pote.Converters

  @type parsed :: 0..255

  @impl true
  def parse(n) when is_integer(n) and n >= 0 and n <= 255 do
    {:ok, n}
  end

  @impl true
  def parse(str) when is_binary(str) do
    sanitized = Pote.Sanitizer.sanitize(str)

    case Integer.parse(sanitized) do
      {n, ""} when n >= 0 and n <= 255 -> {:ok, n}
      _ -> :error
    end
  end

  @impl true
  def parse(_), do: :error

  @impl true
  def valid?(n) when is_integer(n) and n >= 0 and n <= 255, do: true

  def valid?(str) when is_binary(str) do
    case Integer.parse(str) do
      {n, ""} -> n >= 0 and n <= 255
      _ -> false
    end
  end

  def valid?(_), do: false

  @impl true
  def to_rgb(xterm), do: Converters.XTerm256.to_rgb(xterm)

  @impl true
  def to_xterm256(xterm), do: xterm

  @impl true
  def from_rgb(rgb), do: Converters.RGB.to_xterm256(rgb)
end
