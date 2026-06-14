defmodule Pote.PropertyTest do
  @moduledoc """
  Property-based tests para verificar invariantes de conversiones de color.
  Usa StreamData para generar inputs aleatorios y verificar que las
  conversiones roundtrip son aproximadamente correctas.
  """
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Pote.Converters.HSL
  alias Pote.Converters.HSV
  alias Pote.Converters.RGB

  describe "RGB roundtrips" do
    property "rgb → hex → rgb" do
      check all(
              r <- integer(0..255),
              g <- integer(0..255),
              b <- integer(0..255)
            ) do
        hex = RGB.to_hex({r, g, b})
        assert {:ok, {r, g, b}} == RGB.from_hex(hex)
      end
    end

    property "rgb → hsl → rgb (tolerancia 1 por canal)" do
      check all(
              r <- integer(0..255),
              g <- integer(0..255),
              b <- integer(0..255)
            ) do
        hsl = RGB.to_hsl({r, g, b})
        {r2, g2, b2} = HSL.to_rgb(hsl)
        assert abs(r - r2) <= 1, "R: #{r} vs #{r2}"
        assert abs(g - g2) <= 1, "G: #{g} vs #{g2}"
        assert abs(b - b2) <= 1, "B: #{b} vs #{b2}"
      end
    end

    property "rgb → hsv → rgb" do
      check all(
              r <- integer(0..255),
              g <- integer(0..255),
              b <- integer(0..255)
            ) do
        hsv = RGB.to_hsv({r, g, b})
        {r2, g2, b2} = HSV.to_rgb(hsv)
        assert abs(r - r2) <= 1, "R: #{r} vs #{r2}"
        assert abs(g - g2) <= 1, "G: #{g} vs #{g2}"
        assert abs(b - b2) <= 1, "B: #{b} vs #{b2}"
      end
    end
  end

  describe "Edge cases" do
    property "negro siempre negro" do
      check all(_ <- integer(0..255)) do
        assert {:ok, {0, 0, 0}} == RGB.from_hex(RGB.to_hex({0, 0, 0}))
      end
    end

    property "blanco siempre blanco" do
      check all(_ <- integer(0..255)) do
        assert {:ok, {255, 255, 255}} == RGB.from_hex(RGB.to_hex({255, 255, 255}))
      end
    end

    property "grises (r=g=b) preservan hue=0" do
      check all(v <- integer(0..255)) do
        {h, s, _l} = RGB.to_hsl({v, v, v})
        assert h == 0
        assert s == 0
      end
    end
  end
end
