defmodule Pote.AccessibilityTest do
  use ExUnit.Case
  use ExUnitProperties
  alias Pote.Accessibility

  describe "simulate/2" do
    test "protanopia collapses red toward dark brown" do
      assert Accessibility.simulate({255, 0, 0}, :protanopia) == {39, 29, 0}
    end

    test "deuteranopia shifts green toward yellow" do
      assert Accessibility.simulate({0, 255, 0}, :deuteranopia) == {219, 171, 11}
    end

    test "tritanopia darkens blue" do
      assert Accessibility.simulate({0, 0, 255}, :tritanopia) == {0, 38, 77}
    end

    test "red and green collapse toward each other under deuteranopia" do
      red = Accessibility.simulate({255, 0, 0}, :deuteranopia)
      green = Accessibility.simulate({0, 255, 0}, :deuteranopia)

      # Both shift toward yellow: channel ratio r/g becomes similar
      r_ratio = elem(red, 0) / max(elem(red, 1), 1)
      g_ratio = elem(green, 0) / max(elem(green, 1), 1)
      assert abs(r_ratio - g_ratio) < 1.0
    end

    test "grays are mostly unchanged" do
      for gray <- [{128, 128, 128}, {50, 50, 50}, {200, 200, 200}],
          deficiency <- [:protanopia, :deuteranopia, :tritanopia] do
        simulated = Accessibility.simulate(gray, deficiency)
        # Perceptual difference stays small
        assert Pote.Converters.Advanced.delta_e(gray, simulated) < 15.0
      end
    end

    test "output is always a valid RGB tuple" do
      for rgb <- [{255, 0, 0}, {0, 255, 0}, {0, 0, 255}, {123, 45, 67}],
          deficiency <- [:protanopia, :deuteranopia, :tritanopia] do
        {r, g, b} = Accessibility.simulate(rgb, deficiency)
        assert r in 0..255 and g in 0..255 and b in 0..255
      end
    end

    test "raises on unknown deficiency" do
      assert_raise FunctionClauseError, fn -> Accessibility.simulate({255, 0, 0}, :x) end
    end
  end

  describe "distinguishable?/3" do
    test "red and green remain distinguishable for protanopia" do
      assert Accessibility.distinguishable?({255, 0, 0}, {0, 255, 0}, :protanopia)
    end

    test "red and green pass for deuteranopia at the default threshold" do
      assert Accessibility.distinguishable?({255, 0, 0}, {0, 255, 0}, :deuteranopia)
    end

    test "red and green collapse for deuteranopia at high threshold" do
      # With a strict threshold, simulated red/green should not pass
      refute Accessibility.distinguishable?({255, 0, 0}, {0, 255, 0}, :deuteranopia, 4.5)
    end

    test "red and green are not distinguishable for tritanopia" do
      refute Accessibility.distinguishable?({255, 0, 0}, {0, 255, 0}, :tritanopia)
    end

    test "identical colors are never distinguishable" do
      refute Accessibility.distinguishable?({100, 100, 100}, {100, 100, 100}, :protanopia)
    end
  end

  property "simulate never returns out-of-range channels" do
    check all(
            r <- integer(0..255),
            g <- integer(0..255),
            b <- integer(0..255),
            deficiency <- member_of([:protanopia, :deuteranopia, :tritanopia])
          ) do
      {sr, sg, sb} = Accessibility.simulate({r, g, b}, deficiency)
      assert sr in 0..255 and sg in 0..255 and sb in 0..255
    end
  end
end
