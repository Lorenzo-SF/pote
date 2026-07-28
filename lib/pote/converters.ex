defmodule Pote.Converters do
  @moduledoc """
  Color conversion module.

  Convenience functions that delegate to the individual converter modules (`Pote.Converters.RGB`,
  `Pote.Converters.HSL`, etc.).

  ## Rounding policy

  Internal converter functions preserve full float precision. Rounding is only
  applied at the final public API boundary (e.g. output formatting, string
  representation). This ensures roundtrip conversions (e.g. RGB → HSL → RGB)
  are as lossless as possible given the inherent quantization of 8-bit RGB.
  """

  # Aliases for nested converter modules
  alias Pote.Converters.{CMYK, HSL, HSV, HWB, RGB, XTerm256}

  # Convenience top‑level functions that proxy to the corresponding converter modules.

  @doc "Converts HSL to RGB."
  @spec hsl_to_rgb(Pote.hsl()) :: Pote.rgb()
  def hsl_to_rgb(hsl), do: HSL.to_rgb(hsl)

  @doc "Converts RGB to HSL."
  @spec rgb_to_hsl(Pote.rgb()) :: Pote.hsl()
  def rgb_to_hsl(rgb), do: RGB.to_hsl(rgb)

  @doc "Converts HSV to RGB."
  @spec hsv_to_rgb(Pote.hsv()) :: Pote.rgb()
  def hsv_to_rgb(hsv), do: HSV.to_rgb(hsv)

  @doc "Converts RGB to HSV."
  @spec rgb_to_hsv(Pote.rgb()) :: Pote.hsv()
  def rgb_to_hsv(rgb), do: RGB.to_hsv(rgb)

  @doc "Converts CMYK to RGB."
  @spec cmyk_to_rgb(Pote.cmyk()) :: Pote.rgb()
  def cmyk_to_rgb(cmyk), do: CMYK.to_rgb(cmyk)

  @doc "Converts RGB to CMYK."
  @spec rgb_to_cmyk(Pote.rgb()) :: Pote.cmyk()
  def rgb_to_cmyk(rgb), do: RGB.to_cmyk(rgb)

  @doc "Converts an XTerm256 index (0-255) to RGB."
  @spec xterm256_to_rgb(Pote.xterm256()) :: Pote.rgb()
  def xterm256_to_rgb(index), do: XTerm256.to_rgb(index)

  @doc "Converts RGB to the nearest XTerm256 index."
  @spec rgb_to_xterm256(Pote.rgb()) :: Pote.xterm256()
  def rgb_to_xterm256(rgb), do: RGB.to_xterm256(rgb)

  @doc "Converts HWB to RGB."
  @spec hwb_to_rgb(Pote.hwb()) :: Pote.rgb()
  def hwb_to_rgb(hwb), do: HWB.to_rgb(hwb)

  @doc "Converts RGB to HWB."
  @spec rgb_to_hwb(Pote.rgb()) :: Pote.hwb()
  def rgb_to_hwb(rgb), do: HWB.from_rgb(rgb)

  @doc "Converts RGB to hex string."
  @spec rgb_to_hex(Pote.rgb()) :: Pote.hex()
  def rgb_to_hex(rgb), do: RGB.to_hex(rgb)

  @doc "Converts a hex string to RGB."
  @spec hex_to_rgb(Pote.hex()) :: {:ok, Pote.rgb()} | {:error, :invalid_hex_format}
  def hex_to_rgb(hex), do: RGB.from_hex(hex)
end
