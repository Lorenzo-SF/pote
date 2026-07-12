defmodule Pote.Converters.GenericTest do
  use ExUnit.Case
  doctest Pote.Converters.Generic

  alias Pote.Converters.Generic
  alias Pote.Converters.Table
  alias Pote.ColorInfo

  describe "RGB conversions" do
    test "RGB → HSL conversion correctness" do
      table = Table.get()
      rgb = %ColorInfo{format: :rgb, rgb: {255, 0, 0}}
      assert {:ok, %ColorInfo{format: :hsl, hsl: {h, s, l}}} = Generic.convert(rgb, %ColorInfo{format: :hsl}, table)
      assert_in_delta h, 0.0, 0.1
      assert_in_delta s, 100.0, 0.1
      assert_in_delta l, 50.0, 0.1
    end

    test "HSL → RGB conversion correctness" do
      table = Table.get()
      hsl = %ColorInfo{format: :hsl, hsl: {0.0, 100.0, 50.0}}
      assert {:ok, %ColorInfo{format: :rgb, rgb: {r, g, b}}} = Generic.convert(hsl, %ColorInfo{format: :rgb}, table)
      assert r == 255
      assert g == 0
      assert b == 0
    end

    test "RGB → Hex conversion" do
      table = Table.get()
      rgb = %ColorInfo{format: :rgb, rgb: {255, 128, 0}}
      assert {:ok, %ColorInfo{format: :hex, hex: hex}} = Generic.convert(rgb, %ColorInfo{format: :hex}, table)
      assert hex == "#FF8000"
    end

    test "RGB → Hex round-trip" do
      table = Table.get()
      rgb = %ColorInfo{format: :rgb, rgb: {100, 150, 200}}
      assert {:ok, %ColorInfo{format: :hex, hex: hex}} = Generic.convert(rgb, %ColorInfo{format: :hex}, table)
      assert {:ok, %ColorInfo{format: :rgb, rgb: result}} = Generic.convert(%ColorInfo{format: :hex, hex: hex}, %ColorInfo{format: :rgb}, table)
      assert result == {100, 150, 200}
    end
  end

  describe "identity and edge cases" do
    test "identity conversion returns target struct unchanged" do
      table = Table.get()
      ci = %ColorInfo{format: :rgb, rgb: {255, 0, 0}}
      target = %ColorInfo{format: :rgb}
      assert {:ok, ^target} = Generic.convert(ci, target, table)
    end

    test "unsupported conversion returns error" do
      table = Table.get()
      rgb = %ColorInfo{format: :rgb, rgb: {255, 0, 0}}
      assert {:error, :unsupported} = Generic.convert(rgb, %ColorInfo{format: :argb}, table)
    end
  end
end
