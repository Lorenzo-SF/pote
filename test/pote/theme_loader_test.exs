defmodule Pote.ThemeLoaderTest do
  use ExUnit.Case
  alias Pote.Theme

  @valid_json ~s({"name":"mytheme","description":"A theme","colors":{"fg":[255,0,0],"bg":[30,30,46]}})

  describe "load_json/1" do
    test "parses a valid JSON binary into a Theme struct" do
      assert {:ok, %Pote.Theme.Theme{} = theme} = Theme.load_json(@valid_json)
      assert theme.name == "mytheme"
      assert theme.description == "A theme"
      assert theme.colors == %{"fg" => {255, 0, 0}, "bg" => {30, 30, 46}}
    end

    test "description is optional" do
      json = ~s({"name":"x","colors":{"fg":[1,2,3]}})
      assert {:ok, theme} = Theme.load_json(json)
      assert theme.name == "x"
      assert theme.description == nil
    end

    test "rejects malformed JSON" do
      assert {:error, %Pote.Error{kind: :invalid_theme, details: {:invalid_json, nil}}} =
               Theme.load_json("{not json")
    end

    test "rejects missing name" do
      json = ~s({"colors":{"fg":[1,2,3]}})
      assert {:error, %Pote.Error{kind: :invalid_theme}} = Theme.load_json(json)
    end

    test "rejects colors that are not a map" do
      json = ~s({"name":"x","colors":[1,2,3]})
      assert {:error, %Pote.Error{kind: :invalid_theme}} = Theme.load_json(json)
    end

    test "rejects invalid color tuples" do
      json = ~s({"name":"x","colors":{"fg":[1,2]}})

      assert {:error, %Pote.Error{kind: :invalid_theme, details: {{:invalid_color, "fg"}, nil}}} =
               Theme.load_json(json)
    end

    test "rejects out-of-range RGB values" do
      json = ~s({"name":"x","colors":{"fg":[300,0,0]}})
      assert {:error, %Pote.Error{kind: :invalid_theme}} = Theme.load_json(json)
    end

    test "accepts a single color_mode" do
      for mode <- ["auto", "truecolor", "xterm256"] do
        json = ~s({"name":"x","color_mode":"#{mode}","colors":{"fg":[1,2,3]}})
        assert {:ok, %Pote.Theme.Theme{}} = Theme.load_json(json)
      end
    end

    test "rejects color_mode both" do
      json = ~s({"name":"x","color_mode":"both","colors":{"fg":[1,2,3]}})
      assert {:error, %Pote.Error{kind: :invalid_theme}} = Theme.load_json(json)
    end

    test "rejects unknown color_mode values" do
      json = ~s({"name":"x","color_mode":"neon","colors":{"fg":[1,2,3]}})
      assert {:error, %Pote.Error{kind: :invalid_theme}} = Theme.load_json(json)
    end

    test "reads a theme from a file path" do
      tmp =
        Path.join(System.tmp_dir!(), "pote_loader_#{:erlang.unique_integer([:positive])}.json")

      File.write!(tmp, @valid_json)

      try do
        assert {:ok, theme} = Theme.load_json(tmp)
        assert theme.name == "mytheme"
      after
        File.rm!(tmp)
      end
    end

    test "reports unreadable paths" do
      assert {:error, %Pote.Error{kind: :invalid_theme, details: {:unreadable, _}}} =
               Theme.load_json("/nonexistent/path/theme.json")
    end

    test "round-trips through save_theme" do
      tmp_dir =
        Path.join(System.tmp_dir!(), "pote_loader_dir_#{:erlang.unique_integer([:positive])}")

      File.mkdir_p!(tmp_dir)

      try do
        theme = %Pote.Theme.Theme{
          name: "roundtrip",
          description: "round",
          colors: %{"primary" => {161, 231, 250}, "bg" => {40, 44, 52}}
        }

        assert :ok = Theme.save_theme(theme, tmp_dir)
        path = Path.join(tmp_dir, "roundtrip.json")
        assert {:ok, loaded} = Theme.load_json(path)
        assert loaded == theme
      after
        File.rm_rf!(tmp_dir)
      end
    end
  end

  describe "parse/1 and parse!/1" do
    test "parse is an alias of load_json" do
      assert {:ok, %Pote.Theme.Theme{}} = Theme.parse(@valid_json)
      assert {:error, %Pote.Error{kind: :invalid_theme}} = Theme.parse("{bad")
    end

    test "parse! returns the theme on success" do
      assert %Pote.Theme.Theme{name: "mytheme"} = Theme.parse!(@valid_json)
    end

    test "parse! raises Pote.Error on failure" do
      assert_raise Pote.Error, fn -> Theme.parse!("{bad") end
    end
  end
end
