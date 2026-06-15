defmodule Pote.ColorInfoTest do
  use ExUnit.Case
  alias Pote.ColorInfo

  describe "new/0" do
    test "creates empty ColorInfo" do
      ci = ColorInfo.new()
      assert ci.rgb == nil
      assert ci.hex == nil
      assert ci.inverted == false
    end
  end

  describe "new/1" do
    test "creates ColorInfo from hex string" do
      ci = ColorInfo.new("#FF8000")
      assert ci.rgb == {255, 128, 0}
    end

    test "creates ColorInfo from RGB tuple" do
      ci = ColorInfo.new({255, 128, 0})
      assert ci.rgb == {255, 128, 0}
    end

    test "creates ColorInfo from atom color" do
      ci = ColorInfo.new(:red)
      assert ci.rgb == {255, 0, 0}
    end

    test "creates ColorInfo from string color name" do
      ci = ColorInfo.new("blue")
      assert ci.rgb == {0, 0, 255}
    end

    test "creates ColorInfo from HSL tuple" do
      ci = ColorInfo.new({30.0, 100.0, 50.0})
      assert ci.rgb == {255, 128, 0}
    end

    test "creates ColorInfo from xterm256 string format" do
      ci = ColorInfo.new("xterm:208")
      assert ci.rgb == {255, 102, 0}
    end

    test "creates ColorInfo from prefixed string formats" do
      ci_rgb = ColorInfo.new("rgb:255,128,0")
      assert ci_rgb.rgb == {255, 128, 0}

      ci_hex = ColorInfo.new("hex:FF8000")
      assert ci_hex.rgb == {255, 128, 0}

      ci_hsl = ColorInfo.new("hsl:30,100,50")
      assert ci_hsl.rgb == {255, 128, 0}
    end

    test "wraps existing ColorInfo when passed" do
      original = ColorInfo.new("#FF8000")
      wrapped = ColorInfo.new(original)
      assert wrapped.rgb == original.rgb
      assert wrapped.inverted == false
    end

    test "returns empty ColorInfo for invalid input" do
      ci = ColorInfo.new("invalid_color_xyz")
      assert ci.rgb == nil
    end
  end

  describe "new/2 with options" do
    test "inverted option sets inverted flag" do
      ci = ColorInfo.new(:red, inverted: true)
      assert ci.inverted == true
    end

    test "inverted option preserves original inverted when true" do
      original = ColorInfo.new(:red, inverted: true)
      ci = ColorInfo.new(original, inverted: false)
      assert ci.inverted == false
    end

    test "default inverted is false" do
      ci = ColorInfo.new(:red)
      assert ci.inverted == false
    end
  end

  describe "basic_colors/0" do
    test "returns map of basic colors" do
      colors = ColorInfo.basic_colors()
      assert is_map(colors)
      assert colors[:red] == {255, 0, 0}
      assert colors[:green] == {0, 255, 0}
      assert colors[:blue] == {0, 0, 255}
      assert colors[:bright_red] == {255, 128, 128}
    end

    test "has all standard basic colors" do
      colors = ColorInfo.basic_colors()

      expected = [
        :black,
        :red,
        :green,
        :yellow,
        :blue,
        :magenta,
        :cyan,
        :white,
        :bright_black,
        :bright_red,
        :bright_green,
        :bright_yellow,
        :bright_blue,
        :bright_magenta,
        :bright_cyan,
        :bright_white
      ]

      Enum.each(expected, fn c -> assert Map.has_key?(colors, c) end)
    end
  end

  describe "to_ansi/1" do
    test "returns empty string for nil color" do
      ci = %ColorInfo{rgb: nil, xterm256: nil}
      assert ColorInfo.to_ansi(ci) == ""
    end

    test "returns empty string for unknown type" do
      ci = %ColorInfo{}
      assert ColorInfo.to_ansi(ci) == ""
    end

    test "returns ANSI escape for RGB color" do
      ci = ColorInfo.new({255, 0, 0})
      ansi = ColorInfo.to_ansi(ci)
      assert ansi == "\e[38;2;255;0;0m"
    end

    test "returns inverted ANSI escape for RGB when inverted" do
      ci = ColorInfo.new({255, 0, 0}, inverted: true)
      ansi = ColorInfo.to_ansi(ci)
      assert ansi == "\e[48;2;255;0;0m"
    end

    test "returns basic ANSI for named color" do
      ci = ColorInfo.new(:red)
      ansi = ColorInfo.to_ansi(ci)
      assert ansi == "\e[31m"
    end

    test "returns bright ANSI for bright color" do
      ci = ColorInfo.new(:bright_red)
      ansi = ColorInfo.to_ansi(ci)
      assert ansi == "\e[91m"
    end

    test "returns 256-color code for xterm256" do
      ci = %ColorInfo{xterm256: 208}
      ansi = ColorInfo.to_ansi(ci)
      assert ansi == "\e[38;5;208m"
    end

    test "returns inverted 256-color code" do
      ci = %ColorInfo{xterm256: 208, inverted: true}
      ansi = ColorInfo.to_ansi(ci)
      assert ansi == "\e[48;5;208m"
    end
  end

  describe "lighter/2" do
    test "returns lighter variant blended with white" do
      ci = ColorInfo.new({100, 100, 100})
      lighter = ColorInfo.lighter(ci, 0.5)
      assert lighter.rgb == {178, 178, 178}
    end

    test "handles nil rgb with black default then blends with white" do
      ci = %ColorInfo{rgb: nil}
      lighter = ColorInfo.lighter(ci, 0.5)
      assert lighter.rgb == {128, 128, 128}
    end

    test "factor 0 returns original color" do
      ci = ColorInfo.new({100, 100, 100})
      lighter = ColorInfo.lighter(ci, 0.0)
      assert lighter.rgb == {100, 100, 100}
    end

    test "factor 1 returns white" do
      ci = ColorInfo.new({100, 100, 100})
      lighter = ColorInfo.lighter(ci, 1.0)
      assert lighter.rgb == {255, 255, 255}
    end
  end

  describe "darker/2" do
    test "returns darker variant blended with black" do
      ci = ColorInfo.new({100, 100, 100})
      darker = ColorInfo.darker(ci, 0.5)
      assert darker.rgb == {50, 50, 50}
    end

    test "handles nil rgb with white default then blends with black" do
      ci = %ColorInfo{rgb: nil}
      darker = ColorInfo.darker(ci, 0.5)
      assert darker.rgb == {128, 128, 128}
    end

    test "factor 0 returns original color" do
      ci = ColorInfo.new({100, 100, 100})
      darker = ColorInfo.darker(ci, 0.0)
      assert darker.rgb == {100, 100, 100}
    end

    test "factor 1 returns black" do
      ci = ColorInfo.new({100, 100, 100})
      darker = ColorInfo.darker(ci, 1.0)
      assert darker.rgb == {0, 0, 0}
    end
  end

  describe "complementary/1" do
    test "returns complementary color" do
      ci = ColorInfo.new({255, 0, 0})
      comp = ColorInfo.complementary(ci)
      assert comp.rgb == {0, 255, 255}
    end

    test "complementary of cyan is red" do
      ci = ColorInfo.new({0, 255, 255})
      comp = ColorInfo.complementary(ci)
      assert comp.rgb == {255, 0, 0}
    end

    test "preserves other ColorInfo fields" do
      ci = ColorInfo.new({255, 0, 0})
      comp = ColorInfo.complementary(ci)
      assert comp.inverted == ci.inverted
    end
  end

  describe "analogous/2" do
    test "returns two analogous colors with default angle" do
      ci = ColorInfo.new({255, 0, 0})
      analogs = ColorInfo.analogous(ci)
      assert length(analogs) == 2
    end

    test "returns two analogous colors with custom angle" do
      ci = ColorInfo.new({255, 0, 0})
      analogs = ColorInfo.analogous(ci, 45.0)
      assert length(analogs) == 2
    end

    test "angle 0 returns same hue colors" do
      ci = ColorInfo.new({255, 0, 0})
      analogs = ColorInfo.analogous(ci, 0.0)
      assert length(analogs) == 2
    end
  end

  describe "triad/1" do
    test "returns two triad colors" do
      ci = ColorInfo.new({255, 0, 0})
      triad = ColorInfo.triad(ci)
      assert length(triad) == 2
    end

    test "triad colors are different from original" do
      ci = ColorInfo.new({255, 0, 0})
      triad = ColorInfo.triad(ci)
      Enum.each(triad, fn t -> assert t.rgb != {255, 0, 0} end)
    end
  end

  describe "color_info struct" do
    test "has all required fields with correct defaults" do
      ci = ColorInfo.new()
      assert ci.rgb == nil
      assert ci.hex == nil
      assert ci.format == nil
      assert ci.argb == nil
      assert ci.hsl == nil
      assert ci.hsv == nil
      assert ci.cmyk == nil
      assert ci.xterm256 == nil
      assert ci.name == nil
      assert ci.inverted == false
      assert ci.display == nil
    end

    test "creates ColorInfo with expected fields from atom" do
      ci = ColorInfo.new(:red)
      assert ci.rgb == {255, 0, 0}
      assert ci.name == :red
      assert ci.inverted == false
    end
  end

  describe "nearest_basic_color/1" do
    test "returns exact match for basic color" do
      assert ColorInfo.nearest_basic_color({255, 0, 0}) == :red
      assert ColorInfo.nearest_basic_color({0, 255, 0}) == :green
      assert ColorInfo.nearest_basic_color({0, 0, 255}) == :blue
    end

    test "returns nearest basic color for close approximation" do
      assert ColorInfo.nearest_basic_color({250, 10, 5}) == :red
    end

    test "returns bright variants when closer" do
      assert ColorInfo.nearest_basic_color({255, 100, 100}) == :bright_red
    end
  end
end
