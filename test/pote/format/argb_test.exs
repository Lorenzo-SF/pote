defmodule Pote.Format.ARGBTest do
  use ExUnit.Case
  alias Pote.Format.ARGB

  describe "parse/1" do
    test "parses valid tuple" do
      assert ARGB.parse({255, 128, 64, 0}) == {:ok, {255, 128, 64, 0}}
    end

    test "parses valid string" do
      assert ARGB.parse("255,128,64,0") == {:ok, {255, 128, 64, 0}}
    end

    test "returns error for boundaries" do
      assert ARGB.parse({256, 0, 0, 0}) == :error
      assert ARGB.parse({255, -1, 0, 0}) == :error
    end

    test "returns error for random" do
      assert ARGB.parse("255,128,64") == :error
      assert ARGB.parse(123) == :error
    end
  end

  describe "valid?/1" do
    test "validates proper bounds" do
      assert ARGB.valid?({255, 128, 64, 0}) == true
      assert ARGB.valid?([255, 128, 64, 0]) == true
    end

    test "invalidates out of bounds" do
      assert ARGB.valid?({256, 0, 0, 0}) == false
    end
  end

  describe "conversions" do
    setup do
      {:ok, argb: {255, 255, 0, 0}}
    end

    test "to_rgb drops alpha", %{argb: argb} do
      assert ARGB.to_rgb(argb) == {255, 0, 0}
    end

    test "from_rgb adds alpha", %{argb: argb} do
      assert ARGB.from_rgb({255, 0, 0}) == argb
    end

    test "translates to spaces", %{argb: argb} do
      assert ARGB.to_argb(argb) == argb
      assert is_binary(ARGB.to_hex(argb))
      assert is_tuple(ARGB.to_hsl(argb))
      assert is_tuple(ARGB.to_hsv(argb))
      assert is_tuple(ARGB.to_cmyk(argb))
      assert is_integer(ARGB.to_xterm256(argb))
    end
  end

  describe "metadata" do
    test "info/1 bundles transformations" do
      argb = {255, 255, 0, 0}
      info = ARGB.info(argb)

      assert info.format == :argb
      assert info.original == argb
      assert info.parsed == argb
      assert info.rgb == {255, 0, 0}
    end
  end
end
