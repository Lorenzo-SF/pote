defmodule Pote.Validator.Bracket do
  @moduledoc """
  Bracket-style detection for color format strings.

  Splits out the bracket-style heuristic from `Pote.Validator` so that
  the validator remains focused on value parsing.

  Not part of the public API — used only by `Pote.Validator`.

  ## Format rules

  Most color formats use parentheses (`rgb:R,G,B`), not curly braces.
  This helper detects the common typo `rgb:{R,G,B}` and returns an
  informative error.

  Currently supported: `rgb`, `argb`, `hsl`, `hsv`, `cmyk`. Other
  formats return `nil` (no bracket-specific advice).
  """

  @doc """
  Checks if `code` uses curly braces instead of parentheses.

  Returns:
    * `{:error, atom(), String.t()}` — bracket-style mismatch error
    * `nil` — no bracket issue detected (or format doesn't care)
  """
  @spec check_bracket_style(String.t(), String.t()) ::
          {:error, atom(), String.t()} | nil
  def check_bracket_style(code, format) do
    if String.contains?(code, "{") or String.contains?(code, "}") do
      do_check(format)
    else
      nil
    end
  end

  defp do_check("rgb"),
    do: {:error, :rgb_uses_curly_braces, "Use rgb:R,G,B (parentheses), not rgb:{R,G,B}"}

  defp do_check("argb"),
    do: {:error, :argb_uses_curly_braces, "Use argb:A,R,G,B (parentheses), not argb:{A,R,G,B}"}

  defp do_check("hsl"),
    do: {:error, :hsl_uses_curly_braces, "Use hsl:H,S,L (parentheses), not hsl:{H,S,L}"}

  defp do_check("hsv"),
    do: {:error, :hsv_uses_curly_braces, "Use hsv:H,S,V (parentheses), not hsv:{H,S,V}"}

  defp do_check("cmyk"),
    do: {:error, :cmyk_uses_curly_braces, "Use cmyk:C,M,Y,K (parentheses), not cmyk:{C,M,Y,K}"}

  defp do_check(_format), do: nil
end
