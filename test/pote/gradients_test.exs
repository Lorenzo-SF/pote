defmodule Pote.GradientsTest do
  use ExUnit.Case
  alias Pote.Gradients

  @red {255, 0, 0}
  @blue {0, 0, 255}
  # Added @green for the new test
  @green {0, 255, 0}

  describe "linear/3" do
    test "generates a linear gradient between two colors" do
      grad = Gradients.linear(@red, @blue, 3)
      assert length(grad) == 3
      assert Enum.at(grad, 0) == {255, 0, 0}
      assert Enum.at(grad, 1) == {128, 0, 128}
      assert Enum.at(grad, 2) == {0, 0, 255}
    end

    test "linear/3 handles steps less than 2 safely" do
      # Depending on implementation, minimal 2 steps or graceful fallback
      grad0 = Gradients.linear(@red, @blue, 1)
      assert length(grad0) == 1
      assert Enum.at(grad0, 0) == @red

      grad0 = Gradients.linear(@red, @blue, 0)
      assert grad0 == []
    end
  end

  describe "multicolor/2" do
    test "generates a multi-stop gradient" do
      colors = [@red, @green, @blue]
      grad = Gradients.multicolor(colors, 5)

      assert length(grad) == 5
      assert Enum.at(grad, 0) == {255, 0, 0}
      assert Enum.at(grad, 2) == {0, 255, 0}
      assert Enum.at(grad, 4) == {0, 0, 255}

      # Intermediate blends
      # between red and green
      c1 = Enum.at(grad, 1)
      assert c1 == {128, 128, 0}

      # between green and blue
      c3 = Enum.at(grad, 3)
      assert c3 == {0, 128, 128}
    end

    test "multicolor/2 handles short lists safely" do
      assert Gradients.multicolor([@red], 3) == [@red]
      assert Gradients.multicolor([], 5) == []
    end
  end

  describe "apply_to_text/3" do
    test "apply_to_text/3 applies horizontal gradient to string returning ANSI string" do
      text = "hello"
      ansi_list = Gradients.apply_to_text(text, @red, @blue)

      ansi = IO.iodata_to_binary(ansi_list)
      # Should contain 5 different ANSI sequences
      # first h
      assert String.contains?(ansi, "38;2;255;0;0")
      # last o
      assert String.contains?(ansi, "38;2;0;0;255")
      assert String.ends_with?(ansi, "\e[0m")
    end

    test "apply_to_text/3 handles directions" do
      text = "ABC"
      # RTL
      ansi_list = Gradients.apply_to_text(text, @red, @blue, :right_to_left)
      ansi = IO.iodata_to_binary(ansi_list)
      # First char A should be blue
      assert String.contains?(ansi, "38;2;0;0;255")

      # Other directions fallback to LTR
      ansi_list2 = Gradients.apply_to_text(text, @red, @blue, :top_to_bottom)
      ansi2 = IO.iodata_to_binary(ansi_list2)
      assert String.contains?(ansi2, "38;2;255;0;0")
    end
  end

  describe "apply_bg_to_text/4" do
    test "applies background gradient" do
      text = "Hi"
      ansi_list = Gradients.apply_bg_to_text(text, @red, @blue)
      ansi = IO.iodata_to_binary(ansi_list)
      assert String.contains?(ansi, "48;2;255;0;0")
      assert String.contains?(ansi, "48;2;0;0;255")
    end
  end

  describe "vertical_fill/5" do
    test "generates vertical gradient strings" do
      fill = Gradients.vertical_fill(@red, @blue, 2, 5)
      ansi = IO.iodata_to_binary(fill)
      assert String.contains?(ansi, "48;2;255;0;0")
      assert String.contains?(ansi, "48;2;0;0;255")
      # width 5
      assert String.contains?(ansi, "     ")
    end
  end

  describe "to_hsl_stops/1" do
    test "converts rgb list to hsl list" do
      rgb_list = [@red, @blue]
      hsl_list = Gradients.to_hsl_stops(rgb_list)
      assert length(hsl_list) == 2
      # Red check
      {h1, _s1, _l1} = Enum.at(hsl_list, 0)
      assert_in_delta h1, 0.0, 1.0
      # Blue check
      {h2, _s2, _l2} = Enum.at(hsl_list, 1)
      assert_in_delta h2, 240.0, 1.0
    end
  end
end
