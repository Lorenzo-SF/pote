defmodule Pote do
  @moduledoc """
  Pote — canonical color types, default palette, and top-level helpers.

  This module defines the core color type definitions used throughout the
  entire library and provides access to the built-in default color palette.
  """

  @type rgb :: {non_neg_integer(), non_neg_integer(), non_neg_integer()}
  @type hsl :: {float(), float(), float()}
  @type hsv :: {float(), float(), float()}
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
  Returns the configured theme resolver, or a default that returns `:not_found`.

  Applications embedding Pote (e.g. `Alaja`) can register a custom resolver
  to make `"theme:<key>"` lookups consult their own theme system:

      # In Alaja's startup:
      Application.put_env(:pote, :theme_resolver, fn key ->
        case Alaja.Config.lookup_theme_color(key) do
          {:ok, rgb} -> {:ok, rgb}
          :error -> :not_found
        end
      end)

  Pote itself ships with `@default_colors` and falls back to it when the
  custom resolver returns `:not_found`.
  """
  @spec theme_resolver() :: theme_resolver()
  def theme_resolver do
    Application.get_env(:pote, :theme_resolver, fn _key -> :not_found end)
  end

  @doc """
  Registers a theme resolver at runtime. Convenience over
  `Application.put_env/3` — useful in tests.

  Pass `nil` to restore the default (always `:not_found`) behaviour.
  """
  @spec put_theme_resolver(theme_resolver() | nil) :: :ok
  def put_theme_resolver(nil) do
    Application.delete_env(:pote, :theme_resolver)
    :ok
  end

  def put_theme_resolver(fun) when is_function(fun, 1) do
    Application.put_env(:pote, :theme_resolver, fun)
    :ok
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
      catch
        :error, _ -> nil
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
      {:ok, rgb} -> rgb
      {:error, reason} -> raise ArgumentError, "invalid color #{inspect(input)}: #{inspect(reason)}"
    end
  end
end
