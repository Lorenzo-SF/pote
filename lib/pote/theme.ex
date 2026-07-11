defmodule Pote.Theme do
  alias Pote.Theme.Templates
  alias Pote.Theme.Theme

  @moduledoc """
  A theme system that any host application can opt into.

  `Pote.Theme` is the *core* contract: it defines a behaviour that
  host apps can adopt via `use Pote.Theme, ...` to get a fully
  functional theme system without writing any boilerplate.

  ## Quick start for host apps

      defmodule MyApp.Theme do
        use Pote.Theme,
          config_app: :my_app,
          storage_dir: "~/.config/my_app/themes",
          defaults: %{
            "primary" => {0, 120, 215},
            "accent" => {255, 90, 50},
            "background" => {24, 24, 28},
            "text" => {240, 240, 245}
          }
      end

  That's it — `MyApp.Theme` now exposes:

      MyApp.Theme.list()           # => ["default", "dracula", "monokai", ...]
      MyApp.Theme.active()         # => %Pote.Theme{...} (the active theme)
      MyApp.Theme.activate("dracula")
      MyApp.Theme.color("primary") # => {0, 120, 215}
      MyApp.Theme.colors()         # => %{"primary" => {0, 120, 215}, ...}
      MyApp.Theme.install!(MyApp.Theme.templates().dracula)

  ## Integration with Pote's color parser

  When a host app uses `use Pote.Theme`, the theme resolver is
  **automatically registered** with `Pote.put_theme_resolver/1` so
  that `Pote.parse("theme:primary")` (and `Pote.parse(:primary)`)
  consult the active theme — no extra wiring needed.

  This is the mechanism that makes `alaja separator --color "theme:primary"`,
  `Flotilla.Components.text("hi", color: "theme:primary")` and any
  other Pote-aware UI all read from the **same** active theme.

  ## On-disk format

  Each theme is a JSON file under `storage_dir`:

      {
        "name": "dracula",
        "description": "Dracula colour palette",
        "colors": {
          "primary": [189, 147, 249],
          "accent": [255, 121, 198],
          ...
        }
      }

  ## Built-in themes

  The default install (`use Pote.Theme`) ships with a small palette
  (`default`, `dracula`, `monokai`, `nord`, `light`) so the system
  is useful out of the box. Use `MyApp.Theme.templates/0` to inspect
  them and `MyApp.Theme.install!/2` to write them to disk.

  See `Pote.Theme.Templates` for the full list.
  """

  defmodule Theme do
    @moduledoc """
    The theme struct — name, optional description, and the colour map.

    `colors` is a map from string key to RGB tuple. Strings (not
    atoms) are used so themes roundtrip cleanly through JSON.
    """

    @type rgb :: {non_neg_integer(), non_neg_integer(), non_neg_integer()}

    @type t :: %__MODULE__{
            name: String.t(),
            description: String.t() | nil,
            colors: %{optional(String.t()) => rgb()}
          }

    @enforce_keys [:name, :colors]
    defstruct [:name, :description, colors: %{}]
  end

  @typedoc "A function that resolves a theme key to an RGB tuple."
  @type color_resolver :: (String.t() -> {:ok, Theme.rgb()} | :not_found)

  @doc """
  Looks up a theme key in the active theme for `config_app`.

  Reads `Application.get_env(config_app, :theme_active)` and looks
  up the corresponding theme file under `storage_dir`. Returns
  `{:ok, rgb}` on hit, `:not_found` on miss (key or theme absent).
  """
  @spec lookup(String.t(), keyword()) :: {:ok, Theme.rgb()} | :not_found
  def lookup(key, opts) when is_binary(key) and is_list(opts) do
    config_app = Keyword.get(opts, :config_app)
    storage_dir = Keyword.get(opts, :storage_dir)

    theme_active =
      if config_app,
        do: Application.get_env(config_app, :theme_active, "default"),
        else: Keyword.get(opts, :theme_active, "default")

    with {:ok, data} <- load_theme(theme_active, storage_dir),
         %{"colors" => colors} <- data do
      case Map.get(colors, key) do
        [r, g, b] when is_integer(r) and is_integer(g) and is_integer(b) ->
          {:ok, {r, g, b}}

        _ ->
          :not_found
      end
    else
      _ -> :not_found
    end
  end

  @doc """
  Returns a built-in resolver function that consults `config_app` +
  `storage_dir`. This is the function passed to `Pote.put_theme_resolver/1`.

  The `storage_dir` opt can be either a string (resolved once, at
  call time of `resolver/1`) or a 0-arity function (resolved on every
  lookup, so the underlying directory can change between calls). The
  generated `use Pote.Theme` module always passes a function so that
  `defoverridable storage_dir/0` overrides take effect at lookup
  time, not at registration time.
  """
  @spec resolver(keyword()) :: color_resolver()
  def resolver(opts) when is_list(opts) do
    storage_dir_opt = Keyword.get(opts, :storage_dir)
    resolved_opts = Keyword.delete(opts, :storage_dir)

    fn key ->
      opts_for_call =
        case storage_dir_opt do
          fun when is_function(fun, 0) -> Keyword.put(resolved_opts, :storage_dir, fun.())
          other -> Keyword.put(resolved_opts, :storage_dir, other)
        end

      lookup(key, opts_for_call)
    end
  end

  @doc """
  Loads a theme JSON file from `storage_dir`. Returns `{:ok, data}`
  with the parsed map, or `:not_found` if the file is missing or
  unreadable.
  """
  @spec load_theme(String.t(), String.t() | nil) :: {:ok, map()} | :not_found
  def load_theme(name, storage_dir) when is_binary(name) do
    dir = expand_path(storage_dir)

    if dir do
      path = Path.join(dir, "#{name}.json")

      with true <- File.exists?(path),
           {:ok, content} <- File.read(path),
           {:ok, data} <- safe_decode(content) do
        {:ok, data}
      else
        _ -> :not_found
      end
    else
      :not_found
    end
  end

  defp expand_path(nil), do: nil

  defp expand_path("~/" <> rest) do
    Path.join(System.user_home!(), rest)
  end

  defp expand_path(path), do: path

  defp safe_decode(content) do
    {:ok, _} = result = Jason.decode(content)
    result
  rescue
    _ -> :not_found
  catch
    _, _ -> :not_found
  end

  @doc """
  Writes a `Pote.Theme.Theme` struct to disk under `storage_dir`.

  Creates `storage_dir` if it does not exist. Returns `:ok` on
  success or `{:error, reason}` on failure.
  """
  @spec save_theme(Theme.t(), String.t() | nil) :: :ok | {:error, term()}
  def save_theme(%Theme{} = theme, storage_dir) do
    dir = expand_path(storage_dir) || ""

    with :ok <- File.mkdir_p(dir),
         path <- Path.join(dir, "#{theme.name}.json"),
         data <- %{
           "name" => theme.name,
           "description" => theme.description,
           "colors" => Map.new(theme.colors, fn {k, {r, g, b}} -> {k, [r, g, b]} end)
         },
         {:ok, json} <- Jason.encode(data, pretty: true),
         :ok <- Apero.File.IO.atomic_write(path, json) do
      :ok
    else
      err -> {:error, err}
    end
  end

  @doc """
  Lists theme names available in `storage_dir`.

  Returns only theme names (`"dracula"`, `"monokai"`, ...) without
  the `.json` extension. Themes without an on-disk file but
  available via `Pote.Theme.Templates` are not included.
  """
  @spec list_themes(String.t() | nil) :: [String.t()]
  def list_themes(storage_dir) do
    dir = expand_path(storage_dir)

    if dir && File.exists?(dir) do
      case File.ls(dir) do
        {:ok, files} ->
          files
          |> Enum.filter(&String.ends_with?(&1, ".json"))
          |> Enum.map(&String.trim_trailing(&1, ".json"))

        _ ->
          []
      end
    else
      []
    end
  end

  @doc """
  `use Pote.Theme` — the entry point for host apps.

  Accepts these options:

    * `:config_app` (required) — the OTP application name whose
      `:theme_active` env holds the active theme name.
    * `:storage_dir` (optional) — directory where theme JSONs live.
      Defaults to `"~/.config/<config_app>/themes"`.
    * `:defaults` (optional) — map of default theme colours used
      when no theme is selected or the active theme file is missing.

  Generates a module that exposes:

      list/0, active/0, activate/1, color/1, colors/0,
      install!/1, templates/0

  And automatically registers the resolver with Pote.
  """
  defmacro __using__(opts) do
    config_app = Keyword.fetch!(opts, :config_app)
    storage_dir = Keyword.get(opts, :storage_dir)
    defaults = opts |> Keyword.get(:defaults, %{}) |> eval_runtime_value()
    caller = __CALLER__.module
    defaults_ast = quote(do: unquote(Macro.escape(defaults)))
    default_storage_dir = storage_dir || "~/.config/#{config_app}/themes"

    quote do
      alias Pote.Theme.Templates
      alias Pote.Theme.Theme

      @config_app unquote(config_app)
      @storage_dir_default unquote(default_storage_dir)
      @defaults unquote(defaults_ast)

      @doc """
      Theme management facade for #{inspect(unquote(caller))}.

      Generated by `use Pote.Theme`. See `Pote.Theme` for the full
      contract.
      """
      def config_app, do: @config_app

      # storage_dir/0 is intentionally NOT defined here. The host
      # module must define it after `use Pote.Theme`:
      #
      #     def storage_dir, do: @storage_dir_default
      #
      # The default attribute `@storage_dir_default` is set to the
      # opt's value (or `"~/.config/<config_app>/themes"`). The host
      # is free to define `storage_dir/0` with any body, since the
      # generated functions all call `storage_dir()` (the host's
      # own definition) at runtime, never the attribute directly.

      @doc "Lists all themes available in `storage_dir`."
      @spec list() :: [String.t()]
      def list do
        ensure_registered()
        Pote.Theme.list_themes(storage_dir())
      end

      @doc """
      Returns the active theme as a `Pote.Theme.Theme` struct.

      Reads `:theme_active` from the application's config, loads the
      JSON file, and returns the parsed theme. Falls back to the
      built-in `default` theme when no theme is selected or the
      active file is unreadable.
      """
      @spec active() :: Theme.t()
      def active do
        ensure_registered()
        name = Application.get_env(@config_app, :theme_active, "default")

        case Pote.Theme.load_theme(name, storage_dir()) do
          {:ok, data} ->
            %Theme{
              name: data["name"] || name,
              description: data["description"],
              colors: Map.new(data["colors"] || %{}, fn {k, [r, g, b]} -> {k, {r, g, b}} end)
            }

          :not_found ->
            %Theme{name: name, description: "in-memory default", colors: @defaults}
        end
      end

      @doc "Returns the colour map for the active theme."
      @spec colors() :: %{
              optional(String.t()) => {non_neg_integer(), non_neg_integer(), non_neg_integer()}
            }
      def colors do
        ensure_registered()
        active().colors
      end

      @doc """
      Looks up a single colour key in the active theme.

      Returns `{:ok, {r, g, b}}` on hit, `:not_found` on miss.
      """
      @spec color(String.t()) ::
              {:ok, {non_neg_integer(), non_neg_integer(), non_neg_integer()}} | :not_found
      def color(key) when is_binary(key) do
        ensure_registered()

        case Map.fetch(active().colors, key) do
          {:ok, _} = ok -> ok
          :error -> :not_found
        end
      end

      @doc "Activates a theme by name. Writes through to `:theme_active`."
      @spec activate(String.t()) :: :ok
      def activate(name) when is_binary(name) do
        Application.put_env(@config_app, :theme_active, name)
        # Re-register in case the resolver captures the active name.
        Pote.put_theme_resolver(
          Pote.Theme.resolver(config_app: @config_app, storage_dir: fn -> storage_dir() end)
        )

        :ok
      end

      @doc false
      @spec ensure_registered() :: :ok
      def ensure_registered do
        case Pote.theme_resolver() do
          # default resolver returns :not_found for anything — register ours
          _ ->
            Pote.put_theme_resolver(
              Pote.Theme.resolver(config_app: @config_app, storage_dir: fn -> storage_dir() end)
            )
        end

        :ok
      end

      @doc """
      Registers the resolver with `Pote` so `Pote.parse("theme:<key>")`
      and atom lookups consult this theme system. Idempotent.
      """
      @spec register_with_pote() :: :ok
      def register_with_pote do
        Pote.put_theme_resolver(
          Pote.Theme.resolver(config_app: @config_app, storage_dir: fn -> storage_dir() end)
        )

        :ok
      end

      @doc """
      Installs a theme to disk. Accepts a `Pote.Theme.Theme` struct
      (or a name + map tuple via `install_template/2`).
      """
      @spec install!(Theme.t()) :: :ok | {:error, term()}
      def install!(%Theme{} = theme), do: Pote.Theme.save_theme(theme, storage_dir())

      @doc """
      Installs a built-in template theme by name.

      Returns `:ok` if the template was installed, `{:error, :not_found}`
      if the template does not exist.
      """
      @spec install_template(String.t()) :: :ok | {:error, term()}
      def install_template(name) when is_binary(name) do
        case Templates.fetch(name) do
          {:ok, theme} -> install!(theme)
          :error -> {:error, :not_found}
        end
      end

      @doc """
      Returns the list of built-in template theme names.
      """
      @spec templates() :: [String.t()]
      def templates, do: Templates.names()
    end
  end

  # Force a value (which may be either a runtime value or an AST tuple)
  # into a runtime value. AST tuples are recognised by their first
  # element being an atom like `%{}`, `{}`, `[]`, etc.
  defp eval_runtime_value(%_{} = m), do: m

  defp eval_runtime_value(other) do
    if is_tuple(other) and is_atom(elem(other, 0)) and tuple_size(other) >= 2 and
         is_list(elem(other, 1)) do
      {result, _} = Code.eval_quoted(other)
      result
    else
      other
    end
  end
end
