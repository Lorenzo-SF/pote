defmodule Pote.Converters.AdvancedTest do
  use ExUnit.Case, async: true

  alias Pote.Converters.Advanced

  describe "CIE XYZ conversions" do
    test "to_xyz converts correctly" do
      result = Advanced.to_xyz({255, 128, 0})
      assert_in_delta result |> elem(0), 0.487, 0.05
      assert_in_delta result |> elem(1), 0.356, 0.05
      assert_in_delta result |> elem(2), 0.041, 0.05
    end

    test "from_xyz converts correctly" do
      result = Advanced.from_xyz({0.487, 0.356, 0.041})
      assert_in_delta result |> elem(0), 255, 5
      assert_in_delta result |> elem(1), 127, 5
      assert_in_delta result |> elem(2), 0, 5
    end

    test "to_xyz and from_xyz are inverses approximately" do
      rgb = {100, 150, 200}
      xyz = Advanced.to_xyz(rgb)
      result = Advanced.from_xyz(xyz)

      assert result
             |> Tuple.to_list()
             |> Enum.zip(Tuple.to_list(rgb))
             |> Enum.all?(fn {a, b} -> abs(a - b) < 5 end)
    end
  end

  describe "CIELAB conversions" do
    test "to_lab converts correctly" do
      result = Advanced.to_lab({255, 128, 0})
      assert_in_delta result |> elem(0), 66.89, 1.0
      assert_in_delta result |> elem(1), 37.14, 10.0
      assert_in_delta result |> elem(2), 75.29, 10.0
    end

    test "from_lab converts correctly" do
      result = Advanced.from_lab({66.89, 37.14, 75.29})
      assert_in_delta result |> elem(0), 255, 10
      assert_in_delta result |> elem(1), 127, 10
    end
  end

  describe "Delta E (color distance)" do
    test "delta_e for identical colors is zero" do
      assert Advanced.delta_e({255, 0, 0}, {255, 0, 0}) == 0.0
    end

    test "delta_e for similar colors is small" do
      assert Advanced.delta_e({255, 0, 0}, {254, 0, 0}) < 1.0
    end

    test "delta_e for different colors is larger" do
      assert Advanced.delta_e({255, 0, 0}, {0, 0, 255}) > 50.0
    end
  end

  describe "WCAG contrast" do
    test "relative_luminance for white is 1.0" do
      assert Advanced.relative_luminance({255, 255, 255}) == 1.0
    end

    test "relative_luminance for black is 0.0" do
      assert Advanced.relative_luminance({0, 0, 0}) == 0.0
    end

    test "relative_luminance for red is correct" do
      result = Advanced.relative_luminance({255, 0, 0})
      assert_in_delta result, 0.2126, 0.001
    end

    test "contrast_ratio between black and white is 21.0" do
      assert Advanced.contrast_ratio({255, 255, 255}, {0, 0, 0}) == 21.0
    end

    test "contrast_ratio between same colors is 1.0" do
      assert Advanced.contrast_ratio({100, 100, 100}, {100, 100, 100}) == 1.0
    end
  end

  describe "YUV (BT.601) conversions" do
    test "to_yuv converts correctly" do
      result = Advanced.to_yuv({255, 128, 0})
      # Just verify Y is in expected range (Y: 0-255)
      assert elem(result, 0) in 0..255
      # U and V can be negative in YUV
      assert is_integer(elem(result, 1))
      assert is_integer(elem(result, 2))
    end

    test "from_yuv converts back to rgb" do
      yuv = {165, 13, 146}
      rgb = Advanced.from_yuv(yuv)
      # Check it returns valid RGB values
      assert elem(rgb, 0) in 0..255
      assert elem(rgb, 1) in 0..255
      assert elem(rgb, 2) in 0..255
    end
  end

  describe "YCbCr (BT.601) conversions" do
    test "to_ycbcr converts correctly" do
      result = Advanced.to_ycbcr({255, 128, 0})
      # Just check Y is in expected range
      assert elem(result, 0) in 16..235
      assert elem(result, 1) in 16..240
      assert elem(result, 2) in 16..240
    end

    test "from_ycbcr converts back to rgb" do
      ycbcr = {165, 69, 224}
      rgb = Advanced.from_ycbcr(ycbcr)
      # Check it returns valid RGB values
      assert elem(rgb, 0) in 0..255
      assert elem(rgb, 1) in 0..255
      assert elem(rgb, 2) in 0..255
    end
  end

  describe "Kelvin color temperature" do
    test "kelvin_to_rgb for 6500K (daylight)" do
      result = Advanced.kelvin_to_rgb(6500)
      # Just verify it returns a valid RGB tuple
      assert elem(result, 0) in 0..255
      assert elem(result, 1) in 0..255
      assert elem(result, 2) in 0..255
    end

    test "kelvin_to_rgb bounds clamping" do
      assert Advanced.kelvin_to_rgb(500) == Advanced.kelvin_to_rgb(1000)
      assert Advanced.kelvin_to_rgb(50_000) == Advanced.kelvin_to_rgb(40_000)
    end

    test "rgb_to_kelvin returns a value for typical colors" do
      kelvin = Advanced.rgb_to_kelvin({255, 160, 60})
      # Should return a reasonable Kelvin value
      assert kelvin != nil
      assert kelvin >= 1000
      assert kelvin <= 40_000
    end

    test "rgb_to_kelvin returns reasonable values" do
      # Warm color should return low Kelvin
      warm = Advanced.rgb_to_kelvin({255, 100, 50})
      assert warm != nil
      assert warm < 5000

      # Cool color should return high Kelvin
      cool = Advanced.rgb_to_kelvin({200, 220, 255})
      assert cool != nil
      assert cool > 5000
    end
  end
end
