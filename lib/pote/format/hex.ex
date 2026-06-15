defmodule Pote.Format.Hex do
  @moduledoc """
  Hex format for colours (#RRGGBB).

  Implements the `Pote.Format` behaviour to provide
  all conversion operations from/to hex.
  """

  use Pote.Format

  alias Pote.Converters.RGB

  @type parsed :: String.t()

  @impl true
  def parse(<<"#", r1, r2, g1, g2, b1, b2>> = hex)
      when r1 in ~c"0123456789ABCDEFabcdef" and r2 in ~c"0123456789ABCDEFabcdef" and
             g1 in ~c"0123456789ABCDEFabcdef" and g2 in ~c"0123456789ABCDEFabcdef" and
             b1 in ~c"0123456789ABCDEFabcdef" and b2 in ~c"0123456789ABCDEFabcdef" do
    {:ok, String.upcase(hex)}
  end

  @impl true
  def parse(hex) when is_binary(hex) do
    case RGB.from_hex(hex) do
      {:ok, _rgb} -> {:ok, normalize_hex(hex)}
      _ -> :error
    end
  end

  @impl true
  def parse(_), do: :error

  @impl true
  def valid?(<<"+", _::binary>>), do: false
  def valid?(<<"#", _::binary>> = hex), do: byte_size(hex) == 7
  def valid?(hex) when is_binary(hex), do: byte_size(hex) == 6
  def valid?(_), do: false

  @impl true
  def to_rgb(<<"#", r1, r2, g1, g2, b1, b2>>) do
    r = hex_char_to_int(r1) * 16 + hex_char_to_int(r2)
    g = hex_char_to_int(g1) * 16 + hex_char_to_int(g2)
    b = hex_char_to_int(b1) * 16 + hex_char_to_int(b2)
    {r, g, b}
  end

  @impl true
  def to_hex(hex), do: hex

  @impl true
  def from_rgb({r, g, b}) do
    normalize_hex("##{to_hex_component(r)}#{to_hex_component(g)}#{to_hex_component(b)}")
  end

  # ============================================================================
  # Funciones privadas
  # ============================================================================

  defp normalize_hex(hex) do
    hex = String.replace_prefix(hex, "#", "")
    "#" <> String.upcase(hex)
  end

  defp hex_char_to_int(c) when c >= ?0 and c <= ?9, do: c - ?0
  defp hex_char_to_int(c) when c >= ?A and c <= ?F, do: c - ?A + 10
  defp hex_char_to_int(c) when c >= ?a and c <= ?f, do: c - ?a + 10

  defp to_hex_component(n) when n < 16, do: "0#{Integer.to_string(n, 16)}"
  defp to_hex_component(n), do: Integer.to_string(n, 16)
end
