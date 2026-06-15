defmodule Pote.Format.AtomTest do
  use ExUnit.Case
  alias Pote.Format.Atom

  describe "parse/1" do
    test "parses valid predefined semantic atom" do
      assert Atom.parse(:primary) == {:ok, :primary}
    end

    test "parses valid predefined string converting to atom" do
      assert Atom.parse("secondary") == {:ok, :secondary}
    end

    test "returns error for invalid strings avoiding atom exhaustion" do
      assert Atom.parse("nonexistent_semantic_color_12345") == :error
      assert Atom.parse(:not_a_real_color) == :error
    end

    test "returns error for random types" do
      assert Atom.parse(123) == :error
    end
  end

  describe "valid?/1" do
    test "validates proper existing semantic atoms and strings" do
      assert Atom.valid?(:success) == true
      assert Atom.valid?("error") == true
    end

    test "invalidates random strings and atoms" do
      assert Atom.valid?("invented_semantic_name") == false
      assert Atom.valid?(:fake_semantic) == false
      assert Atom.valid?({255, 0, 0}) == false
    end
  end

  describe "conversions" do
    setup do
      {:ok, atom: :primary}
    end

    test "to_rgb returns rgb tuple", %{atom: atom} do
      assert is_tuple(Atom.to_rgb(atom))
    end

    test "to_rgb returns default gray if missing" do
      assert Atom.to_rgb(:nonexistent) == {128, 128, 128}
    end

    test "from_rgb approximates to closest semantic color" do
      rgb = Atom.to_rgb(:primary)
      assert Atom.from_rgb(rgb) == :primary
    end

    test "to_hex translates color", %{atom: atom} do
      assert is_binary(Atom.to_hex(atom))
    end

    test "to_argb injects alpha", %{atom: atom} do
      {a, _r, _g, _b} = Atom.to_argb(atom)
      assert a == 255
    end

    test "translates to spaces", %{atom: atom} do
      assert is_tuple(Atom.to_hsl(atom))
      assert is_tuple(Atom.to_hsv(atom))
      assert is_tuple(Atom.to_cmyk(atom))
      assert is_integer(Atom.to_xterm256(atom))
    end
  end

  describe "metadata" do
    test "name/1 returns identical atom" do
      assert Atom.name(:warning) == :warning
    end

    test "info/1 bundles transformations" do
      atom = :info
      info = Atom.info(atom)

      assert info.format == :atom
      assert info.original == atom
      assert info.parsed == atom
      assert is_tuple(info.rgb)
      assert is_binary(info.hex)
      assert info.name == atom
    end
  end
end
