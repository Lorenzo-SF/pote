defmodule Pote.Theme.RuntimeTest do
  use ExUnit.Case, async: false

  alias Pote.Theme.{Runtime, Theme}

  setup_all do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "pote_runtime_direct_test_#{:erlang.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)
    {:ok, tmp_dir: tmp_dir}
  end

  setup ctx do
    {:ok, tmp_dir: ctx.tmp_dir}
  end

  defmodule TestHost do
    def config_app, do: :test_runtime_app

    def storage_dir,
      do: Application.get_env(:test_runtime_app, :storage_dir, "/tmp/pote_runtime_default")

    def defaults, do: %{"primary" => {255, 0, 0}, "accent" => {0, 255, 0}}
  end

  setup do
    Application.delete_env(:test_runtime_app, :theme_active)
    Application.delete_env(:test_runtime_app, :storage_dir)

    on_exit(fn ->
      Application.delete_env(:test_runtime_app, :theme_active)
      Application.delete_env(:test_runtime_app, :storage_dir)
      pop_all_resolvers()
    end)

    :ok
  end

  defp pop_all_resolvers do
    case Pote.theme_resolvers() do
      [] ->
        :ok

      [_ | _] ->
        Pote.put_theme_resolver(:pop)
        pop_all_resolvers()
    end
  end

  describe "list/1" do
    test "returns empty when storage dir does not exist" do
      assert Runtime.list(TestHost) == []
    end

    test "lists installed themes", %{tmp_dir: tmp_dir} do
      Application.put_env(:test_runtime_app, :storage_dir, tmp_dir)

      Pote.Theme.save_theme(%Theme{name: "a", colors: %{"k" => {1, 1, 1}}}, tmp_dir)
      Pote.Theme.save_theme(%Theme{name: "b", colors: %{"k" => {2, 2, 2}}}, tmp_dir)

      names = Runtime.list(TestHost)
      assert "a" in names
      assert "b" in names
    end
  end

  describe "active/1" do
    test "falls back to defaults when no theme is selected", %{tmp_dir: tmp_dir} do
      Application.put_env(:test_runtime_app, :storage_dir, tmp_dir)
      Application.delete_env(:test_runtime_app, :theme_active)

      active = Runtime.active(TestHost)
      assert active.name == "default"
      assert active.colors["primary"] == {255, 0, 0}
      assert active.colors["accent"] == {0, 255, 0}
    end

    test "reads from disk when a theme is selected", %{tmp_dir: tmp_dir} do
      Application.put_env(:test_runtime_app, :storage_dir, tmp_dir)

      Pote.Theme.save_theme(
        %Theme{name: "ocean", colors: %{"deep" => {10, 20, 30}}},
        tmp_dir
      )

      Application.put_env(:test_runtime_app, :theme_active, "ocean")

      active = Runtime.active(TestHost)
      assert active.name == "ocean"
      assert active.colors["deep"] == {10, 20, 30}
    end
  end

  describe "color/2" do
    test "returns colour from active theme", %{tmp_dir: tmp_dir} do
      Application.put_env(:test_runtime_app, :storage_dir, tmp_dir)

      Pote.Theme.save_theme(
        %Theme{name: "ocean", colors: %{"deep" => {10, 20, 30}}},
        tmp_dir
      )

      Application.put_env(:test_runtime_app, :theme_active, "ocean")

      assert {:ok, {10, 20, 30}} = Runtime.color(TestHost, "deep")
    end

    test "returns :not_found for missing keys", %{tmp_dir: tmp_dir} do
      Application.put_env(:test_runtime_app, :storage_dir, tmp_dir)

      Pote.Theme.save_theme(
        %Theme{name: "ocean", colors: %{"deep" => {10, 20, 30}}},
        tmp_dir
      )

      Application.put_env(:test_runtime_app, :theme_active, "ocean")

      assert :not_found = Runtime.color(TestHost, "missing")
    end
  end

  describe "colors/1" do
    test "returns colour map from active theme", %{tmp_dir: tmp_dir} do
      Application.put_env(:test_runtime_app, :storage_dir, tmp_dir)

      Pote.Theme.save_theme(
        %Theme{name: "ocean", colors: %{"deep" => {10, 20, 30}}},
        tmp_dir
      )

      Application.put_env(:test_runtime_app, :theme_active, "ocean")

      assert %{"deep" => {10, 20, 30}} = Runtime.colors(TestHost)
    end
  end

  describe "activate/2" do
    test "sets theme_active and re-registers resolver", %{tmp_dir: tmp_dir} do
      Application.put_env(:test_runtime_app, :storage_dir, tmp_dir)

      Pote.Theme.save_theme(
        %Theme{name: "dracula", colors: %{"bg" => {0, 0, 0}}},
        tmp_dir
      )

      assert :ok = Runtime.activate(TestHost, "dracula")
      assert Application.get_env(:test_runtime_app, :theme_active) == "dracula"
    end
  end

  describe "ensure_registered/1" do
    test "registers resolver on first call" do
      assert :ok = Runtime.ensure_registered(TestHost)

      # Resolver should be registered now
      assert [_ | _] = Pote.theme_resolvers()
    end

    test "idempotent on repeated calls" do
      Runtime.ensure_registered(TestHost)
      initial_count = length(Pote.theme_resolvers())
      Runtime.ensure_registered(TestHost)
      assert length(Pote.theme_resolvers()) == initial_count
    end
  end

  describe "register_with_pote/1" do
    test "registers resolver" do
      assert :ok = Runtime.register_with_pote(TestHost)
      assert [_ | _] = Pote.theme_resolvers()
    end
  end

  describe "install!/2" do
    test "saves theme to disk", %{tmp_dir: tmp_dir} do
      Application.put_env(:test_runtime_app, :storage_dir, tmp_dir)

      theme = %Theme{name: "custom", colors: %{"k" => {1, 2, 3}}}
      assert :ok = Runtime.install!(TestHost, theme)

      assert {:ok, _} = Pote.Theme.load_theme("custom", tmp_dir)
    end
  end

  describe "install_template/2" do
    test "installs a known template", %{tmp_dir: tmp_dir} do
      Application.put_env(:test_runtime_app, :storage_dir, tmp_dir)

      assert :ok = Runtime.install_template(TestHost, "default")
      assert {:ok, _} = Pote.Theme.load_theme("default", tmp_dir)
    end

    test "returns error for unknown template" do
      assert {:error, :not_found} = Runtime.install_template(TestHost, "nonexistent")
    end
  end

  describe "templates/0" do
    test "returns list of template names" do
      names = Runtime.templates()
      assert is_list(names)
      assert "default" in names
      assert "dracula" in names
    end
  end
end
