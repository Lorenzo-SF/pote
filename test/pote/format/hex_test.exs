defmodule Pote.Format.HexTest do
  use ExUnit.Case
  alias Pote.Format.Hex

  describe "parse/1" do
    test "parses valid 7-char upper hex" do
      assert Hex.parse("#FF8000") == {:ok, "#FF8000"}
    end

    test "parses valid 7-char lower hex and upcases" do
      assert Hex.parse("#ff8000") == {:ok, "#FF8000"}
    end

    test "parses valid 6-char hex by prepending hash" do
      assert Hex.parse("FF8000") == {:ok, "#FF8000"}
      assert Hex.parse("ff8000") == {:ok, "#FF8000"}
    end

    test "returns error for invalid strings" do
      assert Hex.parse("#ZZYYXX") == :error
      assert Hex.parse("invalid") == :error
      assert Hex.parse(123) == :error
    end
  end

  describe "valid?/1" do
    test "validates proper string lengths" do
      assert Hex.valid?("#FF8000") == true
      # Visually, valid? logic in code checks byte_size == 6 or 7.
      assert Hex.valid?("FF8000") == true
    end

    test "invalidates wrong prefixes" do
      assert Hex.valid?("+FF8000") == false
    end

    test "invalidates random types" do
      assert Hex.valid?(%{}) == false
    end
  end

  describe "conversions" do
    setup do
      {:ok, hex: "#FF8000"}
    end

    test "to_rgb parses hex values", %{hex: hex} do
      assert Hex.to_rgb(hex) == {255, 128, 0}
    end

    test "from_rgb generates hex", %{hex: hex} do
      assert Hex.from_rgb({255, 128, 0}) == hex
    end

    test "from_rgb pads single digits" do
      assert Hex.from_rgb({1, 10, 255}) == "#010AFF"
    end

    test "to_hex returns verbatim", %{hex: hex} do
      assert Hex.to_hex(hex) == "#FF8000"
    end

    test "to_argb injects alpha", %{hex: hex} do
      assert Hex.to_argb(hex) == {255, 255, 128, 0}
    end

    test "translates through to_rgb", %{hex: hex} do
      assert is_tuple(Hex.to_hsl(hex))
      assert is_tuple(Hex.to_hsv(hex))
      assert is_tuple(Hex.to_cmyk(hex))
      assert is_integer(Hex.to_xterm256(hex))
    end
  end

  describe "metadata" do
    test "name/1 returns nil" do
      assert Hex.name("#FF0000") == nil
    end

    test "info/1 bundles transformations" do
      hex = "#FF0000"
      info = Hex.info(hex)

      assert info.format == :hex
      assert info.original == hex
      assert info.parsed == hex
      assert info.rgb == {255, 0, 0}
      assert info.hex == hex
      assert info.argb == {255, 255, 0, 0}
      assert info.name == nil
    end
  end
end
