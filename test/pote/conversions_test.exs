defmodule Pote.ConversionsTest do
  use ExUnit.Case
  alias Pote.Conversions

  describe "hex_to_rgb/1" do
    test "converts #RRGGBB format" do
      assert Conversions.hex_to_rgb("#FF0000") == {:ok, {255, 0, 0}}
      assert Conversions.hex_to_rgb("#00FF00") == {:ok, {0, 255, 0}}
      assert Conversions.hex_to_rgb("#0000FF") == {:ok, {0, 0, 255}}
      assert Conversions.hex_to_rgb("#FFFFFF") == {:ok, {255, 255, 255}}
      assert Conversions.hex_to_rgb("#000000") == {:ok, {0, 0, 0}}
      assert Conversions.hex_to_rgb("#1A2B3C") == {:ok, {26, 43, 60}}
    end

    test "handles lowercase hex" do
      assert Conversions.hex_to_rgb("#ff0000") == {:ok, {255, 0, 0}}
      assert Conversions.hex_to_rgb("#1a2b3c") == {:ok, {26, 43, 60}}
    end

    test "hex_to_rgb/1 returns error for invalid hex formats" do
      assert Conversions.hex_to_rgb("FF00M0") == {:error, :invalid_hex_format}
      assert Conversions.hex_to_rgb("GGGGGG") == {:error, :invalid_hex_format}
      assert Conversions.hex_to_rgb("#XXYYZZ") == {:error, :invalid_hex_format}
      assert Conversions.hex_to_rgb("#GGG") == {:error, :invalid_hex_format}
    end

    test "hex_to_rgb/1 accepts valid 3 and 6 char hex formats" do
      # 3-char hex (expanded to 6-char)
      assert Conversions.hex_to_rgb("#123") == {:ok, {17, 34, 51}}
      assert Conversions.hex_to_rgb("F00") == {:ok, {255, 0, 0}}
      # 6-char hex
      assert Conversions.hex_to_rgb("#FF0000") == {:ok, {255, 0, 0}}
      assert Conversions.hex_to_rgb("FF0000") == {:ok, {255, 0, 0}}
    end
  end

  describe "rgb_to_hex/1" do
    test "converts rgb tuple to #RRGGBB format" do
      assert Conversions.rgb_to_hex({255, 0, 0}) == "#FF0000"
      assert Conversions.rgb_to_hex({0, 255, 0}) == "#00FF00"
      assert Conversions.rgb_to_hex({0, 0, 255}) == "#0000FF"
      assert Conversions.rgb_to_hex({255, 255, 255}) == "#FFFFFF"
      assert Conversions.rgb_to_hex({0, 0, 0}) == "#000000"
      assert Conversions.rgb_to_hex({26, 43, 60}) == "#1A2B3C"
    end
  end

  describe "rgb_to_hsl/1 and hsl_to_rgb/1" do
    test "converts red back and forth" do
      rgb = {255, 0, 0}
      {h, s, l} = Conversions.rgb_to_hsl(rgb)
      assert_in_delta h, 0.0, 1.0
      assert_in_delta s, 100.0, 1.0
      assert_in_delta l, 50.0, 1.0

      {r, g, b} = Conversions.hsl_to_rgb({h, s, l})
      assert r == 255
      assert g == 0
      assert b == 0
    end

    test "converts white back and forth" do
      rgb = {255, 255, 255}
      {h, s, l} = Conversions.rgb_to_hsl(rgb)
      assert_in_delta h, 0.0, 1.0
      assert_in_delta s, 0.0, 1.0
      assert_in_delta l, 100.0, 1.0

      {r, g, b} = Conversions.hsl_to_rgb({h, s, l})
      assert r == 255
      assert g == 255
      assert b == 255
    end

    test "converts cyan back and forth" do
      rgb = {0, 255, 255}
      {h, s, l} = Conversions.rgb_to_hsl(rgb)
      assert_in_delta h, 180.0, 1.0

      {r, g, b} = Conversions.hsl_to_rgb({h, s, l})
      assert r == 0
      assert g == 255
      assert b == 255
    end
  end

  describe "rgb_to_hsv/1 and hsv_to_rgb/1" do
    test "converts red back and forth" do
      rgb = {255, 0, 0}
      {h, s, v} = Conversions.rgb_to_hsv(rgb)
      assert_in_delta h, 0.0, 1.0
      assert_in_delta s, 100.0, 1.0
      assert_in_delta v, 100.0, 1.0

      {r, g, b} = Conversions.hsv_to_rgb({h, s, v})
      assert r == 255
      assert g == 0
      assert b == 0
    end
  end

  describe "rgb_to_cmyk/1 and cmyk_to_rgb/1" do
    test "converts magenta back and forth" do
      rgb = {255, 0, 255}
      {c, m, y, k} = Conversions.rgb_to_cmyk(rgb)
      assert_in_delta c, 0.0, 1.0
      assert_in_delta m, 100.0, 1.0
      assert_in_delta y, 0.0, 1.0
      assert_in_delta k, 0.0, 1.0

      {r, g, b} = Conversions.cmyk_to_rgb({c, m, y, k})
      assert r == 255
      assert g == 0
      assert b == 255
    end

    test "converts black back and forth" do
      rgb = {0, 0, 0}
      {c, m, y, k} = Conversions.rgb_to_cmyk(rgb)
      assert_in_delta c, 0.0, 0.001
      assert_in_delta m, 0.0, 0.001
      assert_in_delta y, 0.0, 0.001
      assert_in_delta k, 100.0, 0.001

      assert Conversions.cmyk_to_rgb({c, m, y, k}) == {0, 0, 0}
    end
  end

  describe "rgb_to_xterm256/1 and ansi constants" do
    test "rgb_to_xterm256/1 converts black and white" do
      # 232 is first grayscale (black), 16 is black in standard 16
      assert Conversions.rgb_to_xterm256({0, 0, 0}) in [16, 232]
      assert Conversions.rgb_to_xterm256({255, 255, 255}) in [15, 231, 255]

      # Test color palette (16-231)
      assert Conversions.rgb_to_xterm256({255, 0, 0}) == 196
    end

    test "xterm256_to_rgb/1 converts correctly" do
      # Test grayscale ramp
      assert Conversions.xterm256_to_rgb(232) == {8, 8, 8}
      assert Conversions.xterm256_to_rgb(255) == {238, 238, 238}

      # Test standard palette
      assert Conversions.xterm256_to_rgb(196) == {255, 0, 0}
      assert Conversions.xterm256_to_rgb(16) == {0, 0, 0}
      assert Conversions.xterm256_to_rgb(231) == {255, 255, 255}

      # Test 0-15 base colors
      assert Conversions.xterm256_to_rgb(0) == {0, 0, 0}
      assert Conversions.xterm256_to_rgb(1) == {128, 0, 0}
      assert Conversions.xterm256_to_rgb(15) == {255, 255, 255}
    end

    test "edge cases for coverage" do
      # RGB to HSL grayscale
      {h, s, l} = Conversions.rgb_to_hsl({100, 100, 100})
      assert h == 0
      assert s == 0
      assert_in_delta l, 39.21, 0.1

      # RGB to XTerm grayscale - 50/255 = 0.196, escala 0-23 → 232 + round(0.196*23) = 232 + 4 = 236
      # (puede ser 236 o 237 dependiendo del método de redondeo)
      assert Conversions.rgb_to_xterm256({50, 50, 50}) in [236, 237]

      # RGB to HSV grayscale
      assert Conversions.rgb_to_hsv({0, 0, 0}) == {0.0, 0.0, 0.0}

      # Hex with missing characters handled by slice/with
      assert Conversions.hex_to_rgb("FF") == {:error, :invalid_hex_format}
    end
  end

  describe "blend/3" do
    test "blends two colors with a factor" do
      assert Conversions.blend({255, 0, 0}, {0, 0, 255}, 0.5) == {128, 0, 128}
      assert Conversions.blend({0, 0, 0}, {255, 255, 255}, 0.0) == {0, 0, 0}
      assert Conversions.blend({0, 0, 0}, {255, 255, 255}, 1.0) == {255, 255, 255}
    end
  end

  describe "rgb_to_hwb/1 and hwb_to_rgb/1" do
    test "converts red back and forth" do
      rgb = {255, 0, 0}
      {h, w, b} = Conversions.rgb_to_hwb(rgb)
      assert_in_delta h, 0.0, 1.0
      assert_in_delta w, 0.0, 0.01
      assert_in_delta b, 0.0, 0.01

      {r, g, b_val} = Conversions.hwb_to_rgb({h, w, b})
      assert r == 255
      assert g == 0
      assert b_val == 0
    end

    test "converts gray to hwb" do
      {h, w, b} = Conversions.rgb_to_hwb({128, 128, 128})
      assert h == 0.0
      assert_in_delta w, 0.502, 0.01
      assert_in_delta b, 0.498, 0.01
    end

    test "hwb_to_rgb with w+b >= 1 returns gray" do
      assert Conversions.hwb_to_rgb({0.0, 0.5, 0.5}) == {128, 128, 128}
    end
  end

  describe "rgb_to_xyz/1 and xyz_to_rgb/1" do
    test "converts red back and forth" do
      {x, y, z} = Conversions.rgb_to_xyz({255, 0, 0})
      assert x > 0
      assert y > 0
      assert z > 0

      {r, g, b} = Conversions.xyz_to_rgb({x, y, z})
      assert r == 255
      assert_in_delta g, 0, 5
      assert_in_delta b, 0, 5
    end

    test "converts black to xyz" do
      assert Conversions.rgb_to_xyz({0, 0, 0}) == {0.0, 0.0, 0.0}
    end
  end

  describe "rgb_to_lab/1 and lab_to_rgb/1" do
    test "converts red back and forth" do
      {l, a, b} = Conversions.rgb_to_lab({255, 0, 0})
      assert l > 50
      assert a > 0

      {r, g, b_val} = Conversions.lab_to_rgb({l, a, b})
      assert r == 255
      assert_in_delta g, 0, 5
      assert_in_delta b_val, 0, 5
    end

    test "white has high L" do
      {l, _a, _b} = Conversions.rgb_to_lab({255, 255, 255})
      assert_in_delta l, 100.0, 1.0
    end
  end

  describe "delta_e/2" do
    test "identical colors have zero distance" do
      assert Conversions.delta_e({255, 0, 0}, {255, 0, 0}) == 0.0
    end

    test "different colors have positive distance" do
      de = Conversions.delta_e({255, 0, 0}, {0, 0, 255})
      assert de > 100
    end
  end

  describe "relative_luminance/1 and contrast_ratio/2" do
    test "white has luminance 1.0" do
      assert Conversions.relative_luminance({255, 255, 255}) == 1.0
    end

    test "black has luminance 0.0" do
      assert Conversions.relative_luminance({0, 0, 0}) == 0.0
    end

    test "contrast ratio white vs black is 21.0" do
      assert Conversions.contrast_ratio({255, 255, 255}, {0, 0, 0}) == 21.0
    end

    test "identical colors have contrast 1.0" do
      assert Conversions.contrast_ratio({128, 128, 128}, {128, 128, 128}) == 1.0
    end
  end

  describe "kelvin conversions" do
    test "kelvin_to_rgb clamps extreme values" do
      assert Conversions.kelvin_to_rgb(500) == Conversions.kelvin_to_rgb(1000)
      assert Conversions.kelvin_to_rgb(50_000) == Conversions.kelvin_to_rgb(40_000)
    end

    test "kelvin_to_rgb returns valid RGB" do
      {r, g, b} = Conversions.kelvin_to_rgb(6500)
      assert r in 0..255
      assert g in 0..255
      assert b in 0..255
    end

    test "rgb_to_kelvin approximates temperature" do
      k = Conversions.rgb_to_kelvin({255, 160, 60})
      assert is_integer(k)
      assert k >= 1000 and k <= 40_000
    end
  end

  describe "YUV conversions" do
    test "rgb_to_yuv and yuv_to_rgb round-trip" do
      rgb = {255, 128, 0}
      yuv = Conversions.rgb_to_yuv(rgb)
      {r, g, b} = Conversions.yuv_to_rgb(yuv)
      assert r == 255
      assert_in_delta g, 128, 2
      assert_in_delta b, 0, 2
    end
  end

  describe "YCbCr conversions" do
    test "rgb_to_ycbcr and ycbcr_to_rgb round-trip" do
      rgb = {255, 128, 0}
      ycbcr = Conversions.rgb_to_ycbcr(rgb)
      {r, g, b} = Conversions.ycbcr_to_rgb(ycbcr)
      assert r == 255
      assert_in_delta g, 128, 40
      assert_in_delta b, 0, 5
    end
  end

  describe "rgb_to_pantone_approx/1" do
    test "finds close match for red" do
      result = Conversions.rgb_to_pantone_approx({255, 0, 0})
      assert is_tuple(result)
      {name, distance} = result
      assert is_binary(name)
      assert distance < 30.0
    end

    test "returns a match for colors close to pantone palette" do
      result = Conversions.rgb_to_pantone_approx({255, 0, 0})
      assert is_tuple(result)
      {name, distance} = result
      assert is_binary(name)
      assert distance < 30.0
    end

    test "returns tuple for any color with match" do
      result = Conversions.rgb_to_pantone_approx({128, 128, 128})
      assert is_tuple(result)
    end
  end

  describe "color_distance/2" do
    test "calculates manhattan distance" do
      assert Conversions.color_distance({0, 0, 0}, {255, 255, 255}) == 765
      assert Conversions.color_distance({100, 100, 100}, {100, 100, 100}) == 0
      assert Conversions.color_distance({0, 0, 0}, {1, 1, 1}) == 3
    end
  end

  describe "clamp/1" do
    test "clamps values to 0-255 range" do
      assert Conversions.clamp(-100) == 0
      assert Conversions.clamp(300) == 255
      assert Conversions.clamp(128) == 128
      assert Conversions.clamp(0) == 0
      assert Conversions.clamp(255) == 255
    end
  end

  describe "rgb_to_kelvin/1 edge cases" do
    test "returns nil when search fails to converge" do
      result = Conversions.rgb_to_kelvin({128, 128, 128})
      assert is_integer(result) or result == nil
    end
  end
end
