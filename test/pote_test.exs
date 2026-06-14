defmodule PoteTest do
  use ExUnit.Case

  describe "default_colors/0" do
    test "returns a map" do
      colors = Pote.default_colors()
      assert is_map(colors)
    end

    test "contains expected default colors" do
      colors = Pote.default_colors()
      assert colors.primary == {161, 231, 250}
      assert colors.success == {151, 197, 60}
      assert colors.error == {255, 91, 91}
    end
  end

  describe "get_color/1" do
    test "returns rgb tuple for existing color" do
      assert Pote.get_color(:primary) == {161, 231, 250}
      assert Pote.get_color(:success) == {151, 197, 60}
    end

    test "returns nil for nonexistent color" do
      assert Pote.get_color(:nonexistent_color_xyz) == nil
    end
  end

  describe "color_exists?/1" do
    test "returns true for existing color" do
      assert Pote.color_exists?(:primary) == true
      assert Pote.color_exists?(:success) == true
    end

    test "returns false for nonexistent color" do
      assert Pote.color_exists?(:nonexistent_color_xyz) == false
    end
  end

  describe "color_names/0" do
    test "returns list of atoms" do
      names = Pote.color_names()
      assert is_list(names)
      assert :primary in names
      assert :success in names
    end
  end

  describe "color/1" do
    test "is alias for get_color" do
      assert Pote.color(:primary) == Pote.get_color(:primary)
    end
  end
end
