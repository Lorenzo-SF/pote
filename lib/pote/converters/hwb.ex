defmodule Pote.Converters.HWB do
  @moduledoc """
  Conversions to/from HWB (Hue, Whiteness, Blackness).
  """
  alias Pote.Converters.HSV

  @type rgb :: Pote.rgb()
  @type hwb :: {float(), float(), float()}

  @doc """
  Converts HWB to RGB.
  """
  @spec to_rgb(hwb()) :: rgb()
  def to_rgb({h, w, b}) do
    w = w / 1.0
    b = b / 1.0

    if w + b >= 1.0 do
      gray = round(w / (w + b) * 255)
      {gray, gray, gray}
    else
      {r, g, b_val} = HSV.to_rgb({h, 100.0, 100.0})
      r = r / 255.0
      g = g / 255.0
      b_val = b_val / 255.0

      factor = 1.0 - w - b

      r = r * factor + w
      g = g * factor + w
      b_val = b_val * factor + w

      {round(r * 255), round(g * 255), round(b_val * 255)}
    end
  end

  @doc """
  Converts RGB to HWB.
  """
  @spec from_rgb(rgb()) :: hwb()
  def from_rgb({r, g, b}) do
    r_norm = r / 255.0
    g_norm = g / 255.0
    b_norm = b / 255.0

    max_val = max(r_norm, max(g_norm, b_norm))
    min_val = min(r_norm, min(g_norm, b_norm))
    diff = max_val - min_val

    h = hwb_hue(r_norm, g_norm, b_norm, max_val, diff) |> normalize_hue()

    w = min_val
    v = max_val
    b_val = 1.0 - v

    {h, w, b_val}
  end

  defp hwb_hue(_rn, _gn, _bn, _max, +0.0), do: 0.0

  defp hwb_hue(rn, gn, bn, _max, diff) when diff > 0.0 do
    max_val = max(rn, max(gn, bn))

    cond do
      max_val == rn ->
        ratio = (gn - bn) / diff
        h_raw = 60.0 * ratio
        h_raw = if h_raw < 0, do: h_raw + 360.0, else: h_raw
        h_raw - trunc(h_raw / 360.0) * 360.0

      max_val == gn ->
        h_temp = 60.0 * ((bn - rn) / diff + 2)
        if h_temp < 0, do: h_temp + 360.0, else: h_temp

      true ->
        h_temp = 60.0 * ((rn - gn) / diff + 4)
        if h_temp < 0, do: h_temp + 360.0, else: h_temp
    end
  end

  defp hwb_hue(_rn, _gn, _bn, _max, _diff), do: 0.0

  defp normalize_hue(h) when h < 0, do: h + 360.0
  defp normalize_hue(h) when h >= 360.0, do: h - 360.0
  defp normalize_hue(h), do: h
end
