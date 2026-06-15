defmodule Pote.Format.CMYKTest do
  use ExUnit.Case
  alias Pote.Format.CMYK

  describe "parse/1" do
    test "parses valid tuple of floats/ints" do
      assert CMYK.parse({0.0, 100.0, 100.0, 0.0}) == {:ok, {0.0, 100.0, 100.0, 0.0}}
      assert CMYK.parse({0, 100, 100, 0}) == {:ok, {0.0, 100.0, 100.0, 0.0}}
    end

    test "parses valid list" do
      assert CMYK.parse([50.0, 50.0, 50.0, 50.0]) == {:ok, {50.0, 50.0, 50.0, 50.0}}
    end

    test "parses valid string" do
      assert CMYK.parse("50.0,50.0,50.0,50.0") == {:ok, {50.0, 50.0, 50.0, 50.0}}
    end

    test "returns error for out of bounds" do
      assert CMYK.parse({101.0, 0.0, 0.0, 0.0}) == :error
      assert CMYK.parse({0.0, -0.1, 0.0, 0.0}) == :error
    end

    test "returns error for invalid parse" do
      assert CMYK.parse("1,2,3") == :error
      assert CMYK.parse(%{}) == :error
    end
  end

  describe "valid?/1" do
    test "validates proper bounds" do
      assert CMYK.valid?({0.0, 100.0, 100.0, 0.0})
      assert CMYK.valid?([0.0, 100.0, 100.0, 0.0])
    end

    test "invalidates out of bounds" do
      assert CMYK.valid?({-0.1, 0.0, 0.0, 0.0}) == false
      assert CMYK.valid?([200.0, 0.0, 0.0, 0.0]) == false
      assert CMYK.valid?("100.0, 100.0, 100.0, 100.0") == false
    end
  end

  describe "conversions" do
    setup do
      # Red
      {:ok, cmyk: {0.0, 100.0, 100.0, 0.0}}
    end

    test "to_rgb returns mapped tuple", %{cmyk: cmyk} do
      assert CMYK.to_rgb(cmyk) == {255, 0, 0}
    end

    test "from_rgb calculates cmyk", %{cmyk: cmyk} do
      assert CMYK.from_rgb({255, 0, 0}) == cmyk
    end

    test "to_hex translates color", %{cmyk: cmyk} do
      assert CMYK.to_hex(cmyk) == "#FF0000"
    end

    test "to_argb injects alpha", %{cmyk: cmyk} do
      assert CMYK.to_argb(cmyk) == {255, 255, 0, 0}
    end

    test "to_cmyk returns self", %{cmyk: cmyk} do
      assert CMYK.to_cmyk(cmyk) == cmyk
    end

    test "translates to spaces", %{cmyk: cmyk} do
      assert is_tuple(CMYK.to_hsl(cmyk))
      assert is_tuple(CMYK.to_hsv(cmyk))
      assert is_integer(CMYK.to_xterm256(cmyk))
    end
  end

  describe "metadata" do
    test "info/1 bundles transformations" do
      cmyk = {0.0, 100.0, 100.0, 0.0}
      info = CMYK.info(cmyk)

      assert info.format == :cmyk
      assert info.original == cmyk
      assert info.parsed == cmyk
      assert info.rgb == {255, 0, 0}
    end
  end
end
