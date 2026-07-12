defmodule Pote.Converters.Table do
  @moduledoc """
  Holds the conversion table mapping between color formats.

  The table maps `{from_format, to_format}` pairs to conversion functions.
  Each function receives a `Pote.ColorInfo.t()` and returns a
  `Pote.ColorInfo.t()` with the new format populated.

  The conversion lambdas use raw conversion logic directly from the
  converter submodules' internal helpers, not the public delegating API,
  to avoid circular calls through `Generic.convert/3`.
  """

  alias Pote.ColorInfo

  @doc "Returns the conversion table."
  @spec get() :: map()
  def get do
    %{
      {:rgb, :hex} => fn %ColorInfo{rgb: {r, g, b}} ->
        hex =
          "##{
            r |> Integer.to_string(16) |> String.pad_leading(2, "0")
          }#{
            g |> Integer.to_string(16) |> String.pad_leading(2, "0")
          }#{
            b |> Integer.to_string(16) |> String.pad_leading(2, "0")
          }" |> String.upcase()

        %ColorInfo{format: :hex, hex: hex}
      end,
      {:hex, :rgb} => fn %ColorInfo{hex: hex} ->
        clean = hex |> String.replace("#", "")

        expanded =
          if String.length(clean) == 3,
            do: clean |> String.graphemes() |> Enum.map_join(&(&1 <> &1)),
            else: clean

        [r, g, b] =
          for i <- [0, 2, 4] do
            part = String.slice(expanded, i, 2)
            {val, ""} = Integer.parse(part, 16)
            val
          end

        %ColorInfo{format: :rgb, rgb: {r, g, b}}
      end,
      {:rgb, :hsl} => fn %ColorInfo{rgb: {r, g, b}} ->
        rf = r / 255
        gf = g / 255
        bf = b / 255
        mx = Enum.max([rf, gf, bf])
        mn = Enum.min([rf, gf, bf])
        delta = mx - mn
        l = (mx + mn) / 2 * 100.0

        {h, s} =
          if delta == 0 do
            {0.0, 0.0}
          else
            s = if l < 50, do: delta / (mx + mn) * 100.0, else: delta / (2 - mx - mn) * 100.0

            h =
              cond do
                rf >= gf and rf >= bf -> (gf - bf) / delta
                gf >= rf and gf >= bf -> (bf - rf) / delta + 2
                true -> (rf - gf) / delta + 4
              end

            h = (h * 60.0) |> then(fn h -> if h < 0, do: h + 360, else: h end) |> Float.round(1)
            {h, s |> Float.round(1)}
          end

        %ColorInfo{format: :hsl, hsl: {h, s, l |> Float.round(1)}}
      end,
      {:hsl, :rgb} => fn %ColorInfo{hsl: {h, s, l}} ->
        hf = h / 360.0
        sf = s / 100.0
        lf = l / 100.0

        {r, g, b} =
          if sf == 0 do
            v = round(lf * 255)
            {v, v, v}
          else
            q = if lf < 0.5, do: lf * (1 + sf), else: lf + sf - lf * sf
            p = 2 * lf - q

            hue_to_rgb = fn t ->
              t =
                cond do
                  t < 0 -> t + 1
                  t > 1 -> t - 1
                  true -> t
                end

              cond do
                t < 1 / 6 -> p + (q - p) * 6 * t
                t < 1 / 2 -> q
                t < 2 / 3 -> p + (q - p) * (2 / 3 - t) * 6
                true -> p
              end
            end

            {round(hue_to_rgb.(hf + 1.0 / 3.0) * 255), round(hue_to_rgb.(hf) * 255),
             round(hue_to_rgb.(hf - 1.0 / 3.0) * 255)}
          end

        %ColorInfo{format: :rgb, rgb: {r, g, b}}
      end,
      {:rgb, :hsv} => fn %ColorInfo{rgb: {r, g, b}} ->
        rf = r / 255.0
        gf = g / 255.0
        bf = b / 255.0
        mx = Enum.max([rf, gf, bf])
        mn = Enum.min([rf, gf, bf])
        delta = mx - mn

        v = mx * 100.0
        s = if mx == 0, do: 0.0, else: delta / mx * 100.0

        h =
          if delta == 0 do
            0.0
          else
            h =
              cond do
                rf >= gf and rf >= bf -> (gf - bf) / delta
                gf >= rf and gf >= bf -> (bf - rf) / delta + 2
                true -> (rf - gf) / delta + 4
              end

            (h * 60.0) |> then(fn h -> if h < 0, do: h + 360, else: h end) |> Float.round(1)
          end

        %ColorInfo{format: :hsv, hsv: {h, s |> Float.round(1), v |> Float.round(1)}}
      end,
      {:hsv, :rgb} => fn %ColorInfo{hsv: {h, s, v}} ->
        hf = h / 360.0
        sf = s / 100.0
        vf = v / 100.0

        i = floor(hf * 6)
        f = hf * 6 - i
        p = vf * (1 - sf)
        q = vf * (1 - f * sf)
        t = vf * (1 - (1 - f) * sf)

        {r, g, b} =
          case rem(i, 6) do
            0 -> {vf, t, p}
            1 -> {q, vf, p}
            2 -> {p, vf, t}
            3 -> {p, q, vf}
            4 -> {t, p, vf}
            5 -> {vf, p, q}
          end

        %ColorInfo{format: :rgb, rgb: {round(r * 255), round(g * 255), round(b * 255)}}
      end,
      {:rgb, :cmyk} => fn %ColorInfo{rgb: {r, g, b}} ->
        rf = r / 255.0
        gf = g / 255.0
        bf = b / 255.0
        k = 1.0 - Enum.max([rf, gf, bf])

        {c, m, y} =
          if k == 1.0,
            do: {0.0, 0.0, 0.0},
            else: {(1.0 - rf - k) / (1.0 - k) * 100.0, (1.0 - gf - k) / (1.0 - k) * 100.0,
             (1.0 - bf - k) / (1.0 - k) * 100.0}

        %ColorInfo{format: :cmyk, cmyk: {c |> Float.round(1), m |> Float.round(1), y |> Float.round(1), k * 100.0 |> Float.round(1)}}
      end,
      {:cmyk, :rgb} => fn %ColorInfo{cmyk: {c, m, y, k}} ->
        cf = c / 100.0
        mf = m / 100.0
        yf = y / 100.0
        kf = k / 100.0

        r = round((1 - cf) * (1 - kf) * 255)
        g = round((1 - mf) * (1 - kf) * 255)
        b = round((1 - yf) * (1 - kf) * 255)

        %ColorInfo{format: :rgb, rgb: {r, g, b}}
      end,
      {:rgb, :xterm256} => fn %ColorInfo{rgb: {r, g, b}} ->
        rf = r / 255.0
        gf = g / 255.0
        bf = b / 255.0

        index =
          if rf == gf and gf == bf do
            cond do
              rf < 0.031 -> 16
              rf > 0.973 -> 231
              true -> round((rf - 0.031) / 0.942 * 23.0) + 232
            end
          else
            16 + round(rf * 5.0) * 36 + round(gf * 5.0) * 6 + round(bf * 5.0)
          end

        %ColorInfo{format: :xterm256, xterm256: index}
      end,
      {:xterm256, :rgb} => fn %ColorInfo{xterm256: index} ->
        {r, g, b} =
          cond do
            index in 232..255 ->
              gray = round((index - 232) / 23.0 * 255)
              {gray, gray, gray}

            index in 16..231 ->
              n = index - 16
              r_idx = div(n, 36)
              g_idx = div(rem(n, 36), 6)
              b_idx = rem(n, 6)

              {round(r_idx / 5.0 * 255), round(g_idx / 5.0 * 255), round(b_idx / 5.0 * 255)}

            index in 0..15 ->
              %{0 => {0, 0, 0}, 1 => {128, 0, 0}, 2 => {0, 128, 0}, 3 => {128, 128, 0},
                4 => {0, 0, 128}, 5 => {128, 0, 128}, 6 => {0, 128, 128}, 7 => {192, 192, 192},
                8 => {128, 128, 128}, 9 => {255, 0, 0}, 10 => {0, 255, 0}, 11 => {255, 255, 0},
                12 => {0, 0, 255}, 13 => {255, 0, 255}, 14 => {0, 255, 255}, 15 => {255, 255, 255}}
              |> Map.get(index, {0, 0, 0})

            true ->
              {0, 0, 0}
          end

        %ColorInfo{format: :rgb, rgb: {r, g, b}}
      end
    }
  end
end
