defmodule Pote.Format.RGBTest do
  use ExUnit.Case
  alias Pote.Format.RGB

  describe "parse/1" do
    test "parses valid tuple" do
      assert RGB.parse({255, 128, 0}) == {:ok, {255, 128, 0}}
    end

    test "parses valid list" do
      assert RGB.parse([255, 128, 0]) == {:ok, {255, 128, 0}}
    end

    test "parses valid string" do
      assert RGB.parse("255, 128, 0") == {:ok, {255, 128, 0}}
      assert RGB.parse("10,20,30") == {:ok, {10, 20, 30}}
    end

    test "returns error for invalid boundaries" do
      assert RGB.parse({256, 0, 0}) == :error
      assert RGB.parse([-1, 0, 0]) == :error
      assert RGB.parse("300, 0, 0") == :error
    end

    test "returns error for malformed strings and other types" do
      assert RGB.parse("255,128") == :error
      assert RGB.parse("a,b,c") == :error
      assert RGB.parse(%{r: 255}) == :error
    end
  end

  describe "valid?/1" do
    test "validates proper bounds" do
      assert RGB.valid?({255, 128, 0}) == true
      assert RGB.valid?([255, 128, 0]) == true
    end

    test "invalidates out of bounds and wrong types" do
      assert RGB.valid?({256, 0, 0}) == false
      assert RGB.valid?([-1, 0, 0]) == false
      assert RGB.valid?("255, 0, 0") == false
    end
  end

  describe "conversions" do
    setup do
      {:ok, rgb: {255, 128, 0}}
    end

    test "to_rgb returns verbatim", %{rgb: rgb} do
      assert RGB.to_rgb(rgb) == {255, 128, 0}
    end

    test "from_rgb returns verbatim", %{rgb: rgb} do
      assert RGB.from_rgb(rgb) == {255, 128, 0}
    end

    test "to_hex delegates to Conversions", %{rgb: rgb} do
      assert RGB.to_hex(rgb) == "#FF8000"
    end

    test "to_argb injects alpha", %{rgb: {r, g, b}} do
      assert RGB.to_argb({r, g, b}) == {255, r, g, b}
    end

    test "to_hsl", %{rgb: rgb} do
      {h, s, l} = RGB.to_hsl(rgb)
      assert is_float(h)
      assert is_float(s)
      assert is_float(l)
    end

    test "to_hsv", %{rgb: rgb} do
      {h, s, v} = RGB.to_hsv(rgb)
      assert is_float(h)
      assert is_float(s)
      assert is_float(v)
    end

    test "to_cmyk", %{rgb: rgb} do
      {c, m, y, k} = RGB.to_cmyk(rgb)
      assert is_float(c)
      assert is_float(m)
      assert is_float(y)
      assert is_float(k)
    end

    test "to_xterm256", %{rgb: rgb} do
      assert is_integer(RGB.to_xterm256(rgb))
    end
  end

  describe "metadata" do
    test "name/1 returns nil" do
      assert RGB.name({255, 0, 0}) == nil
    end

    test "info/1 bundles transformations" do
      rgb = {255, 0, 0}
      info = RGB.info(rgb)

      assert info.format == :rgb
      assert info.original == rgb
      assert info.parsed == rgb
      assert info.rgb == rgb
      assert info.hex == "#FF0000"
      assert info.argb == {255, 255, 0, 0}
      assert info.name == nil
    end
  end
end
