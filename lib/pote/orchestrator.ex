defmodule Pote.Orchestrator do
  @moduledoc """
  Color orchestration module for parsing, converting, and formatting colors.

  This module provides a unified interface for working with various color
  formats, converting between them, and generating ANSI escape codes.

  ## Supported Color Formats

  * RGB tuples: `{r, g, b}` where each value is 0-255
  * Hex strings: `"#RRGGBB"` or `"RRGGBB"`
  * HSL tuples: `{h, s, l}` where h is 0-360°, s and l are 0-100%
  * HSV tuples: `{h, s, v}` where h is 0-360°, s and v are 0-100%
  * CMYK tuples: `{c, m, y, k}` where each value is 0-100%
  * XTerm256: Integer 0-255
  * Atom colors: `:red`, `:green`, `:blue`, etc.
  * Named colors: `"red"`, `"green"`, `"blue"`, etc.

  Type aliases defined here reference the canonical types in `Pote`.

  ## Usage

      iex> Pote.Orchestrator.parse_color("#FF8000")
      {:ok, {255, 128, 0}}

      iex> Pote.Orchestrator.to_ansi({255, 128, 0})
      "\\e[38;2;255;128;0m"
  """

  alias Pote
  alias Pote.ColorInfo
  alias Pote.Conversions
  alias Pote.Validator

  @type rgb :: Pote.rgb()
  @type hex :: Pote.hex()
  @type hsl :: Pote.hsl()
  @type hsv :: Pote.hsv()
  @type cmyk :: Pote.cmyk()
  @type xterm256 :: Pote.xterm256()

  @type color_input :: Pote.color_input()
  @type color_output :: Pote.color_output()

  @named_colors %{
    # Basic colors
    black: {0, 0, 0},
    red: {255, 0, 0},
    green: {0, 255, 0},
    yellow: {255, 255, 0},
    blue: {0, 0, 255},
    magenta: {255, 0, 255},
    cyan: {0, 255, 255},
    white: {255, 255, 255},
    gray: {128, 128, 128},
    grey: {128, 128, 128},
    bright_black: {128, 128, 128},
    bright_red: {255, 128, 128},
    bright_green: {128, 255, 128},
    bright_yellow: {255, 255, 128},
    bright_blue: {128, 128, 255},
    bright_magenta: {255, 128, 255},
    bright_cyan: {128, 255, 255},
    bright_white: {255, 255, 255},
    light_black: {128, 128, 128},
    light_red: {255, 128, 128},
    light_green: {128, 255, 128},
    light_yellow: {255, 255, 128},
    light_blue: {128, 128, 255},
    light_magenta: {255, 128, 255},
    light_cyan: {128, 255, 255},
    light_white: {255, 255, 255},
    # Theme colors - loaded dynamically
    success: :theme_color,
    error: :theme_color,
    warning: :theme_color,
    info: :theme_color,
    debug: :theme_color,
    happy: :theme_color,
    sad: :theme_color,
    critical: :theme_color,
    alert: :theme_color
  }

  @supported_formats_msg """
  Supported formats:
    theme:<key>      — theme color (e.g. theme:primary)
    hex:<RRGGBB>     — hexadecimal (e.g. hex:FF0000 or #FF0000)
    rgb:<R,G,B>      — integers 0-255 (e.g. rgb:255,0,0)
    argb:<A,R,G,B>   — alpha + RGB integers 0-255
    hsl:<H,S,L>      — H=0-360, S/L=0-100 (e.g. hsl:120,50,50)
    hsv:<H,S,V>      — H=0-360, S/V=0-100 (e.g. hsv:120,50,100)
    cmyk:<C,M,Y,K>   — percentages 0-100 (e.g. cmyk:100,0,50,0)
    hwb:<H,W,B>      — H=0-360, W/B=0.0-1.0 (e.g. hwb:120,0.2,0.3)
    xterm:<N>        — index 0-255 (e.g. xterm:202)
    <name>           — named color: red, green, blue, cyan, magenta, yellow, white, black, gray
    <#RRGGBB>        — shorthand hex: #FF0000, #F00
  """

  @doc """
  Parses a color from various input formats.

  ## Parameters

  - `input` - Color in any supported format

  ## Returns

  - `{:ok, rgb}` - RGB tuple on success
  - `{:error, message}` - Error string with explanation

  ## Examples

      iex> Orchestrator.parse_color("#FF8000")
      {:ok, {255, 128, 0}}

      iex> Orchestrator.parse_color({30.0, 100.0, 50.0})
      {:ok, {255, 128, 0}}

      iex> Orchestrator.parse_color(:red)
      {:ok, {255, 0, 0}}

      iex> Orchestrator.parse_color("invalid")
      {:error, "Unknown color format. ..."}
  """
  @spec parse_color(color_input()) ::
          {:ok, rgb()} | {:error, String.t()}
  def parse_color(input) do
    case do_parse_color(input) do
      {:ok, _rgb} = result -> result
      {:error, msg} -> {:error, msg}
      :error -> {:error, "Unknown color format.\n" <> @supported_formats_msg}
    end
  end

  defp parse_rgb_tuple(r, g, b) do
    if r in 0..255 and g in 0..255 and b in 0..255 do
      {:ok, {r, g, b}}
    else
      :error
    end
  end

  defp parse_hsl_tuple(h, s, l) do
    if h >= 0 and h <= 360 and s >= 0 and s <= 100 and l >= 0 and l <= 100 do
      {:ok, Conversions.hsl_to_rgb({h * 1.0, s * 1.0, l * 1.0})}
    else
      :error
    end
  end

  defp parse_hsv_tuple(h, s, v) do
    if h >= 0 and h <= 360 and s >= 0 and s <= 100 and v >= 0 and v <= 100 do
      {:ok, Conversions.hsv_to_rgb({h * 1.0, s * 1.0, v * 1.0})}
    else
      :error
    end
  end

  defp parse_cmyk_tuple(c, m, y, k) do
    if c >= 0 and c <= 100 and m >= 0 and m <= 100 and y >= 0 and y <= 100 and k >= 0 and k <= 100 do
      {:ok, Conversions.cmyk_to_rgb({c * 1.0, m * 1.0, y * 1.0, k * 1.0})}
    else
      :error
    end
  end

  defp do_parse_color(input) when is_tuple(input), do: parse_tuple_color(input)

  defp do_parse_color(input) when is_binary(input) do
    input = String.trim(input)

    case parse_color_string(input) do
      {:error, _reason} -> {:error, :unknown_color_format}
      result -> result
    end
  end

  defp do_parse_color(input) when is_atom(input) do
    case Map.get(@named_colors, input) do
      nil -> resolve_theme_color(input)
      :theme_color -> resolve_theme_color(input)
      rgb -> {:ok, rgb}
    end
  end

  defp do_parse_color(_input), do: :error

  defp parse_tuple_color({r, g, b}) when is_integer(r) and is_integer(g) and is_integer(b) do
    parse_rgb_tuple(r, g, b)
  end

  defp parse_tuple_color({c, m, y, k})
       when is_number(c) and is_number(m) and is_number(y) and is_number(k) do
    parse_cmyk_tuple(c, m, y, k)
  end

  defp parse_tuple_color({h, s, l}) when is_float(h) or is_float(s) or is_float(l) do
    if h >= 0 and h <= 360 and s >= 0 and s <= 100 and l >= 0 and l <= 100 do
      parse_hsl_tuple(h, s, l)
    else
      parse_hsv_tuple(h, s, l)
    end
  end

  defp parse_tuple_color(_), do: :error

  defp resolve_theme_color(color_name) do
    case Pote.get_color(color_name) do
      nil -> {:error, :unknown_color_format}
      rgb -> {:ok, rgb}
    end
  end

  defp parse_color_string(<<"#"::utf8, _rest::binary>> = input) do
    # Validate hex format before converting
    case Validator.validate(input) do
      :ok -> Conversions.hex_to_rgb(input)
      {:error, _} = err -> err
    end
  end

  # Handle prefixed formats: rgb:R,G,B | hsl:H,S,L | hsv:H,S,V | cmyk:C,M,Y,K | hwb:H,W,B
  defp parse_color_string("hex:" <> code), do: parse_hex_string(code)
  defp parse_color_string("rgb:" <> code), do: parse_rgb_string(code)
  defp parse_color_string("argb:" <> code), do: parse_argb_string(code)
  defp parse_color_string("hsl:" <> code), do: parse_hsl_string(code)
  defp parse_color_string("hsv:" <> code), do: parse_hsv_string(code)
  defp parse_color_string("cmyk:" <> code), do: parse_cmyk_string(code)
  defp parse_color_string("hwb:" <> code), do: parse_hwb_string(code)
  defp parse_color_string("xterm:" <> code), do: parse_xterm_string(code)
  defp parse_color_string("theme:" <> code), do: parse_theme_color(code)

  defp parse_color_string(input), do: parse_color_string_fallback(input)

  defp parse_xterm_string(code) do
    code = String.trim(code)

    case Integer.parse(code) do
      {val, ""} when val in 0..255 ->
        {:ok, Conversions.xterm256_to_rgb(val)}

      _ ->
        {:error, "xterm value must be an integer 0-255. Example: xterm:202"}
    end
  end

  # Parse theme color name (e.g., "theme:primary" -> lookup in theme colors)
  defp parse_theme_color(color_name) do
    color_name = String.trim(color_name)

    if color_name == "" do
      {:error, "theme color name cannot be empty. Example: theme:primary"}
    else
      color_atom = String.to_atom(color_name)

      case Pote.get_color(color_atom) do
        nil -> {:error, "theme color '#{color_name}' not found. Example: theme:primary"}
        rgb -> {:ok, rgb}
      end
    end
  end

  # Parse hex string (with or without #)
  defp parse_hex_string(code) do
    code = String.replace(code, "#", "")
    code = String.trim(code)

    if String.match?(code, ~r/^[0-9A-Fa-f]{6}$/) or String.match?(code, ~r/^[0-9A-Fa-f]{3}$/) do
      Conversions.hex_to_rgb(code)
    else
      {:error, "hex value must be 3 or 6 hexadecimal characters. Examples: hex:FF0000, hex:F00"}
    end
  end

  defp parse_rgb_string(code) do
    parts = String.split(code, ",")

    case parts do
      [r_str, g_str, b_str] ->
        with {r, ""} <- Integer.parse(String.trim(r_str)),
             {g, ""} <- Integer.parse(String.trim(g_str)),
             {b, ""} <- Integer.parse(String.trim(b_str)),
             true <- r in 0..255 and g in 0..255 and b in 0..255 do
          {:ok, {r, g, b}}
        else
          _ -> {:error, "rgb values must be three integers 0-255. Example: rgb:255,0,0"}
        end

      _ ->
        {:error, "rgb requires exactly 3 comma-separated values. Example: rgb:255,0,0"}
    end
  end

  defp parse_argb_string(code) do
    parts = String.split(code, ",")

    case parts do
      [_a_str, r_str, g_str, b_str] ->
        with {r, ""} <- Integer.parse(String.trim(r_str)),
             {g, ""} <- Integer.parse(String.trim(g_str)),
             {b, ""} <- Integer.parse(String.trim(b_str)),
             true <- r in 0..255 and g in 0..255 and b in 0..255 do
          {:ok, {r, g, b}}
        else
          _ ->
            {:error,
             "argb values must be four integers 0-255 (alpha ignored). Example: argb:255,255,0,0"}
        end

      _ ->
        {:error, "argb requires exactly 4 comma-separated values. Example: argb:255,255,0,0"}
    end
  end

  defp parse_hsl_string(code) do
    parts = String.split(code, ",")

    case parts do
      [h_str, s_str, l_str] ->
        with {h, ""} <- Float.parse(String.trim(h_str)),
             {s, ""} <- Float.parse(String.trim(s_str)),
             {l, ""} <- Float.parse(String.trim(l_str)),
             true <- h >= 0 and h <= 360,
             true <- s >= 0 and s <= 100,
             true <- l >= 0 and l <= 100 do
          {:ok, Conversions.hsl_to_rgb({h, s, l})}
        else
          _ -> {:error, "hsl values must be H=0-360, S=0-100, L=0-100. Example: hsl:120,50,50"}
        end

      _ ->
        {:error, "hsl requires exactly 3 comma-separated values. Example: hsl:120,50,50"}
    end
  end

  defp parse_hsv_string(code) do
    parts = String.split(code, ",")

    case parts do
      [h_str, s_str, v_str] ->
        with {h, ""} <- Float.parse(String.trim(h_str)),
             {s, ""} <- Float.parse(String.trim(s_str)),
             {v, ""} <- Float.parse(String.trim(v_str)),
             true <- h >= 0 and h <= 360,
             true <- s >= 0 and s <= 100,
             true <- v >= 0 and v <= 100 do
          {:ok, Conversions.hsv_to_rgb({h, s, v})}
        else
          _ -> {:error, "hsv values must be H=0-360, S=0-100, V=0-100. Example: hsv:120,50,100"}
        end

      _ ->
        {:error, "hsv requires exactly 3 comma-separated values. Example: hsv:120,50,100"}
    end
  end

  defp parse_cmyk_string(code) do
    parts = String.split(code, ",")

    case parts do
      [c_str, m_str, y_str, k_str] ->
        with {c, ""} <- Float.parse(String.trim(c_str)),
             {m, ""} <- Float.parse(String.trim(m_str)),
             {y, ""} <- Float.parse(String.trim(y_str)),
             {k, ""} <- Float.parse(String.trim(k_str)),
             true <- c >= 0 and c <= 100,
             true <- m >= 0 and m <= 100,
             true <- y >= 0 and y <= 100,
             true <- k >= 0 and k <= 100 do
          {:ok, Conversions.cmyk_to_rgb({c, m, y, k})}
        else
          _ -> {:error, "cmyk values must be C,M,Y,K = 0-100. Example: cmyk:100,0,50,0"}
        end

      _ ->
        {:error, "cmyk requires exactly 4 comma-separated values. Example: cmyk:100,0,50,0"}
    end
  end

  defp parse_hwb_string(code) do
    parts = String.split(code, ",")

    case parts do
      [h_str, w_str, b_str] ->
        with {h, ""} <- Float.parse(String.trim(h_str)),
             {w, ""} <- Float.parse(String.trim(w_str)),
             {b, ""} <- Float.parse(String.trim(b_str)),
             true <- h >= 0 and h <= 360,
             true <- w >= 0 and w <= 1.0,
             true <- b >= 0 and b <= 1.0 do
          {:ok, Conversions.hwb_to_rgb({h, w, b})}
        else
          _ ->
            {:error, "hwb values must be H=0-360, W=0.0-1.0, B=0.0-1.0. Example: hwb:120,0.2,0.3"}
        end

      _ ->
        {:error, "hwb requires exactly 3 comma-separated values. Example: hwb:120,0.2,0.3"}
    end
  end

  defp parse_color_string_fallback(input) do
    cond do
      # Bare xterm number (0-255) - must check before hex since "232" looks like valid hex
      String.match?(input, ~r/^\d+$/) ->
        case Integer.parse(input) do
          {val, ""} when val in 0..255 ->
            {:ok, Conversions.xterm256_to_rgb(val)}

          _ ->
            {:error, "xterm value must be an integer 0-255. Example: xterm:202"}
        end

      # Hex 6 chars
      String.match?(input, ~r/^[0-9A-Fa-f]{6}$/) ->
        Conversions.hex_to_rgb(input)

      # Hex 3 chars
      String.match?(input, ~r/^[0-9A-Fa-f]{3}$/) ->
        Conversions.hex_to_rgb(input)

      # Named colors
      true ->
        parse_named_color(input)
    end
  end

  defp parse_named_color(input) do
    atom = String.to_existing_atom(input)

    case do_parse_color(atom) do
      {:ok, rgb} ->
        {:ok, rgb}

      _ ->
        {:error,
         "Unknown color '#{input}'. Use a named color (red, green, blue...) or a supported format.\n" <>
           @supported_formats_msg}
    end
  rescue
    ArgumentError ->
      {:error,
       "Unknown color '#{input}'. Use a named color (red, green, blue...) or a supported format.\n" <>
         @supported_formats_msg}
  end

  @doc """
  Converts any color format to RGB tuple.

  ## Parameters

  - `input` - Color in any supported format

  ## Returns

  - `{:ok, rgb}` - RGB tuple on success
  - `{:error, reason}` - Error tuple if conversion fails

  ## Examples

      iex> Orchestrator.to_rgb("#FF8000")
      {:ok, {255, 128, 0}}

      iex> Orchestrator.to_rgb(:red)
      {:ok, {255, 0, 0}}

      iex> Orchestrator.to_rgb({30.0, 100.0, 50.0})
      {:ok, {255, 128, 0}}
  """
  @spec to_rgb(color_input()) :: {:ok, rgb()} | {:error, String.t()}
  def to_rgb(input), do: parse_color(input)

  @doc """
  Converts any color format to RGB tuple (raises on error).

  ## Parameters

  - `input` - Color in any supported format

  ## Returns

  - RGB tuple

  ## Examples

      iex> Orchestrator.to_rgb!("#FF8000")
      {255, 128, 0}

      iex> Orchestrator.to_rgb!(:red)
      {255, 0, 0}
  """
  @spec to_rgb!(color_input()) :: rgb()
  def to_rgb!(input) do
    case to_rgb(input) do
      {:ok, rgb} -> rgb
      {:error, reason} -> raise ArgumentError, "failed to convert color: #{inspect(reason)}"
    end
  end

  @doc """
  Converts a color to its ANSI escape code for foreground.

  ## Parameters

  - `input` - Color in any supported format

  ## Returns

  - ANSI escape code string

  ## Examples

      iex> Orchestrator.to_ansi({255, 128, 0})
      "\\e[38;2;255;128;0m"

      iex> Orchestrator.to_ansi("#FF8000")
      "\\e[38;2;255;128;0m"

      iex> Orchestrator.to_ansi(nil)
      ""
  """
  @spec to_ansi(color_input() | nil) :: String.t()
  def to_ansi(nil), do: ""

  def to_ansi(input) do
    case to_rgb(input) do
      {:ok, {r, g, b}} -> "\e[38;2;#{r};#{g};#{b}m"
      {:error, _} -> ""
    end
  end

  @doc """
  Converts a color to its ANSI escape code for background.

  ## Parameters

  - `input` - Color in any supported format

  ## Returns

  - ANSI escape code string for background color

  ## Examples

      iex> Orchestrator.to_ansi_bg({255, 128, 0})
      "\\e[48;2;255;128;0m"
  """
  @spec to_ansi_bg(color_input() | nil) :: String.t()
  def to_ansi_bg(nil), do: ""

  def to_ansi_bg(input) do
    case to_rgb(input) do
      {:ok, {r, g, b}} -> "\e[48;2;#{r};#{g};#{b}m"
      {:error, _} -> ""
    end
  end

  @doc """
  Converts a color to XTerm256 index.

  ## Parameters

  - `input` - Color in any supported format

  ## Returns

  - `{:ok, xterm256}` - XTerm256 index on success
  - `{:error, reason}` - Error tuple if conversion fails

  ## Examples

      iex> Orchestrator.to_xterm256({255, 128, 0})
      {:ok, 208}

      iex> Orchestrator.to_xterm256("#FF8000")
      {:ok, 208}
  """
  @spec to_xterm256(color_input()) :: {:ok, xterm256()} | {:error, String.t()}
  def to_xterm256(input) do
    case to_rgb(input) do
      {:ok, rgb} -> {:ok, Conversions.rgb_to_xterm256(rgb)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns the list of supported named colors.

  ## Examples

      iex> Orchestrator.named_colors() |> Keyword.keys()
      [:black, :blue, :bright_black, ...]
  """
  @spec named_colors() :: keyword()
  def named_colors do
    @named_colors
    |> Enum.map(fn {k, v} -> {k, v} end)
  end

  @doc """
  Converts a color value to a `Pote.ColorInfo` struct.

  ## Parameters

  - `color` — Any supported color input: atom name, hex string, RGB tuple, etc.

  ## Returns

  - A `Pote.ColorInfo` struct populated with the color in all available formats.
    Returns an empty `ColorInfo` if the input cannot be parsed.

  ## Examples

      iex> Orchestrator.to_color_info(:red).rgb
      {255, 0, 0}

      iex> Orchestrator.to_color_info("#FF8000").hex
      "#FF8000"
  """
  @spec to_color_info(atom() | String.t() | tuple()) :: ColorInfo.t()
  def to_color_info(color) when is_atom(color) do
    case parse_color(color) do
      {:ok, rgb} -> %ColorInfo{rgb: rgb, name: color}
      {:error, _} -> ColorInfo.new()
    end
  end

  def to_color_info(color) do
    case parse_color(color) do
      {:ok, rgb} -> %ColorInfo{rgb: rgb}
      {:error, _} -> ColorInfo.new()
    end
  end
end
