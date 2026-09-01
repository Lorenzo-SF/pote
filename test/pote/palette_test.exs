defmodule Pote.PaletteTest do
  use ExUnit.Case
  use ExUnitProperties
  alias Pote.Palette

  describe "generate/2" do
    test "returns the requested count" do
      for count <- [2, 3, 5, 10] do
        assert length(Palette.generate(1, count: count)) == count
      end
    end

    test "is deterministic per seed" do
      assert Palette.generate(42, count: 6) == Palette.generate(42, count: 6)
    end

    test "different seeds produce different palettes (usually)" do
      assert Palette.generate(1) != Palette.generate(2)
    end

    test "default count is 5" do
      assert length(Palette.generate(123)) == 5
    end

    test "supports harmonious, analogous and complementary bases" do
      for base <- [:harmonious, :analogous, :complementary] do
        palette = Palette.generate(7, count: 4, base: base)
        assert length(palette) == 4

        assert Enum.all?(palette, fn {r, g, b} ->
                 r in 0..255 and g in 0..255 and b in 0..255
               end)
      end
    end

    test "raises on count < 2" do
      assert_raise ArgumentError, fn -> Palette.generate(1, count: 1) end
    end

    test "wcag_aa: true makes consecutive luminance pairs pass AA" do
      # 3 colors at 4.5 is the max achievable ladder (4.5^2 = 20.25 < 21).
      for seed <- 1..30 do
        palette = Palette.generate(seed, count: 3, wcag_aa: true)
        assert Palette.wcag_aa?(palette), "seed #{seed} failed: #{inspect(palette)}"
      end
    end

    test "wcag_aa: true works for larger palettes with a reachable target" do
      # 5 colors at 2.0 is reachable (2^4 = 16 < 21).
      for seed <- 1..10 do
        palette = Palette.generate(seed, count: 5, wcag_aa: true, contrast_target: 2.0)
        assert Palette.wcag_aa?(palette, 2.0), "seed #{seed} failed: #{inspect(palette)}"
      end
    end

    test "wcag_aa: true respects a custom contrast target (2 colors at 7.0)" do
      palette = Palette.generate(3, count: 2, wcag_aa: true, contrast_target: 7.0)
      assert Palette.wcag_aa?(palette, 7.0)
    end

    test "fast for count <= 10" do
      {micros, _} = :timer.tc(fn -> Palette.generate(9, count: 10, wcag_aa: true) end)
      assert micros < 1_000_000
    end
  end

  describe "wcag_aa?/1" do
    test "white and black pass" do
      assert Palette.wcag_aa?([{255, 255, 255}, {0, 0, 0}])
    end

    test "two identical colors fail" do
      refute Palette.wcag_aa?([{255, 255, 255}, {255, 255, 255}])
    end

    test "single color is trivially true" do
      assert Palette.wcag_aa?([{128, 128, 128}])
    end
  end

  property "every generated color is a valid RGB tuple" do
    check all(seed <- integer(0..10_000)) do
      palette = Palette.generate(seed, count: 4)
      assert Enum.all?(palette, fn {r, g, b} -> r in 0..255 and g in 0..255 and b in 0..255 end)
    end
  end

  property "wcag_aa: true palettes always satisfy the target (3 colors @ 4.5)" do
    check all(seed <- integer(0..500)) do
      palette = Palette.generate(seed, count: 3, wcag_aa: true)
      assert Palette.wcag_aa?(palette)
    end
  end

  property "wcag_aa? accepts palettes sorted by luminance" do
    check all(
            a <- integer(0..255),
            b <- integer(0..255),
            c <- integer(0..255),
            d <- integer(0..255),
            e <- integer(0..255),
            f <- integer(0..255)
          ) do
      palette = [{a, b, c}, {d, e, f}]
      assert Palette.wcag_aa?(palette) == Palette.wcag_aa?(Enum.reverse(palette))
    end
  end
end
