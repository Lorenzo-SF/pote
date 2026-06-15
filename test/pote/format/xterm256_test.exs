defmodule Pote.Format.XTerm256Test do
  use ExUnit.Case
  alias Pote.Format.XTerm256

  describe "parse/1" do
    test "parses integers directly" do
      assert XTerm256.parse(15) == {:ok, 15}
    end

    test "parses strings" do
      assert XTerm256.parse("15") == {:ok, 15}
    end

    test "returns error for boundaries" do
      assert XTerm256.parse(256) == :error
      assert XTerm256.parse(-1) == :error
      assert XTerm256.parse("300") == :error
      assert XTerm256.parse("invalid") == :error
    end

    test "returns error for random types" do
      assert XTerm256.parse(%{}) == :error
    end
  end

  describe "valid?/1" do
    test "validates proper ints and strings" do
      assert XTerm256.valid?(0) == true
      assert XTerm256.valid?(255) == true
      assert XTerm256.valid?("128") == true
    end

    test "invalidates out of bounds" do
      assert XTerm256.valid?(256) == false
      assert XTerm256.valid?(-1) == false
      assert XTerm256.valid?("256") == false
    end
  end

  describe "conversions" do
    setup do
      {:ok, xterm: 196}
    end

    test "to_rgb returns maps", %{xterm: xterm} do
      assert XTerm256.to_rgb(xterm) == {255, 0, 0}
    end

    test "from_rgb approximates", %{xterm: xterm} do
      assert XTerm256.from_rgb({255, 0, 0}) == xterm
    end

    test "to_hex translates color", %{xterm: xterm} do
      assert XTerm256.to_hex(xterm) == "#FF0000"
    end

    test "to_argb injects alpha", %{xterm: xterm} do
      assert XTerm256.to_argb(xterm) == {255, 255, 0, 0}
    end

    test "translates to spaces", %{xterm: xterm} do
      assert is_tuple(XTerm256.to_hsl(xterm))
      assert is_tuple(XTerm256.to_hsv(xterm))
      assert is_tuple(XTerm256.to_cmyk(xterm))
      assert XTerm256.to_xterm256(xterm) == xterm
    end
  end

  describe "metadata" do
    test "info/1 bundles transformations" do
      xterm = 196
      info = XTerm256.info(xterm)

      assert info.format == :xterm256
      assert info.original == xterm
      assert info.parsed == xterm
      assert info.rgb == {255, 0, 0}
      assert info.xterm256 == xterm
      assert info.name == nil
    end
  end
end
