defmodule Pote do
  @moduledoc """
  Pote — canonical color types, default palette, and top-level helpers.

  This module defines the core color type definitions used throughout the
  entire library and provides access to the built-in default color palette.
  """

  @type rgb :: {non_neg_integer(), non_neg_integer(), non_neg_integer()}
  @type hsl :: {float(), float(), float()}
  @type hsv :: {float(), float(), float()}
  @type hwb :: {float(), float(), float()}
  @type cmyk :: {float(), float(), float(), float()}
  @type hex :: String.t()
  @type xterm256 :: 0..255
  @type argb :: {non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer()}
  @type color_input :: rgb() | hex() | hsl() | hsv() | cmyk() | xterm256() | atom() | String.t()
  @type color_output :: rgb() | nil

  @default_colors %{
    primary: {161, 231, 250},
    secondary: {58, 171, 163},
    ternary: {255, 128, 0},
    quaternary: {155, 66, 226},
    no_color: {248, 248, 242},
    background: {40, 44, 52},
    success: {151, 197, 60},
    warning: {253, 216, 8},
    error: {255, 91, 91},
    info: {0, 255, 255},
    menu: {171, 205, 241},
    alert: {253, 216, 8},
    critical: {255, 91, 91},
    debug: {176, 176, 176},
    happy: {238, 128, 195},
    sad: {129, 161, 193},
    gradient_1: {161, 231, 250},
    gradient_2: {136, 192, 208},
    gradient_3: {129, 161, 193},
    gradient_4: {94, 129, 172},
    gradient_5: {76, 86, 106},
    gradient_6: {67, 76, 94}
  }

  @doc "Returns the default color palette."
  @spec default_colors() :: map()
  def default_colors, do: @default_colors

  @doc "Looks up a color by atom name. Returns RGB tuple or nil."
  @spec get_color(atom()) :: {integer(), integer(), integer()} | nil
  def get_color(name) do
    Map.get(@default_colors, name)
  end

  @doc "Checks if a color name exists in the default palette."
  @spec color_exists?(atom()) :: boolean()
  def color_exists?(name) do
    Map.has_key?(@default_colors, name)
  end

  @doc "Returns all available color names."
  @spec color_names() :: [atom()]
  def color_names do
    Map.keys(@default_colors)
  end

  @doc "Returns a specific color by name (alias for get_color/1)."
  @spec color(atom()) :: {integer(), integer(), integer()} | nil
  def color(name), do: get_color(name)

  @typedoc "A theme resolver: `(key :: String.t()) -> {:ok, rgb()} | :not_found`."
  @type theme_resolver :: (String.t() -> {:ok, rgb()} | :not_found)

  @doc """
  Returns a combined theme resolver that walks the registered stack.

  The combined resolver tries each registered resolver in order and
  returns the first non-`:not_found` result. If no resolver is
  registered, returns a default that always yields `:not_found`.

  Applications embedding Pote (e.g. `Alaja`) can register their own
  resolver to make `"theme:<key>"` lookups consult their theme system:

      # In Alaja's startup:
      Pote.put_theme_resolver(fn key ->
        case Alaja.Config.lookup_theme_color(key) do
          {:ok, rgb} -> {:ok, rgb}
          :error -> :not_found
        end
      end)

  Multiple resolvers may be registered; the first one to match wins.
  This is the recommended pattern when several apps / themes coexist
  (e.g. in tests for multiple consumers).
  """
  @spec theme_resolver() :: theme_resolver()
  def theme_resolver do
    case theme_resolvers() do
      [] -> fn _key -> :not_found end
      stack -> fn key -> walk_resolvers(stack, key) end
    end
  end

  defp walk_resolvers([], _key), do: :not_found

  defp walk_resolvers([resolver | rest], key) do
    case resolver.(key) do
      {:ok, _} = result -> result
      :not_found -> walk_resolvers(rest, key)
    end
  end

  @doc """
  Registers a theme resolver at runtime. Multiple resolvers can coexist
  in a stack — `resolve_theme_color/1` walks the stack and returns the
  first non-`:not_found` result. Useful when several apps / themes are
  loaded side-by-side (e.g. tests for multiple consumers).

  Pass `nil` to remove ALL resolvers.
  Pass `:pop` to remove the most recently registered one.
  Pass `:clear` as an alias for `nil`.
  """
  @spec put_theme_resolver(theme_resolver() | nil | :pop) :: :ok
  def put_theme_resolver(nil) do
    Application.delete_env(:pote, :theme_resolvers)
    :ok
  end

  def put_theme_resolver(:pop) do
    case Application.get_env(:pote, :theme_resolvers, []) do
      [] -> :ok
      [_ | rest] -> Application.put_env(:pote, :theme_resolvers, rest)
    end

    :ok
  end

  def put_theme_resolver(fun) when is_function(fun, 1) do
    stack = Application.get_env(:pote, :theme_resolvers, [])
    Application.put_env(:pote, :theme_resolvers, [fun | stack])
    :ok
  end

  @doc """
  Returns the current list of registered theme resolvers (newest first).

  The combined resolver returned by `theme_resolver/0` walks this list
  in order until one of them returns `{:ok, _}`.
  """
  @spec theme_resolvers() :: [theme_resolver()]
  def theme_resolvers do
    Application.get_env(:pote, :theme_resolvers, [])
  end

  @doc """
  Resolves a theme key (`"primary"`, `"ternary"`, ...) to an RGB tuple.

  Strategy (in order):
    1. The configured theme resolver (via `theme_resolver/0`).
    2. Pote's built-in `@default_colors`.

  Returns `{:ok, {r, g, b}}` or `:not_found`.
  """
  @spec resolve_theme_color(String.t() | atom()) :: {:ok, rgb()} | :not_found
  def resolve_theme_color(key) when is_atom(key) and not is_nil(key) do
    resolve_theme_color(Atom.to_string(key))
  end

  def resolve_theme_color(key) when is_binary(key) do
    case theme_resolver().(key) do
      {:ok, _} = result ->
        result

      :not_found ->
        resolve_default_color(key)
    end
  end

  def resolve_theme_color(_key), do: :not_found

  defp resolve_default_color(key) do
    atom_key =
      try do
        String.to_existing_atom(key)
      rescue
        ArgumentError -> nil
      end

    case atom_key && Map.get(@default_colors, atom_key) do
      nil -> :not_found
      rgb -> {:ok, rgb}
    end
  end

  @doc """
  Parses any color input to an RGB tuple.

  Accepts hex strings (`"#FF0000"`, `"FF0000"`), RGB tuples
  (`{255, 0, 0}`), HSL/HSV tuples, atom names (`:red`, `:blue`),
  and xterm256 integers (`0..255`).

  Delegates to `Pote.Orchestrator.parse_color/1`.

  Returns `{:ok, {r, g, b}}` on success, `{:error, reason}` on failure.
  """
  @spec parse(color_input()) :: {:ok, rgb()} | {:error, term()}
  defdelegate parse(input), to: Pote.Orchestrator, as: :parse_color

  @doc """
  Like `parse/1` but raises on error.
  """
  @spec parse!(color_input()) :: rgb()
  def parse!(input) do
    case parse(input) do
      {:ok, rgb} ->
        rgb

      {:error, reason} ->
        raise ArgumentError, "invalid color #{inspect(input)}: #{inspect(reason)}"
    end
  end
end
