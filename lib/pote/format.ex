defmodule Pote.Format do
  @moduledoc """
  Behaviour for color format handlers.

  This module defines the contract for all color format modules.
  It provides default implementations for common conversions based
  on `to_rgb/1`.

  Each color format module (ANSI, Hex, RGB, ARGB, HSL, HSV, CMYK,
  XTerm256, Atom) implements this behaviour to provide a consistent
  interface for color parsing, validation, and conversion to all
  supported color spaces.

  See `Pote.Format.RGB`, `Pote.Format.Hex`, `Pote.Format.HSL`, etc.
  for the built-in implementations.

  ## Usage with `use`

      defmodule MyFormat do
        use Pote.Format

        @impl true
        def parse(input), do: # ...
      end

  The `use Pote.Format` macro provides default implementations for
  `to_hex/1`, `to_argb/1`, `to_hsl/1`, `to_hsv/1`, `to_cmyk/1`,
  `to_xterm256/1`, `valid?/1`, `name/1`, and `info/1`.
  """

  # Type for the format state
  @type t :: any()

  # ============================================================================
  # Callbacks
  # ============================================================================

  @doc """
  Parses a string or value into the specific format.
  """
  @callback parse(any()) :: {:ok, any()} | {:error, String.t()}

  @doc """
  Converts the format to RGB.
  """
  @callback to_rgb(t()) :: Pote.rgb()

  @doc """
  Creates the format from RGB.
  """
  @callback from_rgb(Pote.rgb()) :: t()

  @doc """
  Validates whether the value is valid for this format.
  Defaults to returning `true` if `parse/1` succeeds.
  """
  @callback valid?(any()) :: boolean()

  @doc """
  Converts the format to hexadecimal.
  Defaults to using `to_rgb/1` and then `Pote.Converters.RGB.to_hex/1`.
  """
  @callback to_hex(t()) :: String.t()

  @doc """
  Converts the format to ARGB {a, r, g, b}.
  Defaults to returning {255, r, g, b}.
  """
  @callback to_argb(t()) :: {0..255, 0..255, 0..255, 0..255}

  @doc """
  Converts the format to HSL.
  Defaults to using `to_rgb/1` and then `Pote.Converters.RGB.to_hsl/1`.
  """
  @callback to_hsl(t()) :: Pote.hsl()

  @doc """
  Converts the format to HSV.
  Defaults to using `to_rgb/1` and then `Pote.Converters.RGB.to_hsv/1`.
  """
  @callback to_hsv(t()) :: Pote.hsv()

  @doc """
  Converts the format to CMYK.
  Defaults to using `to_rgb/1` and then `Pote.Converters.RGB.to_cmyk/1`.
  """
  @callback to_cmyk(t()) :: Pote.cmyk()

  @doc """
  Converts the format to XTerm256.
  Defaults to using `to_rgb/1` and then `Pote.Converters.RGB.to_xterm256/1`.
  """
  @callback to_xterm256(t()) :: Pote.xterm256()

  @doc """
  Returns the color name.
  Defaults to returning `nil`.
  """
  @callback name(t()) :: String.t() | nil

  @doc """
  Returns a map with all the information about the color.
  """
  @callback info(t()) :: map()

  # ============================================================================
  # Default implementations via `__using__`
  # ============================================================================

  defmacro __using__(_) do
    quote do
      alias Pote.Converters.RGB

      @behaviour Pote.Format

      # Required callbacks - must be implemented
      @impl true
      def parse(_), do: raise("parse/1 must be implemented")

      @impl true
      def to_rgb(_), do: raise("to_rgb/1 must be implemented")

      @impl true
      def from_rgb(_), do: raise("from_rgb/1 must be implemented")

      # Optional callbacks with default implementations
      @impl true
      def to_hex(color), do: color |> to_rgb() |> RGB.to_hex()

      @impl true
      def to_argb(color) do
        {r, g, b} = to_rgb(color)
        {255, r, g, b}
      end

      @impl true
      def to_hsl(color), do: color |> to_rgb() |> RGB.to_hsl()

      @impl true
      def to_hsv(color), do: color |> to_rgb() |> RGB.to_hsv()

      @impl true
      def to_cmyk(color), do: color |> to_rgb() |> RGB.to_cmyk()

      @impl true
      def to_xterm256(color), do: color |> to_rgb() |> RGB.to_xterm256()

      @impl true
      def valid?(input) do
        case parse(input) do
          {:ok, _} -> true
          _ -> false
        end
      end

      @impl true
      def name(_color), do: nil

      @impl true
      def info(color) do
        %{
          format: format_module(__MODULE__),
          original: color,
          parsed: color,
          rgb: to_rgb(color),
          hex: to_hex(color),
          argb: to_argb(color),
          hsl: to_hsl(color),
          hsv: to_hsv(color),
          cmyk: to_cmyk(color),
          xterm256: to_xterm256(color),
          name: name(color)
        }
      end

      defoverridable parse: 1,
                     to_rgb: 1,
                     from_rgb: 1,
                     to_hex: 1,
                     to_argb: 1,
                     to_hsl: 1,
                     to_hsv: 1,
                     to_cmyk: 1,
                     to_xterm256: 1,
                     valid?: 1,
                     name: 1,
                     info: 1

      defp format_module(module) do
        module
        |> Module.split()
        |> List.last()
        |> String.downcase()
        |> String.to_atom()
      end
    end
  end

  @doc """
  Helper to implement `valid?/1` based on `parse/1`.
  """
  def valid_via_parse(module, input) do
    case module.parse(input) do
      {:ok, _} -> true
      _ -> false
    end
  end
end
