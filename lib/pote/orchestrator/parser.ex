defmodule Pote.Orchestrator.Parser do
  @moduledoc """
  Parses color inputs from various formats into normalized RGB tuples.

  This module handles all color parsing, including string prefixes
  (`rgb:`, `hsl:`, `hsv:`, `cmyk:`, `hwb:`, `hex:`, `xterm:`, `theme:`),
  raw tuples, integers, atoms, and named colors.
  """

  alias Pote
  alias Pote.Colors.Basic
  alias Pote.Converters
  alias Pote.Validator

  @named_colors_overrides %{
    light_black: {128, 128, 128},
    light_red: {255, 128, 128},
    light_green: {128, 255, 128},
    light_yellow: {255, 255, 128},
    light_blue: {128, 128, 255},
    light_magenta: {255, 128, 255},
    light_cyan: {128, 255, 255},
    light_white: {255, 255, 255},
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
  """
  @spec parse_color(Pote.color_input()) ::
          {:ok, Pote.rgb()} | {:error, String.t()}
  def parse_color(input) do
    case do_parse_color(input) do
      {:ok, _rgb} = result -> result
      {:error, msg} -> {:error, msg}
      :error -> {:error, "Unknown color format.\n" <> @supported_formats_msg}
    end
  end

  # ── Internal dispatch ────────────────────────────────────────────

  @doc false
  def do_parse_color(input) when is_tuple(input), do: parse_tuple_color(input)

  def do_parse_color(input) when is_binary(input) do
    input = String.trim(input)

    case parse_color_string(input) do
      {:error, _reason} -> {:error, :unknown_color_format}
      result -> result
    end
  end

  def do_parse_color(input) when is_integer(input) and input in 0..255 do
    {:ok, Converters.xterm256_to_rgb(input)}
  end

  def do_parse_color(input) when is_atom(input) do
    case Map.get(named_colors_map(), input) do
      nil -> resolve_theme_color(input)
      :theme_color -> resolve_theme_color(input)
      rgb -> {:ok, rgb}
    end
  end

  def do_parse_color(_input), do: :error

  # ── Tuple parsing ────────────────────────────────────────────────

  defp parse_tuple_color({r, g, b}) when is_integer(r) and is_integer(g) and is_integer(b) do
    parse_rgb_tuple(r, g, b)
  end

  defp parse_tuple_color({c, m, y, k})
       when is_number(c) and is_number(m) and is_number(y) and is_number(k) do
    parse_cmyk_tuple(c, m, y, k)
  end

  defp parse_tuple_color({h, s, l}) when is_float(h) or is_float(s) or is_float(l) do
    {:error,
     "ambiguous 3-float tuple. Use the string form with an explicit prefix: \"hsl:#{h},#{s},#{l}\" or \"hsv:#{h},#{s},#{l}\""}
  end

  defp parse_tuple_color(_), do: :error

  defp parse_rgb_tuple(r, g, b) do
    if r in 0..255 and g in 0..255 and b in 0..255 do
      {:ok, {r, g, b}}
    else
      :error
    end
  end

  defp parse_cmyk_tuple(c, m, y, k) do
    if c >= 0 and c <= 100 and m >= 0 and m <= 100 and y >= 0 and y <= 100 and k >= 0 and k <= 100 do
      {:ok, Converters.cmyk_to_rgb({c * 1.0, m * 1.0, y * 1.0, k * 1.0})}
    else
      :error
    end
  end

  # ── String parsing ───────────────────────────────────────────────

  defp parse_color_string(<<"#"::utf8, _rest::binary>> = input) do
    case Validator.validate(input) do
      :ok -> Converters.hex_to_rgb(input)
      {:error, _} = err -> err
    end
  end

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

  defp parse_hex_string(code) do
    code = String.replace(code, "#", "")
    code = String.trim(code)

    if String.match?(code, ~r/^[0-9A-Fa-f]{6}$/) or String.match?(code, ~r/^[0-9A-Fa-f]{3}$/) do
      Converters.hex_to_rgb(code)
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
          {:ok, Converters.hsl_to_rgb({h, s, l})}
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
          {:ok, Converters.hsv_to_rgb({h, s, v})}
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
          {:ok, Converters.cmyk_to_rgb({c, m, y, k})}
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
          {:ok, Converters.hwb_to_rgb({h, w, b})}
        else
          _ ->
            {:error, "hwb values must be H=0-360, W=0.0-1.0, B=0.0-1.0. Example: hwb:120,0.2,0.3"}
        end

      _ ->
        {:error, "hwb requires exactly 3 comma-separated values. Example: hwb:120,0.2,0.3"}
    end
  end

  defp parse_xterm_string(code) do
    code = String.trim(code)

    case Integer.parse(code) do
      {val, ""} when val in 0..255 ->
        {:ok, Converters.xterm256_to_rgb(val)}

      _ ->
        {:error, "xterm value must be an integer 0-255. Example: xterm:202"}
    end
  end

  defp parse_theme_color(color_name) do
    color_name = String.trim(color_name)

    if color_name == "" do
      {:error, "theme color name cannot be empty. Example: theme:primary"}
    else
      case Pote.resolve_theme_color(color_name) do
        {:ok, rgb} -> {:ok, rgb}
        :not_found -> {:error, "theme color '#{color_name}' not found. Example: theme:primary"}
      end
    end
  end

  # ── Fallback parsing ─────────────────────────────────────────────

  defp parse_color_string_fallback(input) do
    cond do
      String.match?(input, ~r/^\d+$/) ->
        case Integer.parse(input) do
          {val, ""} when val in 0..255 ->
            {:ok, Converters.xterm256_to_rgb(val)}

          _ ->
            {:error, "xterm value must be an integer 0-255. Example: xterm:202"}
        end

      String.match?(input, ~r/^[0-9A-Fa-f]{6}$/) ->
        Converters.hex_to_rgb(input)

      String.match?(input, ~r/^[0-9A-Fa-f]{3}$/) ->
        Converters.hex_to_rgb(input)

      true ->
        parse_named_color(input)
    end
  end

  defp parse_named_color(input) do
    named_colors_map()

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

  # ── Named colors ─────────────────────────────────────────────────

  @doc false
  def resolve_theme_color(color_name) do
    case Pote.resolve_theme_color(color_name) do
      {:ok, _} = result -> result
      :not_found -> {:error, :unknown_color_format}
    end
  end

  @doc false
  def named_colors_map do
    case Application.get_env(:pote, :named_colors) do
      nil ->
        Basic.named_colors()
        |> Map.merge(@named_colors_overrides)

      custom when is_map(custom) ->
        custom

      _ ->
        Basic.named_colors()
        |> Map.merge(@named_colors_overrides)
    end
  end
end
