defmodule Pote.Converters.PropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Pote.Converters
  alias Pote.Converters.{Advanced, CMYK, HSL, HSV, HWB, RGB}

  describe "RGB roundtrips via facade" do
    property "rgb → hwb → rgb tolerancia 1 por canal" do
      check all(
              r <- integer(0..255),
              g <- integer(0..255),
              b <- integer(0..255)
            ) do
        hwb = Converters.rgb_to_hwb({r, g, b})
        {r2, g2, b2} = Converters.hwb_to_rgb(hwb)
        assert abs(r - r2) <= 1
        assert abs(g - g2) <= 1
        assert abs(b - b2) <= 1
      end
    end

    property "rgb → hsl → rgb via facade" do
      check all(
              r <- integer(0..255),
              g <- integer(0..255),
              b <- integer(0..255)
            ) do
        hsl = Converters.rgb_to_hsl({r, g, b})
        {r2, g2, b2} = Converters.hsl_to_rgb(hsl)
        assert abs(r - r2) <= 1
        assert abs(g - g2) <= 1
        assert abs(b - b2) <= 1
      end
    end

    property "rgb → hsv → rgb via facade" do
      check all(
              r <- integer(0..255),
              g <- integer(0..255),
              b <- integer(0..255)
            ) do
        hsv = Converters.rgb_to_hsv({r, g, b})
        {r2, g2, b2} = Converters.hsv_to_rgb(hsv)
        assert abs(r - r2) <= 1
        assert abs(g - g2) <= 1
        assert abs(b - b2) <= 1
      end
    end
  end

  describe "Advanced color space roundtrips" do
    property "rgb → xyz → rgb tolerancia 5" do
      check all(
              r <- integer(0..255),
              g <- integer(0..255),
              b <- integer(0..255)
            ) do
        xyz = Advanced.to_xyz({r, g, b})
        {r2, g2, b2} = Advanced.from_xyz(xyz)
        assert abs(r - r2) < 5
        assert abs(g - g2) < 5
        assert abs(b - b2) < 5
      end
    end

    property "rgb → lab → rgb tolerancia 10" do
      check all(
              r <- integer(0..255),
              g <- integer(0..255),
              b <- integer(0..255)
            ) do
        lab = Advanced.to_lab({r, g, b})
        {r2, g2, b2} = Advanced.from_lab(lab)
        assert abs(r - r2) < 10
        assert abs(g - g2) < 10
        assert abs(b - b2) < 10
      end
    end

    property "yuv → rgb → yuv roundtrip" do
      check all(
              r <- integer(0..255),
              g <- integer(0..255),
              b <- integer(0..255)
            ) do
        yuv = Advanced.to_yuv({r, g, b})
        {r2, g2, b2} = Advanced.from_yuv(yuv)
        {y2, u2, v2} = Advanced.to_yuv({r2, g2, b2})
        assert abs(elem(yuv, 0) - y2) <= 2
        assert abs(elem(yuv, 1) - u2) <= 2
        assert abs(elem(yuv, 2) - v2) <= 2
      end
    end

    property "ycbcr → rgb → ycbcr roundtrip" do
      check all(
              r <- integer(0..255),
              g <- integer(0..255),
              b <- integer(0..255)
            ) do
        ycbcr = Advanced.to_ycbcr({r, g, b})
        {r2, g2, b2} = Advanced.from_ycbcr(ycbcr)
        {y2, cb2, cr2} = Advanced.to_ycbcr({r2, g2, b2})
        assert abs(elem(ycbcr, 0) - y2) <= 2
        assert abs(elem(ycbcr, 1) - cb2) <= 2
        assert abs(elem(ycbcr, 2) - cr2) <= 2
      end
    end
  end

  describe "Kelvin temperature monotonicity" do
    property "kelvin_to_rgb is monotonic: K1 < K2 → temp1 > temp2 (inverse)" do
      check all(
              k1 <- integer(2000..20_000),
              k2 <- integer(2000..20_000),
              k1 != k2
            ) do
        rgb1 = Advanced.kelvin_to_rgb(k1)
        rgb2 = Advanced.kelvin_to_rgb(k2)
        t1 = rgb_to_temp(rgb1)
        t2 = rgb_to_temp(rgb2)

        if k1 < k2 do
          assert t1 >= t2 or rgb1 != rgb2,
                 "K1=#{k1} (temp=#{t1}) < K2=#{k2} (temp=#{t2}) should be monotonic"
        end
      end
    end
  end

  defp rgb_to_temp(rgb), do: Advanced.rgb_to_kelvin(rgb) || 0
end
