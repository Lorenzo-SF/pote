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

  alias Pote.Validator.Bracket
  alias Pote.Validator.{CMYK, Hex, HSL, HWB, RGB, Theme, XTerm}

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
      String.match?(input, ~r/^[0-9]+$/) -> XTerm.validate(input)
      true -> :ok
    end
  end

  # ─── Format-specific validation ────────────────────────────────────────────

  defp validate_format("hex", code), do: Hex.validate(code)

  defp validate_format("rgb", code) do
    if error = Bracket.check_bracket_style(code, "rgb"), do: error, else: RGB.validate(code)
  end

  defp validate_format("argb", code) do
    if error = Bracket.check_bracket_style(code, "argb"), do: error, else: RGB.validate_argb(code)
  end

  defp validate_format("hsl", code) do
    if error = Bracket.check_bracket_style(code, "hsl"), do: error, else: HSL.validate(code)
  end

  defp validate_format("hsv", code) do
    if error = Bracket.check_bracket_style(code, "hsv"), do: error, else: HSL.validate_hsv(code)
  end

  defp validate_format("cmyk", code) do
    if error = Bracket.check_bracket_style(code, "cmyk"), do: error, else: CMYK.validate(code)
  end

  defp validate_format("hwb", code) do
    if error = Bracket.check_bracket_style(code, "hwb"), do: error, else: HWB.validate(code)
  end

  defp validate_format("xterm", code), do: XTerm.validate(code)
  defp validate_format("theme", color_name), do: Theme.validate(color_name)
  defp validate_format(_unknown, _code), do: :ok

  @doc """
  Returns a human-readable error message for a validation error.

  Delegates to per-format submodules when applicable. Bracket-style
  errors and the catch-all `unknown_color_format` / generic reason
  messages are handled directly here.
  """
  @spec error_message(atom()) :: String.t()
  def error_message(reason)

  def error_message(:invalid_hex), do: Hex.error_message(:invalid_hex)
  def error_message(:rgb_value_out_of_range), do: RGB.error_message(:rgb_value_out_of_range)
  def error_message(:argb_value_out_of_range), do: RGB.error_message(:argb_value_out_of_range)
  def error_message(:xterm_out_of_range), do: XTerm.error_message(:xterm_out_of_range)
  def error_message(:hue_out_of_range), do: HSL.error_message(:hue_out_of_range)
  def error_message(:invalid_hue), do: HSL.error_message(:invalid_hue)
  def error_message(:percentage_out_of_range), do: HSL.error_message(:percentage_out_of_range)
  def error_message(:invalid_percentage), do: HSL.error_message(:invalid_percentage)
  def error_message(:hsl_wrong_part_count), do: HSL.error_message(:hsl_wrong_part_count)
  def error_message(:hsv_wrong_part_count), do: HSL.error_message(:hsv_wrong_part_count)
  def error_message(:cmyk_wrong_part_count), do: CMYK.error_message(:cmyk_wrong_part_count)
  def error_message(:hwb_wrong_part_count), do: HWB.error_message(:hwb_wrong_part_count)
  def error_message(:ratio_out_of_range), do: HWB.error_message(:ratio_out_of_range)
  def error_message(:invalid_ratio), do: HWB.error_message(:invalid_ratio)
  def error_message(:rgb_wrong_part_count), do: RGB.error_message(:rgb_wrong_part_count)
  def error_message(:argb_wrong_part_count), do: RGB.error_message(:argb_wrong_part_count)
  def error_message(:invalid_theme_color_name), do: Theme.error_message(:invalid_theme_color_name)

  # Bracket-style errors are unique to the Bracket submodule and not worth a separate call
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
