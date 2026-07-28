defmodule Pote.Converters.XTerm256Test do
  use ExUnit.Case, async: true
  alias Pote.Converters.XTerm256

  describe "to_rgb/1 — known values (POT-16)" do
    test "cube index 16 → (0, 0, 0)" do
      assert XTerm256.to_rgb(16) == {0, 0, 0}
    end

    test "cube index 231 → (255, 255, 255)" do
      assert XTerm256.to_rgb(231) == {255, 255, 255}
    end

    test "cube index 196 → (255, 0, 0) — pure red" do
      assert XTerm256.to_rgb(196) == {255, 0, 0}
    end

    test "gray index 232 → (8, 8, 8)" do
      assert XTerm256.to_rgb(232) == {8, 8, 8}
    end

    test "gray index 255 → (238, 238, 238)" do
      assert XTerm256.to_rgb(255) == {238, 238, 238}
    end

    test "gray formula produces all 24 expected levels (8, 18, ..., 238)" do
      expected_levels = for i <- 232..255, do: (i - 232) * 10 + 8

      actual_levels =
        for i <- 232..255 do
          {g, _, _} = XTerm256.to_rgb(i)
          g
        end

      assert actual_levels == expected_levels
    end
  end
end
