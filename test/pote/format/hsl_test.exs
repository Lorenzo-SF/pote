defmodule Pote.Format.HSLTest do
  use ExUnit.Case
  alias Pote.Format.HSL

  describe "parse/1" do
    test "parses valid tuple of floats/ints" do
      assert HSL.parse({360.0, 100.0, 50.0}) == {:ok, {360.0, 100.0, 50.0}}
      assert HSL.parse({360, 100, 0}) == {:ok, {360.0, 100.0, 0.0}}
    end

    test "parses valid list" do
      assert HSL.parse([180.0, 50.0, 50.0]) == {:ok, {180.0, 50.0, 50.0}}
    end

    test "parses valid string" do
      assert HSL.parse("180.0,50.0,50.0") == {:ok, {180.0, 50.0, 50.0}}
    end

    test "returns error for out of bounds" do
      assert HSL.parse({361.0, 100.0, 100.0}) == :error
      assert HSL.parse({180.0, 101.0, 100.0}) == :error
    end

    test "returns error for random" do
      assert HSL.parse("1,2") == :error
      assert HSL.parse(%{}) == :error
    end
  end

  describe "valid?/1" do
    test "validates proper bounds" do
      assert HSL.valid?({360.0, 100.0, 100.0}) == true
      assert HSL.valid?([0.0, 0.0, 0.0]) == true
    end

    test "invalidates out of bounds" do
      assert HSL.valid?({-1.0, 100.0, 100.0}) == false
      assert HSL.valid?([180.0, -0.1, 100.0]) == false
    end
  end

  describe "conversions" do
    setup do
      # Red
      {:ok, hsl: {0.0, 100.0, 50.0}}
    end

    test "to_rgb returns mapped tuple", %{hsl: hsl} do
      assert HSL.to_rgb(hsl) == {255, 0, 0}
    end

    test "from_rgb calculates hsl", %{hsl: hsl} do
      assert HSL.from_rgb({255, 0, 0}) == hsl
    end

    test "to_hex translates color", %{hsl: hsl} do
      assert HSL.to_hex(hsl) == "#FF0000"
    end

    test "to_hsl returns self", %{hsl: hsl} do
      assert HSL.to_hsl(hsl) == hsl
    end

    test "translates to spaces", %{hsl: hsl} do
      assert is_tuple(HSL.to_argb(hsl))
      assert is_tuple(HSL.to_hsv(hsl))
      assert is_tuple(HSL.to_cmyk(hsl))
      assert is_integer(HSL.to_xterm256(hsl))
    end
  end

  describe "metadata" do
    test "info/1 bundles transformations" do
      hsl = {0.0, 100.0, 50.0}
      info = HSL.info(hsl)

      assert info.format == :hsl
      assert info.original == hsl
      assert info.parsed == hsl
      assert info.rgb == {255, 0, 0}
    end
  end
end
