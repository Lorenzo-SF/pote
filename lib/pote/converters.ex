defmodule Pote.Converters do
  @moduledoc """
  Color conversion module.

  Convenience functions that delegate to the individual converter modules (`Pote.Converters.RGB`,
  `Pote.Converters.HSL`, etc.).
  """

  # Aliases for nested converter modules
  alias Pote.Converters.{CMYK, HSL, HSV, HWB, RGB, XTerm256}

  # Convenience top‑level functions that proxy to the corresponding converter modules.
  def hsl_to_rgb(hsl), do: HSL.to_rgb(hsl)
  def rgb_to_hsl(rgb), do: RGB.to_hsl(rgb)
  def hsv_to_rgb(hsv), do: HSV.to_rgb(hsv)
  def rgb_to_hsv(rgb), do: RGB.to_hsv(rgb)
  def cmyk_to_rgb(cmyk), do: CMYK.to_rgb(cmyk)
  def rgb_to_cmyk(rgb), do: RGB.to_cmyk(rgb)
  def xterm256_to_rgb(index), do: XTerm256.to_rgb(index)
  def rgb_to_xterm256(rgb), do: RGB.to_xterm256(rgb)
  def hwb_to_rgb(hwb), do: HWB.to_rgb(hwb)
  def rgb_to_hwb(rgb), do: HWB.from_rgb(rgb)
  def rgb_to_hex(rgb), do: RGB.to_hex(rgb)
  def hex_to_rgb(hex), do: RGB.from_hex(hex)
end
