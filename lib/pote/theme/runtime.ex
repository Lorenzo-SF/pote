defmodule Pote.Theme.Runtime do
  @moduledoc """
  Runtime theme operations for host modules using `Pote.Theme`.

  All functions in this module receive the host module as their first
  argument and call `host_module.config_app/0`, `host_module.storage_dir/0`,
  and `host_module.defaults/0` at runtime. This allows the host module
  to override `storage_dir/0` freely without any macro recompilation.
  """

  alias Pote.Theme.{Theme, Templates}

  @doc "Lists all themes available in `storage_dir`."
  @spec list(module()) :: [String.t()]
  def list(host_module) do
    Pote.Theme.list_themes(host_module.storage_dir())
  end

  @doc """
  Returns the active theme as a `Pote.Theme.Theme` struct.

  Reads `:theme_active` from the application's config, loads the
  JSON file, and returns the parsed theme. Falls back to the
  built-in `default` theme when no theme is selected or the
  active file is unreadable.
  """
  @spec active(module()) :: Theme.t()
  def active(host_module) do
    name = Application.get_env(host_module.config_app(), :theme_active, "default")

    case Pote.Theme.load_theme(name, host_module.storage_dir()) do
      {:ok, data} ->
        %Theme{
          name: data["name"] || name,
          description: data["description"],
          colors: Map.new(data["colors"] || %{}, fn {k, [r, g, b]} -> {k, {r, g, b}} end)
        }

      :not_found ->
        %Theme{name: name, description: "in-memory default", colors: host_module.defaults()}
    end
  end

  @doc "Returns the colour map for the active theme."
  @spec colors(module()) :: %{optional(String.t()) => Theme.rgb()}
  def colors(host_module) do
    active(host_module).colors
  end

  @doc """
  Looks up a single colour key in the active theme.

  Returns `{:ok, {r, g, b}}` on hit, `:not_found` on miss.
  """
  @spec color(module(), String.t()) :: {:ok, Theme.rgb()} | :not_found
  def color(host_module, key) when is_binary(key) do
    case Map.fetch(active(host_module).colors, key) do
      {:ok, _} = ok -> ok
      :error -> :not_found
    end
  end

  @doc "Activates a theme by name. Writes through to `:theme_active`."
  @spec activate(module(), String.t()) :: :ok
  def activate(host_module, name) when is_binary(name) do
    Application.put_env(host_module.config_app(), :theme_active, name)

    Pote.put_theme_resolver(
      Pote.Theme.resolver(
        config_app: host_module.config_app(),
        storage_dir: fn -> host_module.storage_dir() end
      )
    )

    :ok
  end

  @doc false
  @spec ensure_registered(module()) :: :ok
  def ensure_registered(host_module) do
    unless Process.get({host_module, :pote_registered}) do
      Pote.put_theme_resolver(
        Pote.Theme.resolver(
          config_app: host_module.config_app(),
          storage_dir: fn -> host_module.storage_dir() end
        )
      )

      Process.put({host_module, :pote_registered}, true)
    end

    :ok
  end

  @doc """
  Registers the resolver with `Pote` so `Pote.parse("theme:<key>")`
  and atom lookups consult this theme system. Idempotent.
  """
  @spec register_with_pote(module()) :: :ok
  def register_with_pote(host_module) do
    Pote.put_theme_resolver(
      Pote.Theme.resolver(
        config_app: host_module.config_app(),
        storage_dir: fn -> host_module.storage_dir() end
      )
    )

    :ok
  end

  @doc """
  Installs a theme to disk. Accepts a `Pote.Theme.Theme` struct.
  """
  @spec install!(module(), Theme.t()) :: :ok | {:error, term()}
  def install!(host_module, %Theme{} = theme) do
    Pote.Theme.save_theme(theme, host_module.storage_dir())
  end

  @doc """
  Installs a built-in template theme by name.

  Returns `:ok` if the template was installed, `{:error, :not_found}`
  if the template does not exist.
  """
  @spec install_template(module(), String.t()) :: :ok | {:error, term()}
  def install_template(host_module, name) when is_binary(name) do
    case Templates.fetch(name) do
      {:ok, theme} -> install!(host_module, theme)
      :error -> {:error, :not_found}
    end
  end

  @doc "Returns the list of built-in template theme names."
  @spec templates() :: [String.t()]
  def templates, do: Templates.names()
end
