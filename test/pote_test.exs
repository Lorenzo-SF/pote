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

  describe "theme_resolver/0 and put_theme_resolver/1" do
    test "default resolver returns :not_found for any key" do
      Pote.put_theme_resolver(nil)
      assert Pote.theme_resolver().("anything") == :not_found
    end

    test "put_theme_resolver/1 overrides the default" do
      Pote.put_theme_resolver(fn
        "custom" -> {:ok, {1, 2, 3}}
        _ -> :not_found
      end)

      try do
        assert Pote.theme_resolver().("custom") == {:ok, {1, 2, 3}}
        assert Pote.theme_resolver().("missing") == :not_found
      after
        Pote.put_theme_resolver(nil)
      end
    end

    test "put_theme_resolver(nil) restores the default" do
      Pote.put_theme_resolver(fn _ -> {:ok, {9, 9, 9}} end)
      Pote.put_theme_resolver(nil)
      assert Pote.theme_resolver().("custom") == :not_found
    end

    test "rejects non-function values" do
      assert_raise FunctionClauseError, fn ->
        Pote.put_theme_resolver("not a function")
      end
    end
  end

  describe "resolve_theme_color/1" do
    setup do
      Pote.put_theme_resolver(nil)
      on_exit(fn -> Pote.put_theme_resolver(nil) end)
      :ok
    end

    test "falls back to @default_colors when no resolver" do
      assert Pote.resolve_theme_color("primary") == {:ok, {161, 231, 250}}
      assert Pote.resolve_theme_color(:success) == {:ok, {151, 197, 60}}
    end

    test "returns :not_found for unknown keys" do
      assert Pote.resolve_theme_color("not_a_color") == :not_found
    end

    test "uses configured resolver when set" do
      Pote.put_theme_resolver(fn "ternary" -> {:ok, {255, 184, 108}} end)
      assert Pote.resolve_theme_color("ternary") == {:ok, {255, 184, 108}}
    end

    test "falls back to defaults when resolver returns :not_found" do
      Pote.put_theme_resolver(fn _ -> :not_found end)
      assert Pote.resolve_theme_color("primary") == {:ok, {161, 231, 250}}
    end

    test "resolver takes precedence over defaults" do
      Pote.put_theme_resolver(fn "primary" -> {:ok, {99, 99, 99}} end)
      assert Pote.resolve_theme_color("primary") == {:ok, {99, 99, 99}}
    end

    test "accepts both atom and string keys" do
      Pote.put_theme_resolver(fn "ternary" -> {:ok, {10, 20, 30}} end)
      assert Pote.resolve_theme_color(:ternary) == {:ok, {10, 20, 30}}
      assert Pote.resolve_theme_color("ternary") == {:ok, {10, 20, 30}}
    end
  end

  describe "parse/1 with theme: prefix" do
    setup do
      Pote.put_theme_resolver(nil)
      on_exit(fn -> Pote.put_theme_resolver(nil) end)
      :ok
    end

    test "theme:primary resolves to default color when no resolver" do
      assert {:ok, {161, 231, 250}} = Pote.parse("theme:primary")
    end

    test "BUG REPRO: theme:ternary uses active theme when resolver is set" do
      # This is the regression test for the Alaja theme bug.
      # When a custom resolver is registered (e.g. by Alaja), `theme:ternary`
      # should resolve via that resolver, NOT the hardcoded @default_colors.
      Pote.put_theme_resolver(fn "ternary" -> {:ok, {255, 184, 108}} end)
      assert {:ok, {255, 184, 108}} = Pote.parse("theme:ternary")
    end

    test "theme:unknown returns :error when nothing matches" do
      assert {:error, _} = Pote.parse("theme:totally_made_up")
    end
  end
end
