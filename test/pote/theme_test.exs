defmodule Pote.ThemeTest do
  use ExUnit.Case

  alias Pote.Theme

  @tmp_dir Path.join(System.tmp_dir!(), "pote_theme_test_#{:erlang.unique_integer([:positive])}")

  setup do
    File.mkdir_p!(@tmp_dir)
    on_exit(fn -> File.rm_rf!(@tmp_dir) end)
    :ok
  end

  describe "save_theme/2 + load_theme/2 roundtrip" do
    test "writes and reads back a theme" do
      theme = %Pote.Theme.Theme{
        name: "custom_test",
        description: "test theme",
        colors: %{"primary" => {1, 2, 3}, "bg" => {10, 20, 30}}
      }

      assert :ok = Theme.save_theme(theme, @tmp_dir)
      assert {:ok, data} = Theme.load_theme("custom_test", @tmp_dir)
      assert data["name"] == "custom_test"
      assert data["description"] == "test theme"
      assert data["colors"]["primary"] == [1, 2, 3]
      assert data["colors"]["bg"] == [10, 20, 30]
    end
  end

  describe "list_themes/1" do
    test "returns empty when storage dir does not exist" do
      assert Theme.list_themes("/does/not/exist") == []
    end

    test "lists names without .json extension" do
      Theme.save_theme(
        %Pote.Theme.Theme{name: "a", colors: %{"k" => {1, 1, 1}}},
        @tmp_dir
      )

      Theme.save_theme(
        %Pote.Theme.Theme{name: "b", colors: %{"k" => {2, 2, 2}}},
        @tmp_dir
      )

      names = Theme.list_themes(@tmp_dir)
      assert "a" in names
      assert "b" in names
    end
  end

  describe "lookup/2 with a populated theme" do
    setup do
      Theme.save_theme(
        %Pote.Theme.Theme{
          name: "dracula",
          colors: %{"primary" => {189, 147, 249}, "accent" => {255, 121, 198}}
        },
        @tmp_dir
      )

      :ok
    end

    test "returns the rgb for known keys" do
      assert {:ok, {189, 147, 249}} =
               Theme.lookup("primary", storage_dir: @tmp_dir, theme_active: "dracula")

      assert {:ok, {255, 121, 198}} =
               Theme.lookup("accent", storage_dir: @tmp_dir, theme_active: "dracula")
    end

    test "returns :not_found for unknown keys" do
      assert :not_found = Theme.lookup("missing_key", storage_dir: @tmp_dir)
    end

    test "returns :not_found for missing theme" do
      assert :not_found = Theme.lookup("primary", storage_dir: "/does/not/exist")
    end
  end

  describe "resolver/1" do
    test "returns a closure that consults the storage dir" do
      Theme.save_theme(
        %Pote.Theme.Theme{name: "test", colors: %{"k" => {5, 6, 7}}},
        @tmp_dir
      )

      Application.put_env(:test_resolver_app, :theme_active, "test")
      on_exit(fn -> Application.delete_env(:test_resolver_app, :theme_active) end)

      resolver = Theme.resolver(config_app: :test_resolver_app, storage_dir: @tmp_dir)
      assert {:ok, {5, 6, 7}} = resolver.("k")
      assert :not_found = resolver.("missing")
    end
  end

  describe "use Pote.Theme generates a working module" do
    defmodule TestHostTheme do
      use Pote.Theme,
        config_app: :test_host_app,
        storage_dir: @tmp_dir,
        defaults: %{
          "primary" => {0, 0, 0},
          "accent" => {1, 1, 1}
        }
    end

    setup do
      Application.delete_env(:test_host_app, :theme_active)

      on_exit(fn ->
        Application.delete_env(:test_host_app, :theme_active)
        # Pop any resolvers this describe pushed onto the stack.
        while match?([_ | _], Pote.theme_resolvers()), do: Pote.put_theme_resolver(:pop)
      end)

      :ok
    end

    test "list/0 returns installed themes" do
      TestHostTheme.install!(%Pote.Theme.Theme{name: "x", colors: %{"k" => {1, 2, 3}}})
      assert "x" in TestHostTheme.list()
    end

    test "active/0 falls back to defaults when no theme is selected" do
      active = TestHostTheme.active()
      assert active.name == "default"
      assert active.colors == %{"primary" => {0, 0, 0}, "accent" => {1, 1, 1}}
    end

    test "active/0 reads from disk when a theme is selected" do
      TestHostTheme.install!(%Pote.Theme.Theme{name: "ocean", colors: %{"deep" => {10, 20, 30}}})
      TestHostTheme.activate("ocean")

      active = TestHostTheme.active()
      assert active.name == "ocean"
      assert active.colors == %{"deep" => {10, 20, 30}}
    end

    test "color/1 returns the colour from the active theme" do
      TestHostTheme.install!(%Pote.Theme.Theme{name: "ocean", colors: %{"deep" => {10, 20, 30}}})
      TestHostTheme.activate("ocean")

      assert {:ok, {10, 20, 30}} = TestHostTheme.color("deep")
    end

    test "color/1 returns :not_found for missing keys" do
      TestHostTheme.install!(%Pote.Theme.Theme{name: "ocean", colors: %{"deep" => {10, 20, 30}}})
      TestHostTheme.activate("ocean")

      assert :not_found = TestHostTheme.color("not_a_real_key")
    end

    test "register_with_pote/0 registers the resolver with Pote" do
      TestHostTheme.install!(%Pote.Theme.Theme{name: "t", colors: %{"key" => {42, 42, 42}}})
      TestHostTheme.activate("t")
      TestHostTheme.register_with_pote()

      assert {:ok, {42, 42, 42}} = Pote.resolve_theme_color("key")
    end

    test "install_template/1 ships built-in palettes" do
      assert :ok = TestHostTheme.install_template("dracula")
      assert "dracula" in TestHostTheme.list()
    end
  end
end
