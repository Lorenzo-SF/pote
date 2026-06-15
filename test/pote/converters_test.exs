defmodule Pote.ConvertersTest do
  use ExUnit.Case, async: true

  alias Pote.Converters

  describe "RGB conversions" do
    test "to_hex converts correctly" do
      assert Converters.RGB.to_hex({255, 128, 0}) == "#FF8000"
      assert Converters.RGB.to_hex({0, 0, 0}) == "#000000"
      assert Converters.RGB.to_hex({255, 255, 255}) == "#FFFFFF"
    end

    test "from_hex parses correctly" do
      assert Converters.RGB.from_hex("#FF8000") == {:ok, {255, 128, 0}}
      assert Converters.RGB.from_hex("FF8000") == {:ok, {255, 128, 0}}
      assert Converters.RGB.from_hex("#F00") == {:ok, {255, 0, 0}}
      assert Converters.RGB.from_hex("invalid") == {:error, :invalid_hex_format}
    end

    test "to_hsl converts correctly" do
      result = Converters.RGB.to_hsl({255, 128, 0})
      assert_in_delta result |> elem(0), 30.0, 0.2
      assert_in_delta result |> elem(1), 100.0, 0.2
      assert_in_delta result |> elem(2), 50.0, 0.2
    end

    test "to_hsv converts correctly" do
      result = Converters.RGB.to_hsv({255, 128, 0})
      assert_in_delta result |> elem(0), 30.0, 0.2
      assert_in_delta result |> elem(1), 100.0, 0.2
      assert_in_delta result |> elem(2), 100.0, 0.2
    end

    test "to_cmyk converts correctly" do
      result = Converters.RGB.to_cmyk({255, 128, 0})
      assert_in_delta result |> elem(0), 0.0, 0.2
      assert_in_delta result |> elem(1), 49.8, 0.2
      assert_in_delta result |> elem(2), 100.0, 0.2
      assert_in_delta result |> elem(3), 0.0, 0.2
    end

    test "to_xterm256 converts correctly" do
      # XTerm256 approximation - just verify it returns a valid value
      assert Converters.RGB.to_xterm256({255, 128, 0}) in 200..220
      assert Converters.RGB.to_xterm256({0, 0, 0}) == 16
    end

    test "blend combines colors correctly" do
      assert Converters.RGB.blend({255, 0, 0}, {0, 0, 255}, 0.5) == {128, 0, 128}
      assert Converters.RGB.blend({255, 0, 0}, {0, 0, 255}, 0.0) == {255, 0, 0}
      assert Converters.RGB.blend({255, 0, 0}, {0, 0, 255}, 1.0) == {0, 0, 255}
    end

    test "color_distance calculates correctly" do
      assert Converters.RGB.color_distance({0, 0, 0}, {255, 255, 255}) == 765
      assert Converters.RGB.color_distance({100, 100, 100}, {100, 100, 100}) == 0
    end

    test "clamp bounds values" do
      assert Converters.RGB.clamp(300) == 255
      assert Converters.RGB.clamp(-10) == 0
      assert Converters.RGB.clamp(128) == 128
    end
  end

  describe "HSL conversions" do
    test "to_rgb converts correctly" do
      assert Converters.HSL.to_rgb({30.0, 100.0, 50.0}) == {255, 128, 0}
      assert Converters.HSL.to_rgb({0.0, 0.0, 0.0}) == {0, 0, 0}
      assert Converters.HSL.to_rgb({0.0, 0.0, 100.0}) == {255, 255, 255}
    end

    test "from_rgb is inverse of to_rgb" do
      rgb = {255, 128, 0}
      hsl = Converters.HSL.from_rgb(rgb)
      result = Converters.HSL.to_rgb(hsl)
      assert result == rgb
    end
  end

  describe "HSV conversions" do
    test "to_rgb converts correctly" do
      assert Converters.HSV.to_rgb({30.0, 100.0, 100.0}) == {255, 128, 0}
      assert Converters.HSV.to_rgb({0.0, 0.0, 0.0}) == {0, 0, 0}
      assert Converters.HSV.to_rgb({0.0, 0.0, 100.0}) == {255, 255, 255}
    end

    test "from_rgb is inverse of to_rgb" do
      rgb = {255, 128, 0}
      hsv = Converters.HSV.from_rgb(rgb)
      result = Converters.HSV.to_rgb(hsv)
      assert result == rgb
    end
  end

  describe "CMYK conversions" do
    test "to_rgb converts correctly" do
      assert Converters.CMYK.to_rgb({0.0, 49.8, 100.0, 0.0}) == {255, 128, 0}
      assert Converters.CMYK.to_rgb({0.0, 0.0, 0.0, 100.0}) == {0, 0, 0}
      assert Converters.CMYK.to_rgb({0.0, 0.0, 0.0, 0.0}) == {255, 255, 255}
    end

    test "from_rgb is inverse of to_rgb" do
      rgb = {255, 128, 0}
      cmyk = Converters.CMYK.from_rgb(rgb)
      result = Converters.CMYK.to_rgb(cmyk)
      assert result == rgb
    end
  end

  describe "XTerm256 conversions" do
    test "to_rgb converts basic colors" do
      assert Converters.XTerm256.to_rgb(0) == {0, 0, 0}
      assert Converters.XTerm256.to_rgb(1) == {128, 0, 0}
      assert Converters.XTerm256.to_rgb(15) == {255, 255, 255}
    end

    test "to_rgb converts grayscale range" do
      assert Converters.XTerm256.to_rgb(232) == {8, 8, 8}
      assert Converters.XTerm256.to_rgb(255) == {238, 238, 238}
    end

    test "to_rgb converts color cube" do
      assert Converters.XTerm256.to_rgb(16) == {0, 0, 0}
      assert Converters.XTerm256.to_rgb(231) == {255, 255, 255}
    end

    test "from_rgb converts to nearest xterm" do
      # XTerm256 approximation - just verify it returns a valid value
      xterm = Converters.XTerm256.from_rgb({255, 128, 0})
      assert xterm in 200..220
    end
  end

  describe "HWB conversions" do
    test "to_rgb converts correctly" do
      assert Converters.HWB.to_rgb({0.0, 0.0, 0.0}) == {255, 0, 0}
      assert Converters.HWB.to_rgb({0.0, 1.0, 0.0}) == {255, 255, 255}
      assert Converters.HWB.to_rgb({0.0, 0.0, 1.0}) == {0, 0, 0}
    end

    test "from_rgb is inverse of to_rgb" do
      rgb = {255, 0, 0}
      hwb = Converters.HWB.from_rgb(rgb)
      result = Converters.HWB.to_rgb(hwb)
      assert result == rgb
    end
  end

  describe "convenience functions" do
    test "hsl_to_rgb and rgb_to_hsl are inverses" do
      rgb = {100, 150, 200}
      hsl = Converters.rgb_to_hsl(rgb)
      assert Converters.hsl_to_rgb(hsl) == rgb
    end

    test "hsv_to_rgb and rgb_to_hsv are inverses" do
      rgb = {100, 150, 200}
      hsv = Converters.rgb_to_hsv(rgb)
      assert Converters.hsv_to_rgb(hsv) == rgb
    end

    test "cmyk_to_rgb and rgb_to_cmyk are inverses" do
      rgb = {100, 150, 200}
      cmyk = Converters.rgb_to_cmyk(rgb)
      assert Converters.cmyk_to_rgb(cmyk) == rgb
    end

    test "hwb_to_rgb and rgb_to_hwb are inverses" do
      rgb = {100, 150, 200}
      hwb = Converters.rgb_to_hwb(rgb)
      assert Converters.hwb_to_rgb(hwb) == rgb
    end

    test "rgb_to_hex and hex_to_rgb are inverses" do
      rgb = {100, 150, 200}
      hex = Converters.rgb_to_hex(rgb)
      assert {:ok, rgb} == Converters.hex_to_rgb(hex)
    end
  end
end
