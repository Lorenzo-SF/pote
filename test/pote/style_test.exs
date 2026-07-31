defmodule Pote.StyleTest do
  use ExUnit.Case
  use ExUnitProperties
  alias Pote.Style

  @red {255, 0, 0}
  @black {0, 0, 0}
  @catppuccin_bg {30, 30, 46}

  describe "new/0" do
    test "returns an empty style" do
      assert Style.new() == %Style{fg: nil, bg: nil, effects: []}
    end
  end

  describe "fg/2" do
    test "accepts a named color atom" do
      assert Style.fg(:red).fg == @red
    end

    test "accepts an RGB tuple" do
      assert Style.fg({1, 2, 3}).fg == {1, 2, 3}
    end

    test "accepts a hex string" do
      assert Style.fg("#1e1e2e").fg == @catppuccin_bg
    end

    test "raises on unknown color" do
      assert_raise ArgumentError, fn -> Style.fg(:not_a_color) end
    end

    test "keeps existing bg and effects" do
      style = Style.red() |> Style.on(:black) |> Style.bold() |> Style.fg(:blue)
      assert style.bg == @black
      assert style.effects == [:bold]
    end
  end

  describe "bg/2 and on/2" do
    test "bg sets the background" do
      assert Style.bg("#1e1e2e").bg == @catppuccin_bg
    end

    test "on is an alias of bg" do
      assert Style.on(:black).bg == @black
    end
  end

  describe "named color helpers" do
    test "every basic color has a fg helper" do
      for {name, rgb} <- Pote.Colors.Basic.named_colors() do
        style = apply(Style, name, [])
        assert style.fg == rgb
      end
    end

    test "helpers are chainable via pipe" do
      style = Style.red() |> Style.bg(:blue)
      assert style.fg == @red
      assert style.bg == {0, 0, 255}
    end
  end

  describe "effects" do
    test "each effect helper adds its atom" do
      for effect <- [:bold, :dim, :italic, :underline, :inverse, :blink, :hidden] do
        style = apply(Style, effect, [])
        assert style.effects == [effect]
      end
    end

    test "duplicate effects are uniq'd" do
      assert Style.bold() |> Style.bold() |> Map.fetch!(:effects) == [:bold]
    end
  end

  describe "to_ansi/1" do
    test "empty style produces empty iodata" do
      assert IO.iodata_to_binary(Style.to_ansi(Style.new())) == ""
    end

    test "fg renders as truecolor" do
      assert IO.iodata_to_binary(Style.to_ansi(Style.red())) == "\e[38;2;255;0;0m"
    end

    test "bg renders as truecolor background" do
      assert IO.iodata_to_binary(Style.to_ansi(Style.bg(:black))) == "\e[48;2;0;0;0m"
    end

    test "effects render first, then fg, then bg" do
      ansi =
        Style.red()
        |> Style.bold()
        |> Style.on(:black)
        |> Style.to_ansi()
        |> IO.iodata_to_binary()

      assert ansi == "\e[1m\e[38;2;255;0;0m\e[48;2;0;0;0m"
    end
  end

  describe "render/2" do
    test "wraps text with escape + reset" do
      assert Style.red() |> Style.render("hi") |> IO.iodata_to_binary() ==
               "\e[38;2;255;0;0mhi\e[0m"
    end

    test "full composition from moduledoc" do
      ansi =
        Style.red()
        |> Style.bold()
        |> Style.on("#1e1e2e")
        |> Style.render("hi")
        |> IO.iodata_to_binary()

      assert ansi == "\e[1m\e[38;2;255;0;0m\e[48;2;30;30;46mhi\e[0m"
    end
  end

  property "fg/bg never leak into each other" do
    check all rgb <- tuple({integer(0..255), integer(0..255), integer(0..255)}) do
      style = Style.fg(rgb) |> Style.bg(rgb)
      assert style.fg == rgb
      assert style.bg == rgb
    end
  end
end
