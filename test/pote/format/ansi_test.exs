defmodule Pote.Format.ANSITest do
  use ExUnit.Case
  alias Pote.Format.ANSI

  describe "parse/1" do
    test "parses valid predefined explicit atom" do
      assert ANSI.parse(:red) == {:ok, :red}
    end

    test "parses valid predefined string converting to atom" do
      assert ANSI.parse("blue") == {:ok, :blue}
    end

    test "returns error for invalid strings or non-existing atoms" do
      assert ANSI.parse("nonexistent_ansi_color_magic") == :error
      assert ANSI.parse(:not_a_real_ansi_color) == :error
    end

    test "returns error for random types" do
      assert ANSI.parse(123) == :error
    end
  end

  describe "valid?/1" do
    test "validates proper existing atoms and strings" do
      assert ANSI.valid?(:green) == true
      assert ANSI.valid?("green") == true
    end

    test "invalidates random strings and atoms" do
      assert ANSI.valid?("invented_color_name") == false
      assert ANSI.valid?(:fake_color) == false
      assert ANSI.valid?({255, 0, 0}) == false
    end
  end

  describe "conversions" do
    setup do
      {:ok, ansi: :red}
    end

    test "to_rgb returns mapped tuple", %{ansi: ansi} do
      assert ANSI.to_rgb(ansi) == {255, 0, 0}
    end

    test "to_rgb returns default gray if missing" do
      assert ANSI.to_rgb(:nonexistent) == {128, 128, 128}
    end

    test "from_rgb approximates to closest ansi color" do
      # Exact match
      assert ANSI.from_rgb({255, 0, 0}) == :red
      # Approximation -> should be close to red
      assert ANSI.from_rgb({250, 10, 5}) == :red
    end

    test "to_hex translates color", %{ansi: ansi} do
      assert ANSI.to_hex(ansi) == "#FF0000"
    end

    test "to_argb injects alpha", %{ansi: ansi} do
      assert ANSI.to_argb(ansi) == {255, 255, 0, 0}
    end

    test "translates to spaces", %{ansi: ansi} do
      assert is_tuple(ANSI.to_hsl(ansi))
      assert is_tuple(ANSI.to_hsv(ansi))
      assert is_tuple(ANSI.to_cmyk(ansi))
      assert is_integer(ANSI.to_xterm256(ansi))
    end

    test "to_xterm256 has fallback for non-mapped aliases" do
      assert ANSI.to_xterm256(:nonexistent) == 245
    end
  end

  describe "metadata" do
    test "name/1 returns identical atom" do
      assert ANSI.name(:magenta) == :magenta
    end

    test "info/1 bundles transformations" do
      ansi = :green
      info = ANSI.info(ansi)

      assert info.format == :ansi
      assert info.original == ansi
      assert info.parsed == ansi
      assert info.rgb == {0, 255, 0}
      assert info.hex == "#00FF00"
      assert info.name == :green
    end
  end
end
