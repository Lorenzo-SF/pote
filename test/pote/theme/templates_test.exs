defmodule Pote.Theme.TemplatesTest do
  use ExUnit.Case, async: true

  alias Pote.Theme.Templates

  describe "names/0" do
    test "returns the list of built-in templates" do
      names = Templates.names()
      assert "default" in names
      assert "dracula" in names
      assert "monokai" in names
      assert "nord" in names
      assert "light" in names
    end
  end

  describe "fetch/1" do
    test "returns the template on a hit" do
      assert {:ok, %Pote.Theme.Theme{name: "dracula"}} = Templates.fetch("dracula")
    end

    test "returns :error on a miss" do
      assert :error = Templates.fetch("not_a_real_theme")
    end
  end

  describe "all/0" do
    test "returns all templates as a map" do
      all = Templates.all()
      assert is_map(all)
      assert map_size(all) == 5
    end

    test "every template has well-formed colours" do
      Templates.all()
      |> Enum.each(fn {_name, theme} ->
        assert is_map(theme.colors)
        assert map_size(theme.colors) > 0

        Enum.each(theme.colors, fn {key, rgb} ->
          assert is_binary(key)
          assert {r, g, b} = rgb
          assert is_integer(r) and is_integer(g) and is_integer(b)
          assert r in 0..255 and g in 0..255 and b in 0..255
        end)
      end)
    end
  end
end