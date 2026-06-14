defmodule Pote.Validator do
  @moduledoc """
  Validates color format values against their specification.

  ## Supported Formats

    - `hex:RRGGBB` - 6 hexadecimal characters (0-9, A-F, a-f)
    - `rgb:R,G,B` - Three integers 0-255
    - `argb:A,R,G,B` - Alpha 255, then R,G,B 0-255
    - `xterm:N` - Integer 0-255
    - `hsl:H,S,L` - H: 0-360 (degrees, 2 decimals), S/L: 0-100 (percentage, 4 decimals)
    - `hsv:H,S,V` - H: 0-360 (degrees, 2 decimals), S/V: 0-100 (percentage, 4 decimals)
    - `cmyk:C,M,Y,K` - Each 0-100 (percentage, 4 decimals)

  ## Usage

      iex> Pote.Validator.validate("hex:FF0000")
      :ok

      iex> Pote.Validator.validate("rgb:256,0,0")
      {:error, :rgb_value_out_of_range}

      iex> Pote.Validator.validate("hsl:370,50,50")
      {:error, :hue_out_of_range}
  """

  @type validation_result :: :ok | {:error, atom()} | {:error, atom(), String.t()}

  @doc """
  Validates a color input string with format prefix.

  Returns `:ok` if all values are valid, or `{:error, reason}` or `{:error, reason, detail}` if not.
  """
  @spec validate(String.t()) :: validation_result()
  def validate(input) when is_binary(input) do
    input = String.trim(input)

    if String.contains?(input, ":") do
      [format, code] = String.split(input, ":", parts: 2)
      validate_format(String.downcase(format), code)
    else
      validate_no_prefix(input)
    end
  end

  # ─── No prefix ───────────────────────────────────────────────────────────

  defp validate_no_prefix(input) do
    cond do
      String.match?(input, ~r/^#?[0-9A-Fa-f]{6}$/) -> :ok
      String.match?(input, ~r/^#?[0-9A-Fa-f]{3}$/) -> :ok
      String.match?(input, ~r/^[0-9]+$/) -> validate_xterm_value(input)
      true -> :ok
    end
  end

  # ─── Format-specific validation ────────────────────────────────────────────

  defp check_bracket_style(code, format) do
    if String.contains?(code, "{") or String.contains?(code, "}") do
      case format do
        "rgb" ->
          {:error, :rgb_uses_curly_braces, "Use rgb:R,G,B (parentheses), not rgb:{R,G,B}"}

        "argb" ->
          {:error, :argb_uses_curly_braces, "Use argb:A,R,G,B (parentheses), not argb:{A,R,G,B}"}

        "hsl" ->
          {:error, :hsl_uses_curly_braces, "Use hsl:H,S,L (parentheses), not hsl:{H,S,L}"}

        "hsv" ->
          {:error, :hsv_uses_curly_braces, "Use hsv:H,S,V (parentheses), not hsv:{H,S,V}"}

        "cmyk" ->
          {:error, :cmyk_uses_curly_braces, "Use cmyk:C,M,Y,K (parentheses), not cmyk:{C,M,Y,K}"}

        _ ->
          nil
      end
    else
      nil
    end
  end

  defp validate_format("hex", code) do
    code = String.replace(code, "#", "")

    if byte_size(code) == 6 and String.match?(code, ~r/^[0-9A-Fa-f]{6}$/) do
      :ok
    else
      {:error, :invalid_hex}
    end
  end

  defp validate_format("rgb", code) do
    if error = check_bracket_style(code, "rgb"), do: error, else: do_validate_rgb(code)
  end

  defp validate_format("argb", code) do
    if error = check_bracket_style(code, "argb"), do: error, else: do_validate_argb(code)
  end

  defp validate_format("hsl", code) do
    if error = check_bracket_style(code, "hsl"), do: error, else: do_validate_hsl(code)
  end

  defp validate_format("hsv", code) do
    if error = check_bracket_style(code, "hsv"), do: error, else: do_validate_hsv(code)
  end

  defp validate_format("cmyk", code) do
    if error = check_bracket_style(code, "cmyk"), do: error, else: do_validate_cmyk(code)
  end

  defp validate_format("hwb", code) do
    if error = check_bracket_style(code, "hwb"), do: error, else: do_validate_hwb(code)
  end

  defp validate_format("xterm", code) do
    validate_xterm_value(code)
  end

  defp validate_format("theme", color_name) do
    # Accept any valid atom as theme color name
    # The actual color will be looked up from theme at runtime
    color_name = String.trim(color_name)

    if color_name != "" and String.match?(color_name, ~r/^[a-zA-Z_][a-zA-Z0-9_]*$/) do
      :ok
    else
      {:error, :invalid_theme_color_name}
    end
  end

  defp validate_format(_unknown, _code), do: :ok

  defp do_validate_rgb(code) do
    parts = String.split(code, ",")

    if length(parts) != 3 do
      {:error, :rgb_wrong_part_count}
    else
      Enum.reduce_while(parts, :ok, fn part, :ok -> validate_rgb_part(part) end)
    end
  end

  defp do_validate_argb(code) do
    parts = String.split(code, ",")

    if length(parts) != 4 do
      {:error, :argb_wrong_part_count}
    else
      Enum.reduce_while(parts, :ok, fn part, :ok -> validate_argb_part(part) end)
    end
  end

  defp do_validate_hsl(code) do
    parts = String.split(code, ",")

    if length(parts) != 3 do
      {:error, :hsl_wrong_part_count}
    else
      [h_str, s_str, l_str] = parts

      with {:ok, _h} <- parse_hue(h_str),
           {:ok, _s} <- parse_percentage(s_str),
           {:ok, _l} <- parse_percentage(l_str) do
        :ok
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp do_validate_hsv(code) do
    parts = String.split(code, ",")

    if length(parts) != 3 do
      {:error, :hsv_wrong_part_count}
    else
      [h_str, s_str, v_str] = parts

      with {:ok, _h} <- parse_hue(h_str),
           {:ok, _s} <- parse_percentage(s_str),
           {:ok, _v} <- parse_percentage(v_str) do
        :ok
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp do_validate_cmyk(code) do
    parts = String.split(code, ",")

    if length(parts) != 4 do
      {:error, :cmyk_wrong_part_count}
    else
      Enum.reduce_while(parts, :ok, fn part, :ok -> validate_cmyk_part(part) end)
    end
  end

  defp do_validate_hwb(code) do
    parts = String.split(code, ",")

    if length(parts) != 3 do
      {:error, :hwb_wrong_part_count}
    else
      [h, w, b] = Enum.map(parts, &String.trim/1)

      with {:ok, _} <- parse_hue(h),
           {:ok, _} <- parse_normalized(w),
           {:ok, _} <- parse_normalized(b) do
        :ok
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp validate_rgb_part(part) do
    case Integer.parse(String.trim(part)) do
      {val, ""} when val in 0..255 -> {:cont, :ok}
      _ -> {:halt, {:error, :rgb_value_out_of_range}}
    end
  end

  defp validate_argb_part(part) do
    case Integer.parse(String.trim(part)) do
      {val, ""} when val in 0..255 -> {:cont, :ok}
      _ -> {:halt, {:error, :argb_value_out_of_range}}
    end
  end

  defp validate_cmyk_part(part) do
    case parse_percentage(String.trim(part)) do
      {:ok, _} -> {:cont, :ok}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  # ─── Value parsers ─────────────────────────────────────────────────────────

  # Hue: degrees 0-360, up to 2 decimal places
  defp parse_hue(str) do
    str = String.trim(str)

    str = String.replace(str, "°", "")

    case Float.parse(str) do
      {val, ""} ->
        if val >= 0 and val <= 360 and valid_decimals?(str, 2) do
          {:ok, val}
        else
          {:error, :hue_out_of_range}
        end

      _ ->
        {:error, :invalid_hue}
    end
  end

  # Normalized value: 0.0-1.0, up to 2 decimal places
  defp parse_normalized(str) do
    str = String.trim(str)

    case Float.parse(str) do
      {val, ""} ->
        if val >= 0 and val <= 1.0 and valid_decimals?(str, 2) do
          {:ok, val}
        else
          {:error, :ratio_out_of_range}
        end

      _ ->
        {:error, :invalid_ratio}
    end
  end

  # Percentage: 0-100, up to 2 decimal places
  defp parse_percentage(str) do
    str = String.trim(str)

    str = String.replace(str, "%", "")

    case Float.parse(str) do
      {val, ""} ->
        if val >= 0 and val <= 100.0 and valid_decimals?(str, 2) do
          {:ok, val}
        else
          {:error, :percentage_out_of_range}
        end

      _ ->
        {:error, :invalid_percentage}
    end
  end

  defp validate_xterm_value(str) do
    str = String.trim(str)

    case Integer.parse(str) do
      {val, ""} when val in 0..255 -> :ok
      _ -> {:error, :xterm_out_of_range}
    end
  end

  defp valid_decimals?(str, max_decimals) do
    if String.contains?(str, ".") do
      [_, dec] = String.split(str, ".")
      String.length(dec) <= max_decimals
    else
      true
    end
  end

  @doc """
  Returns a human-readable error message for a validation error.
  """
  @spec error_message(atom()) :: String.t()
  def error_message(:invalid_hex),
    do: "Hex color must be 6 hexadecimal characters (0-9, A-F)"

  def error_message(:rgb_value_out_of_range),
    do: "RGB values must be integers between 0 and 255"

  def error_message(:argb_value_out_of_range),
    do: "ARGB values must be integers between 0 and 255"

  def error_message(:xterm_out_of_range),
    do: "XTerm256 index must be between 0 and 255"

  def error_message(:hue_out_of_range),
    do: "Hue must be between 0.00 and 360.00 degrees"

  def error_message(:invalid_hue),
    do: "Hue must be a number between 0 and 360"

  def error_message(:percentage_out_of_range),
    do: "Percentage must be between 0 and 100"

  def error_message(:invalid_percentage),
    do: "Percentage must be a number between 0 and 100"

  def error_message(:hsl_wrong_part_count),
    do: "HSL format requires exactly 3 values: H,S,L"

  def error_message(:hsv_wrong_part_count),
    do: "HSV format requires exactly 3 values: H,S,V"

  def error_message(:cmyk_wrong_part_count),
    do: "CMYK format requires exactly 4 values: C,M,Y,K"

  def error_message(:hwb_wrong_part_count),
    do: "HWB format requires exactly 3 values: H,W,B"

  def error_message(:ratio_out_of_range),
    do: "HWB whiteness/blackness must be between 0.0 and 1.0"

  def error_message(:invalid_ratio),
    do: "HWB whiteness/blackness must be a number between 0.0 and 1.0"

  def error_message(:rgb_wrong_part_count),
    do: "RGB format requires exactly 3 values: R,G,B"

  def error_message(:argb_wrong_part_count),
    do: "ARGB format requires exactly 4 values: A,R,G,B"

  def error_message(:rgb_uses_curly_braces),
    do: "RGB format uses parentheses, not curly braces. Use rgb:R,G,B (e.g., rgb:255,0,0)"

  def error_message(:argb_uses_curly_braces),
    do:
      "ARGB format uses parentheses, not curly braces. Use argb:A,R,G,B (e.g., argb:255,255,0,0)"

  def error_message(:hsl_uses_curly_braces),
    do: "HSL format uses parentheses, not curly braces. Use hsl:H,S,L (e.g., hsl:120,50,50)"

  def error_message(:hsv_uses_curly_braces),
    do: "HSV format uses parentheses, not curly braces. Use hsv:H,S,V (e.g., hsv:120,50,100)"

  def error_message(:cmyk_uses_curly_braces),
    do: "CMYK format uses parentheses, not curly braces. Use cmyk:C,M,Y,K (e.g., cmyk:100,0,50,0)"

  def error_message(:unknown_color_format),
    do:
      "Unknown color format. Use a supported format like: hex:RRGGBB, rgb:R,G,B, argb:A,R,G,B, xterm:N, hsl:H,S,L, hsv:H,S,V, cmyk:C,M,Y,K, or plain hex/number"

  def error_message(reason), do: "Invalid color value: #{inspect(reason)}"
end
