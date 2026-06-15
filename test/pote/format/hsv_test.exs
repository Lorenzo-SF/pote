defmodule Pote.Format.HSVTest do
  use ExUnit.Case
  alias Pote.Format.HSV

  describe "parse/1" do
    test "parses valid tuple of floats/ints" do
      assert HSV.parse({360.0, 100.0, 100.0}) == {:ok, {360.0, 100.0, 100.0}}
      assert HSV.parse({360, 100, 100}) == {:ok, {360.0, 100.0, 100.0}}
    end

    test "parses valid list" do
      assert HSV.parse([180.0, 50.0, 50.0]) == {:ok, {180.0, 50.0, 50.0}}
    end

    test "parses valid string" do
      assert HSV.parse("180.0,50.0,50.0") == {:ok, {180.0, 50.0, 50.0}}
    end

    test "returns error for out of bounds" do
      assert HSV.parse({400.0, 100.0, 100.0}) == :error
      assert HSV.parse({180.0, 101.0, 100.0}) == :error
    end

    test "returns error for random" do
      assert HSV.parse("1,2") == :error
      assert HSV.parse(%{}) == :error
    end
  end

  describe "valid?/1" do
    test "validates proper bounds" do
      assert HSV.valid?({360.0, 100.0, 100.0}) == true
      assert HSV.valid?([0.0, 0.0, 0.0]) == true
    end

    test "invalidates out of bounds" do
      assert HSV.valid?({-1.0, 100.0, 100.0}) == false
      assert HSV.valid?([180.0, -0.1, 100.0]) == false
    end
  end

  describe "conversions" do
    setup do
      # Red
      {:ok, hsv: {0.0, 100.0, 100.0}}
    end

    test "to_rgb returns mapped tuple", %{hsv: hsv} do
      assert HSV.to_rgb(hsv) == {255, 0, 0}
    end

    test "from_rgb calculates hsv", %{hsv: hsv} do
      assert HSV.from_rgb({255, 0, 0}) == hsv
    end

    test "to_hex translates color", %{hsv: hsv} do
      assert HSV.to_hex(hsv) == "#FF0000"
    end

    test "to_hsv returns self", %{hsv: hsv} do
      assert HSV.to_hsv(hsv) == hsv
    end

    test "translates to spaces", %{hsv: hsv} do
      assert is_tuple(HSV.to_argb(hsv))
      assert is_tuple(HSV.to_hsl(hsv))
      assert is_tuple(HSV.to_cmyk(hsv))
      assert is_integer(HSV.to_xterm256(hsv))
    end
  end

  describe "metadata" do
    test "info/1 bundles transformations" do
      hsv = {0.0, 100.0, 100.0}
      info = HSV.info(hsv)

      assert info.format == :hsv
      assert info.original == hsv
      assert info.parsed == hsv
      assert info.rgb == {255, 0, 0}
    end
  end
end
