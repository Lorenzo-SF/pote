defmodule Pote.Converters.Advanced do
  @moduledoc """
  Conversiones avanzadas de color para espacios de color especiales.

  Incluye:
  - CIE XYZ
  - CIELAB
  - YUV (BT.601)
  - YCbCr (BT.601)
  - Temperatura de color (Kelvin)
  - Delta E (distancia de color)
  - Contraste WCAG
  """

  alias Pote.Converters

  @type rgb :: Pote.rgb()
  @type xyz :: {float(), float(), float()}
  @type lab :: {float(), float(), float()}
  @type yuv :: {integer(), integer(), integer()}
  @type ycbcr :: {integer(), integer(), integer()}

  # ============================================================================
  # CIE XYZ
  # ============================================================================

  @doc """
  Convierte RGB a CIE XYZ usando la matriz sRGB D65.
  """
  @spec to_xyz(rgb()) :: xyz()
  def to_xyz({r, g, b}) do
    [rn, gn, bn] =
      [r, g, b]
      |> Enum.map(fn v -> v / 255.0 end)
      |> Enum.map(fn v ->
        if v <= 0.04045 do
          v / 12.92
        else
          :math.pow((v + 0.055) / 1.055, 2.4)
        end
      end)

    x = rn * 0.4124564 + gn * 0.3575761 + bn * 0.1804375
    y = rn * 0.2126729 + gn * 0.7151522 + bn * 0.0721750
    z = rn * 0.0193339 + gn * 0.1191920 + bn * 0.9503041

    {Float.round(x, 3), Float.round(y, 3), Float.round(z, 3)}
  end

  @doc """
  Convierte CIE XYZ a RGB (sRGB D65).
  """
  @spec from_xyz(xyz()) :: rgb()
  def from_xyz({x, y, z}) do
    rn = x * 3.2404542 + y * -1.5371385 + z * -0.4985314
    gn = x * -0.9692660 + y * 1.8760108 + z * 0.0415560
    bn = x * 0.0556434 + y * -0.2040259 + z * 1.0572252

    [r, g, b] =
      [rn, gn, bn]
      |> Enum.map(fn v ->
        if v <= 0.0031308 do
          v * 12.92
        else
          :math.pow(v, 1.0 / 2.4) * 1.055 - 0.055
        end
      end)
      |> Enum.map(fn v -> round(v * 255) end)
      |> Enum.map(fn v -> min(max(v, 0), 255) end)

    {r, g, b}
  end

  # ============================================================================
  # CIELAB
  # ============================================================================

  @doc """
  Convierte RGB a CIELAB (D65 illuminant).
  """
  @spec to_lab(rgb()) :: lab()
  def to_lab(rgb) do
    {x, y, z} = to_xyz(rgb)

    xn = 95.047
    yn = 100.0
    zn = 108.883

    fx = lab_f(x * 100.0 / xn)
    fy = lab_f(y * 100.0 / yn)
    fz = lab_f(z * 100.0 / zn)

    l = 116.0 * fy - 16.0
    a = 500.0 * (fx - fy)
    b = 200.0 * (fy - fz)

    {Float.round(l, 2), Float.round(a, 2), Float.round(b, 2)}
  end

  defp lab_f(t) do
    delta = 6.0 / 29.0

    if t > :math.pow(delta, 3) do
      :math.pow(t, 1.0 / 3.0)
    else
      t / (3.0 * :math.pow(delta, 2)) + 4.0 / 29.0
    end
  end

  @doc """
  Convierte CIELAB a RGB (sRGB D65).
  """
  @spec from_lab(lab()) :: rgb()
  def from_lab({l, a, b}) do
    delta = 6.0 / 29.0

    fy = (l + 16.0) / 116.0
    fx = a / 500.0 + fy
    fz = fy - b / 200.0

    x =
      if fx > delta do
        :math.pow(fx, 3)
      else
        3.0 * :math.pow(delta, 2) * (fx - 4.0 / 29.0)
      end

    y =
      if fy > delta do
        :math.pow(fy, 3)
      else
        3.0 * :math.pow(delta, 2) * (fy - 4.0 / 29.0)
      end

    z =
      if fz > delta do
        :math.pow(fz, 3)
      else
        3.0 * :math.pow(delta, 2) * (fz - 4.0 / 29.0)
      end

    from_xyz({x * 0.95047, y * 1.0, z * 1.08883})
  end

  # ============================================================================
  # Delta E (distancia de color)
  # ============================================================================

  @doc """
  Calcula la distancia Delta E 1976 entre dos colores.

  Esta es la distancia Euclidiana en espacio CIELAB.
  Valores < 1.0 son imperceptibles.
  """
  @spec delta_e(rgb(), rgb()) :: float()
  def delta_e(rgb1, rgb2) do
    {l1, a1, b1} = to_lab(rgb1)
    {l2, a2, b2} = to_lab(rgb2)

    :math.sqrt(:math.pow(l2 - l1, 2) + :math.pow(a2 - a1, 2) + :math.pow(b2 - b1, 2))
    |> Float.round(2)
  end

  # ============================================================================
  # WCAG Contrast
  # ============================================================================

  @doc """
  Calcula la luminancia relativa WCAG 2.1 de un color.
  """
  @spec relative_luminance(rgb()) :: float()
  def relative_luminance({r, g, b}) do
    [rn, gn, bn] =
      [r, g, b]
      |> Enum.map(fn v -> v / 255.0 end)
      |> Enum.map(fn v ->
        if v <= 0.03928 do
          v / 12.92
        else
          :math.pow((v + 0.055) / 1.055, 2.4)
        end
      end)

    (0.2126 * rn + 0.7152 * gn + 0.0722 * bn)
    |> Float.round(4)
  end

  @doc """
  Calcula el ratio de contraste WCAG 2.1 entre dos colores.

  WCAG AA requiere 4.5:1 para texto normal, 7:1 para AAA.
  """
  @spec contrast_ratio(rgb(), rgb()) :: float()
  def contrast_ratio(rgb1, rgb2) do
    l1 = relative_luminance(rgb1)
    l2 = relative_luminance(rgb2)

    lighter = max(l1, l2)
    darker = min(l1, l2)

    ((lighter + 0.05) / (darker + 0.05))
    |> Float.round(2)
  end

  # ============================================================================
  # YUV (BT.601)
  # ============================================================================

  @doc """
  Convierte RGB a YUV (BT.601, PAL/NTSC broadcast).
  """
  @spec to_yuv(rgb()) :: yuv()
  def to_yuv({r, g, b}) do
    y = round(0.299 * r + 0.587 * g + 0.114 * b)
    u = round(-0.147 * r - 0.289 * g + 0.436 * b)
    v = round(0.615 * r - 0.515 * g - 0.100 * b)

    {clamp(y), clamp(u + 128) - 128, clamp(v + 128) - 128}
  end

  @doc """
  Convierte YUV (BT.601) a RGB.
  """
  @spec from_yuv(yuv()) :: rgb()
  def from_yuv({y, u, v}) do
    u = u + 128
    v = v + 128

    r = round(y + 1.140 * (v - 128))
    g = round(y - 0.395 * (u - 128) - 0.581 * (v - 128))
    b = round(y + 2.032 * (u - 128))

    {clamp(r), clamp(g), clamp(b)}
  end

  # ============================================================================
  # YCbCr (BT.601)
  # ============================================================================

  @doc """
  Convierte RGB a YCbCr (BT.601, digital video).
  """
  @spec to_ycbcr(rgb()) :: ycbcr()
  def to_ycbcr({r, g, b}) do
    y = round(16 + 65.481 * r / 255 + 128.553 * g / 255 + 24.966 * b / 255)
    cb = round(128 - 37.797 * r / 255 - 74.203 * g / 255 + 112.0 * b / 255)
    cr = round(128 + 112.0 * r / 255 - 93.786 * g / 255 - 18.214 * b / 255)

    {min(max(y, 16), 235), min(max(cb, 16), 240), min(max(cr, 16), 240)}
  end

  @doc """
  Convierte YCbCr (BT.601) a RGB.
  """
  @spec from_ycbcr(ycbcr()) :: rgb()
  def from_ycbcr({y, cb, cr}) do
    r =
      round(255.0 / 219.0 * (y - 16) + 255.0 / 112.0 * 0.701 * (cr - 128))

    g =
      round(
        255.0 / 219.0 * (y - 16) - 255.0 / 112.0 * 0.886 * (cb - 128) / 1.772 -
          255.0 / 112.0 * 0.701 * (cr - 128) / 1.402
      )

    b = round(255.0 / 219.0 * (y - 16) + 255.0 / 112.0 * 0.886 * (cb - 128))

    {clamp(r), clamp(g), clamp(b)}
  end

  # ============================================================================
  # Temperatura de color (Kelvin)
  # ============================================================================

  @doc """
  Approxima la temperatura de color correlacionada (CCT) en Kelvin desde un color RGB.

  Usa una búsqueda iterativa sobre `kelvin_to_rgb/1` para encontrar
  la temperatura más cercana.
  """
  @spec rgb_to_kelvin(rgb()) :: pos_integer() | nil
  def rgb_to_kelvin(rgb) do
    search_kelvin(rgb, 1000, 40_000, 20)
  end

  defp search_kelvin(_rgb, low, high, _iterations) when low >= high do
    low
  end

  defp search_kelvin(_rgb, _low, _high, 0) do
    nil
  end

  defp search_kelvin(rgb, low, high, iterations) do
    mid = div(low + high, 2)
    mid_rgb = kelvin_to_rgb(mid)

    {h1, s1, l1} = Converters.rgb_to_hsl(rgb)
    {h2, s2, l2} = Converters.rgb_to_hsl(mid_rgb)

    cond do
      h1 < h2 -> search_kelvin(rgb, low, mid, iterations - 1)
      h1 > h2 -> search_kelvin(rgb, mid + 1, high, iterations - 1)
      s1 < s2 -> search_kelvin(rgb, low, mid, iterations - 1)
      s1 > s2 -> search_kelvin(rgb, mid + 1, high, iterations - 1)
      l1 < l2 -> search_kelvin(rgb, low, mid, iterations - 1)
      true -> search_kelvin(rgb, mid + 1, high, iterations - 1)
    end
  end

  @doc """
  Convierte temperatura en Kelvin a RGB.

  Basado en el algoritmo de Tanner Helland para aproximación de radiación black-body.
  """
  @spec kelvin_to_rgb(pos_integer()) :: rgb()
  def kelvin_to_rgb(kelvin) when kelvin < 1000, do: kelvin_to_rgb(1000)
  def kelvin_to_rgb(kelvin) when kelvin > 40_000, do: kelvin_to_rgb(40_000)

  def kelvin_to_rgb(kelvin) do
    k = kelvin / 100.0

    r = if k <= 66, do: 255, else: kelvin_red_component(k)

    g =
      if k <= 66,
        do: kelvin_green_low(k),
        else: kelvin_green_high(k)

    b =
      cond do
        k >= 66 -> 255
        k <= 19 -> 0
        true -> kelvin_blue_mid(k)
      end

    {r, g, b}
  end

  defp kelvin_red_component(k) do
    t = k - 60.0
    v = 329.698_727_446 * :math.pow(t, -0.133_204_759_2)
    clamp(round(v))
  end

  defp kelvin_green_low(k) do
    v = 99.470_802_586_1 * :math.log(k) - 161.119_568_166_1
    clamp(round(v))
  end

  defp kelvin_green_high(k) do
    t = k - 60.0
    v = 288.122_169_528_3 * :math.pow(t, -0.075_514_849_2)
    clamp(round(v))
  end

  defp kelvin_blue_mid(k) do
    t = k - 10.0
    v = 138.517_731_223_1 * :math.log(t) - 305.044_792_730_7
    clamp(round(v))
  end

  # ============================================================================
  # Pantone approximation
  # ============================================================================

  @pantone_colors [
    {"Process Yellow C", {255, 238, 0}},
    {"Process Magenta C", {236, 0, 140}},
    {"Process Cyan C", {0, 174, 239}},
    {"Process Black C", {45, 41, 38}},
    {"Red 032 C", {239, 51, 64}},
    {"Warm Red C", {249, 66, 58}},
    {"Orange 021 C", {254, 80, 0}},
    {"Yellow C", {254, 221, 0}},
    {"Green C", {0, 173, 131}},
    {"Blue 072 C", {16, 6, 159}},
    {"Violet C", {78, 0, 142}},
    {"Reflex Blue C", {0, 20, 137}},
    {"Rubine Red C", {206, 0, 88}},
    {"Rhodamine Red C", {225, 0, 152}},
    {"Purple C", {187, 0, 153}},
    {"Blue 0821 C", {162, 222, 255}},
    {"Yellow 0131 C", {242, 240, 174}},
    {"Red 0331 C", {255, 182, 175}},
    {"Magenta 0521 C", {234, 182, 222}},
    {"Violet 0631 C", {188, 172, 224}},
    {"Green 0921 C", {191, 232, 213}},
    {"Black 0961 C", {163, 165, 164}},
    {"100 C", {244, 237, 124}},
    {"101 C", {244, 237, 92}},
    {"102 C", {249, 232, 20}},
    {"103 C", {198, 173, 15}},
    {"104 C", {173, 155, 19}},
    {"105 C", {137, 125, 31}},
    {"106 C", {247, 232, 89}},
    {"116 C", {255, 205, 0}},
    {"124 C", {255, 181, 0}},
    {"130 C", {255, 158, 0}},
    {"165 C", {255, 103, 31}},
    {"172 C", {250, 70, 22}},
    {"178 C", {255, 88, 93}},
    {"185 C", {228, 0, 43}},
    {"199 C", {213, 0, 50}},
    {"200 C", {186, 12, 47}},
    {"Process Blue C", {0, 133, 202}},
    {"299 C", {0, 163, 224}},
    {"300 C", {0, 119, 200}},
    {"301 C", {0, 94, 168}},
    {"302 C", {0, 75, 135}},
    {"303 C", {0, 52, 96}},
    {"326 C", {0, 178, 169}},
    {"327 C", {0, 163, 155}},
    {"328 C", {0, 147, 142}},
    {"329 C", {0, 132, 127}},
    {"330 C", {0, 107, 102}},
    {"331 C", {0, 127, 126}},
    {"348 C", {0, 155, 85}},
    {"349 C", {0, 135, 75}},
    {"350 C", {43, 114, 62}},
    {"351 C", {120, 196, 136}},
    {"354 C", {0, 175, 80}},
    {"360 C", {108, 194, 74}},
    {"361 C", {67, 181, 73}},
    {"362 C", {80, 165, 69}},
    {"363 C", {101, 172, 56}},
    {"364 C", {102, 153, 40}},
    {"365 C", {196, 216, 115}},
    {"375 C", {143, 204, 0}},
    {"376 C", {132, 189, 0}},
    {"377 C", {126, 177, 0}},
    {"378 C", {85, 117, 16}},
    {"379 C", {225, 228, 29}},
    {"380 C", {225, 224, 0}},
    {"381 C", {206, 216, 0}},
    {"382 C", {186, 207, 0}},
    {"383 C", {170, 188, 0}},
    {"384 C", {155, 169, 0}},
    {"385 C", {139, 150, 0}},
    {"386 C", {231, 226, 0}},
    {"387 C", {226, 223, 0}},
    {"388 C", {218, 219, 0}},
    {"389 C", {211, 215, 0}},
    {"390 C", {196, 201, 0}},
    {"391 C", {175, 180, 0}},
    {"392 C", {156, 158, 0}},
    {"393 C", {242, 237, 78}},
    {"394 C", {242, 234, 0}},
    {"395 C", {239, 230, 0}},
    {"396 C", {237, 224, 0}},
    {"397 C", {209, 194, 0}},
    {"398 C", {188, 176, 0}},
    {"399 C", {168, 156, 0}},
    {"400 C", {196, 191, 182}},
    {"401 C", {181, 176, 168}},
    {"402 C", {166, 162, 154}},
    {"403 C", {152, 148, 141}},
    {"404 C", {126, 123, 118}},
    {"405 C", {101, 99, 95}},
    {"406 C", {196, 191, 186}},
    {"407 C", {175, 169, 164}},
    {"408 C", {155, 150, 146}},
    {"409 C", {135, 130, 126}},
    {"410 C", {115, 110, 107}},
    {"411 C", {95, 90, 87}},
    {"412 C", {64, 60, 58}},
    {"413 C", {175, 175, 168}},
    {"414 C", {160, 160, 153}},
    {"415 C", {145, 145, 138}},
    {"416 C", {130, 130, 124}},
    {"417 C", {115, 115, 109}},
    {"418 C", {100, 100, 94}},
    {"419 C", {64, 64, 60}},
    {"420 C", {196, 196, 196}},
    {"421 C", {181, 181, 181}},
    {"422 C", {166, 166, 166}},
    {"423 C", {150, 150, 150}},
    {"424 C", {130, 130, 130}},
    {"425 C", {110, 110, 110}},
    {"426 C", {64, 64, 64}},
    {"427 C", {221, 221, 221}},
    {"428 C", {198, 198, 198}},
    {"429 C", {173, 173, 173}},
    {"430 C", {148, 148, 148}},
    {"431 C", {120, 120, 120}},
    {"432 C", {90, 90, 90}},
    {"433 C", {60, 60, 60}},
    {"434 C", {233, 219, 219}},
    {"435 C", {226, 206, 206}},
    {"436 C", {216, 188, 188}},
    {"437 C", {196, 161, 161}},
    {"438 C", {155, 121, 121}},
    {"439 C", {114, 90, 90}},
    {"440 C", {79, 64, 64}},
    {"441 C", {216, 221, 216}},
    {"442 C", {196, 204, 196}},
    {"443 C", {175, 186, 175}},
    {"444 C", {155, 168, 155}},
    {"445 C", {121, 135, 121}},
    {"446 C", {90, 101, 90}},
    {"447 C", {64, 71, 64}},
    {"White C", {255, 255, 255}},
    {"Black C", {45, 41, 38}},
    {"Cool Gray 1 C", {217, 217, 214}},
    {"Cool Gray 2 C", {199, 201, 199}},
    {"Cool Gray 3 C", {184, 186, 186}},
    {"Cool Gray 4 C", {169, 172, 172}},
    {"Cool Gray 5 C", {155, 158, 159}},
    {"Cool Gray 6 C", {140, 143, 145}},
    {"Cool Gray 7 C", {125, 128, 130}},
    {"Cool Gray 8 C", {112, 115, 118}},
    {"Cool Gray 9 C", {100, 103, 106}},
    {"Cool Gray 10 C", {88, 91, 94}},
    {"Cool Gray 11 C", {62, 64, 67}},
    {"Warm Gray 1 C", {215, 213, 209}},
    {"Warm Gray 2 C", {198, 195, 191}},
    {"Warm Gray 3 C", {183, 179, 174}},
    {"Warm Gray 4 C", {168, 163, 158}},
    {"Warm Gray 5 C", {153, 148, 143}},
    {"Warm Gray 6 C", {139, 133, 128}},
    {"Warm Gray 7 C", {124, 118, 112}},
    {"Warm Gray 8 C", {110, 103, 97}},
    {"Warm Gray 9 C", {97, 89, 83}},
    {"Warm Gray 10 C", {84, 76, 70}},
    {"Warm Gray 11 C", {62, 54, 48}},
    {"Yellow 012 C", {255, 215, 0}}
  ]

  @doc """
  Encuentra el color Pantone más cercano para un color RGB.

  Usa una lista curada de colores Pantone populares y busca el match más
  cercano usando distancia Delta E en el espacio CIELAB.

  ## Parámetros
  - `rgb` - tupla RGB `{r, g, b}`

  ## Retorna
  - tupla `{nombre_pantone, distancia}` o `nil` si no hay match cercano

  ## Ejemplo
      iex> Pote.Converters.Advanced.nearest_pantone({255, 0, 0})
      {"Red 032 C", 0.0}
  """
  @spec nearest_pantone(rgb()) :: {String.t(), float()} | nil
  def nearest_pantone(rgb) do
    @pantone_colors
    |> Enum.map(fn {name, pantone_rgb} ->
      distance = delta_e(rgb, pantone_rgb)
      {name, distance}
    end)
    |> Enum.min_by(fn {_, distance} -> distance end)
    |> case do
      {_, distance} when distance > 30.0 -> nil
      result -> result
    end
  end

  @doc """
  Encuentra el nombre Pantone más cercano para un color RGB.
  Devuelve solo el nombre, o `nil` si no hay match cercano.

  ## Ejemplo
      iex> Pote.Converters.Advanced.nearest_pantone_name({255, 0, 0})
      "Red 032 C"
  """
  @spec nearest_pantone_name(rgb()) :: String.t() | nil
  def nearest_pantone_name(rgb) do
    case nearest_pantone(rgb) do
      {name, _distance} -> name
      nil -> nil
    end
  end

  # ============================================================================
  # Helper
  # ============================================================================

  defp clamp(value), do: min(max(value, 0), 255)
end
