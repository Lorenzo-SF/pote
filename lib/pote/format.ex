defmodule Pote.Format do
  @moduledoc """
  Behaviour for colour format handlers.

  This module defines the contract for all color format modules.
  It provides default implementations for common conversions based
  on `to_rgb/1`.

  Each colour format module (ANSI, Hex, RGB, ARGB, HSL, HSV, CMYK,
  XTerm256, Atom) implements this behaviour to provide a consistent
  interface for colour parsing, validation, and conversion to all
  supported colour spaces.

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
  Parsea un string o valor al formato específico.
  """
  @callback parse(any()) :: {:ok, any()} | {:error, String.t()}

  @doc """
  Convierte el formato a RGB.
  """
  @callback to_rgb(t()) :: Pote.rgb()

  @doc """
  Crea el formato desde RGB.
  """
  @callback from_rgb(Pote.rgb()) :: t()

  @doc """
  Valida si el valor es válido para este formato.
  Por defecto, retorna `true` si `parse/1` succeeds.
  """
  @callback valid?(any()) :: boolean()

  @doc """
  Convierte el formato a hexadecimal.
  Por defecto usa `to_rgb/1` y luego `Pote.Converters.RGB.to_hex/1`.
  """
  @callback to_hex(t()) :: String.t()

  @doc """
  Convierte el formato a ARGB {a, r, g, b}.
  Por defecto retorna {255, r, g, b}.
  """
  @callback to_argb(t()) :: {0..255, 0..255, 0..255, 0..255}

  @doc """
  Convierte el formato a HSL.
  Por defecto usa `to_rgb/1` y luego `Pote.Converters.RGB.to_hsl/1`.
  """
  @callback to_hsl(t()) :: Pote.hsl()

  @doc """
  Convierte el formato a HSV.
  Por defecto usa `to_rgb/1` y luego `Pote.Converters.RGB.to_hsv/1`.
  """
  @callback to_hsv(t()) :: Pote.hsv()

  @doc """
  Convierte el formato a CMYK.
  Por defecto usa `to_rgb/1` y luego `Pote.Converters.RGB.to_cmyk/1`.
  """
  @callback to_cmyk(t()) :: Pote.cmyk()

  @doc """
  Convierte el formato a XTerm256.
  Por defecto usa `to_rgb/1` y luego `Pote.Converters.RGB.to_xterm256/1`.
  """
  @callback to_xterm256(t()) :: Pote.xterm256()

  @doc """
  Retorna el nombre del color.
  Por defecto retorna `nil`.
  """
  @callback name(t()) :: String.t() | nil

  @doc """
  Retorna un mapa con toda la información del color.
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
  Helper para implementar `valid?/1` basándose en `parse/1`.
  """
  def valid_via_parse(module, input) do
    case module.parse(input) do
      {:ok, _} -> true
      _ -> false
    end
  end
end

# Pote.Format.Behaviour now simply aliases Pote.Format for backward compatibility
defmodule Pote.Format.Behaviour do
  @moduledoc """
  Alias de `Pote.Format` para backward compatibility.

  Los nuevos módulos deberían usar `use Pote.Format` en lugar de
  `use Pote.Format.Behaviour`.
  """

  # This module exists only for backward compatibility.
  # All implementations are in Pote.Format.
end
