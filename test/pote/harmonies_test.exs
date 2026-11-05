defmodule Pote.HarmoniesTest do
  use ExUnit.Case
  alias Pote.Harmonies

  @red {255, 0, 0}

  describe "complementary/1" do
    test "complementary of red is cyan" do
      # Hue 0 (red) + 180 = 180 (cyan)
      [c1] = Harmonies.complementary(@red)
      {r, g, b} = c1
      assert r == 0
      assert g == 255
      assert b == 255
    end
  end

  describe "analogous/1" do
    test "analogous/1 returns two adjacent colors (+30 and -30 degrees)" do
      [a1, a2] = Harmonies.analogous(@red)

      assert a1 == {255, 0, 128}
      assert a2 == {255, 128, 0}
    end
  end

  describe "triad/1" do
    test "returns two equidistant colors (+120 and +240 degrees)" do
      [t1, t2] = Harmonies.triad(@red)
      # h: 120 (green)
      {r1, g1, b1} = t1
      assert r1 == 0
      assert g1 == 255
      assert b1 == 0

      # h: 240 (blue)
      {r2, g2, b2} = t2
      assert r2 == 0
      assert g2 == 0
      assert b2 == 255
    end
  end

  describe "square/1" do
    test "square/1 returns three equidistant colors (+90, +180, +270 degrees)" do
      [s1, s2, s3] = Harmonies.square(@red)

      # 90 deg from red is Chartreuse Green area
      assert s1 == {128, 255, 0}
      # 180 deg is cyan
      assert s2 == {0, 255, 255}
      # 270 deg is violet/purple
      assert s3 == {127, 0, 255}
    end
  end

  describe "split_complementary/1" do
    test "split_complementary/1 returns two colors strictly adjacent to the complementary (+150 and +210)" do
      [s1, s2] = Harmonies.split_complementary(@red)

      # 150 deg from red
      assert s1 == {0, 255, 128}
      # 210 deg from red
      assert s2 == {0, 127, 255}
    end
  end

  describe "compound/1" do
    test "compound/1 returns combinations of opposite and adjacent hues (+180, +30, +210)" do
      [c1, c2, c3, c4] = Harmonies.compound(@red)

      assert c1 == {255, 128, 0}
      assert c2 == {0, 255, 255}
      assert c3 == {0, 127, 255}
      assert c4 == {255, 0, 128}
    end
  end

  describe "monochromatic/2" do
    test "generates lightness variations of the same hue" do
      colors = Harmonies.monochromatic(@red, 5)
      assert length(colors) == 5
      # all should be variations of red (hue 0)
      # Lightness goes from 20% to 80%
      {r1, g1, b1} = Enum.at(colors, 0)
      {r5, g5, b5} = Enum.at(colors, 4)

      assert r1 > 0 and g1 == 0 and b1 == 0
      # 80% lightness of red in RGB is {255, 153, 153}
      assert r5 > r1 and g5 == 153 and b5 == 153
    end
  end

  describe "lighter/2 and darker/2" do
    test "lighter mixes with white" do
      color = Harmonies.lighter({100, 100, 100}, 0.5)
      assert color == {178, 178, 178}
    end

    test "darker mixes with black" do
      color = Harmonies.darker({200, 200, 200}, 0.5)
      assert color == {100, 100, 100}
    end

    test "lighter with default amount" do
      color = Harmonies.lighter({100, 100, 100})
      assert is_tuple(color)
    end

    test "darker with default amount" do
      color = Harmonies.darker({100, 100, 100})
      assert is_tuple(color)
    end

    test "lighter at boundary amounts" do
      assert Harmonies.lighter({100, 100, 100}, 0.0) == {100, 100, 100}
      assert Harmonies.lighter({100, 100, 100}, 1.0) == {255, 255, 255}
    end

    test "darker at boundary amounts" do
      assert Harmonies.darker({100, 100, 100}, 0.0) == {100, 100, 100}
      assert Harmonies.darker({100, 100, 100}, 1.0) == {0, 0, 0}
    end
  end

  describe "monochromatic edge cases" do
    test "with two steps" do
      colors = Harmonies.monochromatic(@red, 2)
      assert length(colors) == 2
    end

    test "with many steps" do
      colors = Harmonies.monochromatic(@red, 10)
      assert length(colors) == 10
    end
  end
end
