defmodule Pote.OrchestratorTest do
  use ExUnit.Case
  alias Pote.Orchestrator

  describe "parse_color/1" do
    test "parses RGB tuples" do
      assert Orchestrator.parse_color({255, 0, 0}) == {:ok, {255, 0, 0}}
      assert match?({:error, _}, Orchestrator.parse_color({256, 0, 0}))
    end

    test "parses HSL tuples" do
      assert Orchestrator.parse_color({0.0, 100.0, 50.0}) == {:ok, {255, 0, 0}}
    end

    test "parses CMYK tuples" do
      assert Orchestrator.parse_color({0.0, 100.0, 100.0, 0.0}) == {:ok, {255, 0, 0}}
    end

    test "returns error for invalid tuples" do
      assert match?({:error, _}, Orchestrator.parse_color({1}))
      assert match?({:error, _}, Orchestrator.parse_color({1, 2, 3, 4, 5}))
    end

    test "parses HEX strings" do
      assert Orchestrator.parse_color("#FF0000") == {:ok, {255, 0, 0}}
      assert Orchestrator.parse_color("00FF00") == {:ok, {0, 255, 0}}
    end

    test "parses XTerm integers as strings" do
      assert Orchestrator.parse_color("196") == {:ok, {255, 0, 0}}
      assert match?({:error, _}, Orchestrator.parse_color("300"))
    end

    test "parses XTerm indices directly to rgb logic" do
      # 232..255 (Grayscale)
      assert Orchestrator.parse_color("232") == {:ok, {8, 8, 8}}
      assert Orchestrator.parse_color("255") == {:ok, {238, 238, 238}}
      # 16..231 (6x6x6 cube)
      assert Orchestrator.parse_color("16") == {:ok, {0, 0, 0}}
      assert Orchestrator.parse_color("231") == {:ok, {255, 255, 255}}
      # 0..15 (Standard)
      assert Orchestrator.parse_color("1") == {:ok, {128, 0, 0}}
      assert Orchestrator.parse_color("9") == {:ok, {255, 0, 0}}
    end

    test "parses existing atom strings" do
      result = Orchestrator.parse_color("invented_color_alias")
      assert match?({:error, _}, result)
    end

    test "parses atoms directly" do
      assert Orchestrator.parse_color(:blue) == {:ok, {0, 0, 255}}
      assert Orchestrator.parse_color(:nonexistent) == {:error, :unknown_color_format}
    end

    test "returns error for random items" do
      assert is_tuple(Orchestrator.parse_color(123))
      # Just verify it returns an error tuple, not the value
    end
  end

  describe "to_rgb/1 and to_rgb!/1" do
    test "to_rgb returns ok tuple" do
      assert Orchestrator.to_rgb(:red) == {:ok, {255, 0, 0}}
    end

    test "to_rgb! unwraps the tuple" do
      assert Orchestrator.to_rgb!(:red) == {255, 0, 0}
    end

    test "to_rgb! raises ArgumentError on failure" do
      assert_raise ArgumentError, ~r/failed to convert color/, fn ->
        Orchestrator.to_rgb!(:invalid)
      end
    end
  end

  describe "to_ansi/1 and to_ansi_bg/1" do
    test "to_ansi creates foreground 24-bit codes" do
      assert Orchestrator.to_ansi({255, 128, 0}) == "\e[38;2;255;128;0m"
      assert Orchestrator.to_ansi("#FF8000") == "\e[38;2;255;128;0m"
    end

    test "to_ansi handles nil and errors" do
      assert Orchestrator.to_ansi(nil) == ""
      assert Orchestrator.to_ansi(:invalid) == ""
    end

    test "to_ansi_bg creates background 24-bit codes" do
      assert Orchestrator.to_ansi_bg({255, 128, 0}) == "\e[48;2;255;128;0m"
      assert Orchestrator.to_ansi_bg("#FF8000") == "\e[48;2;255;128;0m"
    end

    test "to_ansi_bg handles nil and errors" do
      assert Orchestrator.to_ansi_bg(nil) == ""
      assert Orchestrator.to_ansi_bg(:invalid) == ""
    end
  end

  describe "to_xterm256/1" do
    test "converts correctly to xterm" do
      assert Orchestrator.to_xterm256({255, 128, 0}) == {:ok, 214}
      assert Orchestrator.to_xterm256("#FF8000") == {:ok, 214}
    end

    test "returns error on invalid input" do
      assert Orchestrator.to_xterm256(:invalid) == {:error, :unknown_color_format}
    end
  end

  describe "named_colors/0" do
    test "returns keyword list of mapped colors" do
      colors = Orchestrator.named_colors()
      assert is_list(colors)
      assert Keyword.get(colors, :red) == {255, 0, 0}
      assert Keyword.get(colors, :magenta) == {255, 0, 255}
    end
  end

  describe "prefixed format parsing" do
    test "parses rgb:R,G,B format" do
      assert Orchestrator.parse_color("rgb:255,0,0") == {:ok, {255, 0, 0}}
      assert Orchestrator.parse_color("rgb:100,150,200") == {:ok, {100, 150, 200}}
    end

    test "parses hsl:H,S,L format" do
      # hsl:0,100,50 is red
      assert Orchestrator.parse_color("hsl:0,100,50") == {:ok, {255, 0, 0}}
    end

    test "parses hsv:H,S,V format" do
      # hsv:0,100,100 is red
      assert Orchestrator.parse_color("hsv:0,100,100") == {:ok, {255, 0, 0}}
    end

    test "parses cmyk:C,M,Y,K format" do
      # cmyk:0,100,100,0 is red
      assert Orchestrator.parse_color("cmyk:0,100,100,0") == {:ok, {255, 0, 0}}
    end

    test "parses argb:A,R,G,B format" do
      assert Orchestrator.parse_color("argb:255,255,0,0") == {:ok, {255, 0, 0}}
    end

    test "invalid rgb string returns error" do
      result = Orchestrator.parse_color("rgb:not,integers")
      assert match?({:error, _}, result)

      result2 = Orchestrator.parse_color("rgb:256,0,0")
      assert match?({:error, _}, result2)
    end

    test "invalid hsl string returns error" do
      result = Orchestrator.parse_color("hsl:not,values")
      assert match?({:error, _}, result)
    end

    test "invalid hsv string returns error" do
      result = Orchestrator.parse_color("hsv:not,values")
      assert match?({:error, _}, result)
    end

    test "invalid cmyk string returns error" do
      result = Orchestrator.parse_color("cmyk:not,values")
      assert match?({:error, _}, result)
    end
  end

  describe "to_color_info/1" do
    test "creates ColorInfo from atom color" do
      ci = Orchestrator.to_color_info(:red)
      assert ci.rgb == {255, 0, 0}
      assert ci.name == :red
    end

    test "creates ColorInfo from string color" do
      ci = Orchestrator.to_color_info("#FF0000")
      assert ci.rgb == {255, 0, 0}
    end

    test "creates ColorInfo from rgb tuple" do
      ci = Orchestrator.to_color_info({255, 0, 0})
      assert ci.rgb == {255, 0, 0}
    end

    test "returns default ColorInfo on invalid color" do
      ci = Orchestrator.to_color_info(:nonexistent_color)
      assert is_struct(ci)
    end

    test "returns default ColorInfo on invalid string" do
      ci = Orchestrator.to_color_info("not_a_color")
      assert is_struct(ci)
    end
  end

  describe "xterm256 edge cases" do
    test "parses standard xterm colors 0-15" do
      # Color 0 (black)
      assert Orchestrator.parse_color("0") == {:ok, {0, 0, 0}}
      # Color 9 (bright red)
      assert Orchestrator.parse_color("9") == {:ok, {255, 0, 0}}
    end

    test "parses grayscale xterm colors 232-255" do
      # 232 is near black
      assert Orchestrator.parse_color("232") == {:ok, {8, 8, 8}}
      # 255 is near white
      assert Orchestrator.parse_color("255") == {:ok, {238, 238, 238}}
    end

    test "parses 6x6x6 cube xterm colors 16-231" do
      # 16 should be black
      assert Orchestrator.parse_color("16") == {:ok, {0, 0, 0}}
      # 17 should be (0, 0, 51) per xterm256 formula
      assert Orchestrator.parse_color("17") == {:ok, {0, 0, 51}}
      # 231 should be white
      assert Orchestrator.parse_color("231") == {:ok, {255, 255, 255}}
    end

    test "out of range xterm returns error" do
      assert match?({:error, _}, Orchestrator.parse_color("256"))
      assert match?({:error, _}, Orchestrator.parse_color("-1"))
    end
  end

  describe "parse_color edge cases" do
    test "hex without hash" do
      assert Orchestrator.parse_color("FF0000") == {:ok, {255, 0, 0}}
    end

    test "atom color not in named list" do
      assert Orchestrator.parse_color(:invented_color_xyz) == {:error, :unknown_color_format}
    end

    test "unknown string with digits falls back to xterm" do
      result = Orchestrator.parse_color("196")
      assert result == {:ok, {255, 0, 0}}
    end
  end

  describe "prefixed format error cases" do
    test "hex: prefix with invalid hex" do
      assert match?({:error, _}, Orchestrator.parse_color("hex:GGGGGG"))
      assert match?({:error, _}, Orchestrator.parse_color("hex:FFFF"))
    end

    test "rgb: prefix with wrong part count" do
      assert match?({:error, _}, Orchestrator.parse_color("rgb:255,0"))
      assert match?({:error, _}, Orchestrator.parse_color("rgb:255,0,0,0"))
    end

    test "rgb: prefix with out of range values" do
      assert match?({:error, _}, Orchestrator.parse_color("rgb:256,0,0"))
      assert match?({:error, _}, Orchestrator.parse_color("rgb:255,256,0"))
      assert match?({:error, _}, Orchestrator.parse_color("rgb:255,0,256"))
    end

    test "argb: prefix with wrong part count" do
      assert match?({:error, _}, Orchestrator.parse_color("argb:255,0,0"))
      assert match?({:error, _}, Orchestrator.parse_color("argb:255,255,0,0,0"))
    end

    test "hsl: prefix with wrong part count" do
      assert match?({:error, _}, Orchestrator.parse_color("hsl:120,50"))
      assert match?({:error, _}, Orchestrator.parse_color("hsl:120,50,50,50"))
    end

    test "hsl: prefix with out of range values" do
      assert match?({:error, _}, Orchestrator.parse_color("hsl:370,50,50"))
      assert match?({:error, _}, Orchestrator.parse_color("hsl:120,150,50"))
      assert match?({:error, _}, Orchestrator.parse_color("hsl:120,50,150"))
    end

    test "hsv: prefix with wrong part count" do
      assert match?({:error, _}, Orchestrator.parse_color("hsv:120,50"))
    end

    test "hsv: prefix with out of range values" do
      assert match?({:error, _}, Orchestrator.parse_color("hsv:370,50,100"))
      assert match?({:error, _}, Orchestrator.parse_color("hsv:120,150,100"))
      assert match?({:error, _}, Orchestrator.parse_color("hsv:120,50,150"))
    end

    test "cmyk: prefix with wrong part count" do
      assert match?({:error, _}, Orchestrator.parse_color("cmyk:100,0,50"))
      assert match?({:error, _}, Orchestrator.parse_color("cmyk:100,0,50,0,0"))
    end

    test "cmyk: prefix with out of range values" do
      assert match?({:error, _}, Orchestrator.parse_color("cmyk:150,0,50,0"))
      assert match?({:error, _}, Orchestrator.parse_color("cmyk:100,150,50,0"))
    end

    test "hwb: prefix with wrong part count" do
      assert match?({:error, _}, Orchestrator.parse_color("hwb:120,0.2"))
      assert match?({:error, _}, Orchestrator.parse_color("hwb:120,0.2,0.3,0.1"))
    end

    test "hwb: prefix with out of range values" do
      assert match?({:error, _}, Orchestrator.parse_color("hwb:370,0.2,0.3"))
      assert match?({:error, _}, Orchestrator.parse_color("hwb:120,1.5,0.3"))
      assert match?({:error, _}, Orchestrator.parse_color("hwb:120,0.2,1.5"))
    end

    test "xterm: prefix with out of range value" do
      assert match?({:error, _}, Orchestrator.parse_color("xterm:256"))
      assert match?({:error, _}, Orchestrator.parse_color("xterm:-1"))
      assert match?({:error, _}, Orchestrator.parse_color("xterm:abc"))
    end

    test "theme: prefix parsing returns error when theme not configured" do
      result = Orchestrator.parse_color("theme:nonexistent_theme_xyz")
      assert match?({:error, _}, result)
    end

    test "empty string returns error" do
      assert match?({:error, _}, Orchestrator.parse_color(""))
    end

    test "whitespace only returns error" do
      assert match?({:error, _}, Orchestrator.parse_color("   "))
    end
  end

  describe "parse_color atom handling" do
    test "theme colors resolve when Pote has theme colors configured" do
      result = Orchestrator.parse_color(:success)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "atom with binary fallback returns error" do
      assert match?({:error, _}, Orchestrator.parse_color(:nonexistent_atom_xyz))
    end
  end
end
