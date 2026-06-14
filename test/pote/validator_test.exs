defmodule Pote.ValidatorTest do
  use ExUnit.Case
  alias Pote.Validator

  describe "validate/1" do
    test "validates hex format" do
      assert Validator.validate("hex:FF0000") == :ok
      assert Validator.validate("hex:#FF0000") == :ok
      assert Validator.validate("hex:abc123") == :ok
    end

    test "invalidates hex with wrong length" do
      assert Validator.validate("hex:FF00") == {:error, :invalid_hex}
      assert Validator.validate("hex:GG0000") == {:error, :invalid_hex}
    end

    test "validates rgb format" do
      assert Validator.validate("rgb:255,0,0") == :ok
      assert Validator.validate("rgb:0,255,0") == :ok
      assert Validator.validate("rgb:0,0,255") == :ok
      assert Validator.validate("rgb:128,128,128") == :ok
    end

    test "invalidates rgb with out of range values" do
      assert Validator.validate("rgb:256,0,0") == {:error, :rgb_value_out_of_range}
      assert Validator.validate("rgb:255,256,0") == {:error, :rgb_value_out_of_range}
      assert Validator.validate("rgb:-1,0,0") == {:error, :rgb_value_out_of_range}
    end

    test "invalidates rgb with wrong part count" do
      assert Validator.validate("rgb:255,0") == {:error, :rgb_wrong_part_count}
      assert Validator.validate("rgb:255,0,0,0") == {:error, :rgb_wrong_part_count}
    end

    test "invalidates rgb with curly braces" do
      assert Validator.validate("rgb:{255,0,0}") ==
               {:error, :rgb_uses_curly_braces, "Use rgb:R,G,B (parentheses), not rgb:{R,G,B}"}
    end

    test "validates argb format" do
      assert Validator.validate("argb:255,255,0,0") == :ok
      assert Validator.validate("argb:128,0,255,0") == :ok
    end

    test "invalidates argb with out of range values" do
      assert Validator.validate("argb:256,255,0,0") == {:error, :argb_value_out_of_range}
      assert Validator.validate("argb:255,256,0,0") == {:error, :argb_value_out_of_range}
    end

    test "invalidates argb with wrong part count" do
      assert Validator.validate("argb:255,0,0") == {:error, :argb_wrong_part_count}
    end

    test "invalidates argb with curly braces" do
      assert Validator.validate("argb:{255,255,0,0}") ==
               {:error, :argb_uses_curly_braces,
                "Use argb:A,R,G,B (parentheses), not argb:{A,R,G,B}"}
    end

    test "validates hsl format" do
      assert Validator.validate("hsl:120,50,50") == :ok
      assert Validator.validate("hsl:0,0,0") == :ok
      assert Validator.validate("hsl:360,100,100") == :ok
    end

    test "validates hsl with degree symbol" do
      assert Validator.validate("hsl:120°,50,50") == :ok
    end

    test "validates hsl with percentage symbol" do
      assert Validator.validate("hsl:120,50%,50%") == :ok
    end

    test "invalidates hsl with wrong part count" do
      assert Validator.validate("hsl:120,50") == {:error, :hsl_wrong_part_count}
    end

    test "invalidates hsl with hue out of range" do
      assert Validator.validate("hsl:370,50,50") == {:error, :hue_out_of_range}
    end

    test "invalidates hsl with percentage out of range" do
      assert Validator.validate("hsl:120,150,50") == {:error, :percentage_out_of_range}
      assert Validator.validate("hsl:120,50,150") == {:error, :percentage_out_of_range}
    end

    test "invalidates hsl with curly braces" do
      assert Validator.validate("hsl:{120,50,50}") ==
               {:error, :hsl_uses_curly_braces, "Use hsl:H,S,L (parentheses), not hsl:{H,S,L}"}
    end

    test "validates hsv format" do
      assert Validator.validate("hsv:120,50,100") == :ok
      assert Validator.validate("hsv:0,0,0") == :ok
    end

    test "invalidates hsv with wrong part count" do
      assert Validator.validate("hsv:120,50") == {:error, :hsv_wrong_part_count}
    end

    test "invalidates hsv with curly braces" do
      assert Validator.validate("hsv:{120,50,100}") ==
               {:error, :hsv_uses_curly_braces, "Use hsv:H,S,V (parentheses), not hsv:{H,S,V}"}
    end

    test "validates cmyk format" do
      assert Validator.validate("cmyk:100,0,50,0") == :ok
      assert Validator.validate("cmyk:0,0,0,0") == :ok
      assert Validator.validate("cmyk:50,50,50,50") == :ok
    end

    test "validates cmyk with percentage symbol" do
      assert Validator.validate("cmyk:100%,0%,50%,0%") == :ok
    end

    test "invalidates cmyk with wrong part count" do
      assert Validator.validate("cmyk:100,0,50") == {:error, :cmyk_wrong_part_count}
    end

    test "invalidates cmyk with curly braces" do
      assert Validator.validate("cmyk:{100,0,50,0}") ==
               {:error, :cmyk_uses_curly_braces,
                "Use cmyk:C,M,Y,K (parentheses), not cmyk:{C,M,Y,K}"}
    end

    test "validates hwb format" do
      assert Validator.validate("hwb:120,0.2,0.3") == :ok
      assert Validator.validate("hwb:0,0,0") == :ok
      assert Validator.validate("hwb:0,0.5,0.5") == :ok
    end

    test "invalidates hwb with wrong part count" do
      assert Validator.validate("hwb:120,0.2") == {:error, :hwb_wrong_part_count}
    end

    test "validates xterm format" do
      assert Validator.validate("xterm:0") == :ok
      assert Validator.validate("xterm:255") == :ok
      assert Validator.validate("xterm:128") == :ok
    end

    test "invalidates xterm out of range" do
      assert Validator.validate("xterm:256") == {:error, :xterm_out_of_range}
      assert Validator.validate("xterm:-1") == {:error, :xterm_out_of_range}
    end

    test "validates theme format" do
      assert Validator.validate("theme:primary") == :ok
      assert Validator.validate("theme:my_color") == :ok
      assert Validator.validate("theme:COLOR_1") == :ok
    end

    test "invalidates theme with empty name" do
      assert Validator.validate("theme:") == {:error, :invalid_theme_color_name}
    end

    test "invalidates theme with invalid characters" do
      assert Validator.validate("theme:123abc") == {:error, :invalid_theme_color_name}
      assert Validator.validate("theme:my-color") == {:error, :invalid_theme_color_name}
    end

    test "validates plain hex without prefix" do
      assert Validator.validate("#FF0000") == :ok
      assert Validator.validate("FF0000") == :ok
      assert Validator.validate("#F00") == :ok
    end

    test "validates plain xterm number without prefix" do
      assert Validator.validate("255") == :ok
      assert Validator.validate("0") == :ok
    end

    test "returns ok for unknown format prefix" do
      assert Validator.validate("unknown:something") == :ok
    end
  end

  describe "error_message/1" do
    test "returns correct messages for validation errors" do
      assert Validator.error_message(:invalid_hex) ==
               "Hex color must be 6 hexadecimal characters (0-9, A-F)"

      assert Validator.error_message(:rgb_value_out_of_range) ==
               "RGB values must be integers between 0 and 255"

      assert Validator.error_message(:argb_value_out_of_range) ==
               "ARGB values must be integers between 0 and 255"

      assert Validator.error_message(:xterm_out_of_range) ==
               "XTerm256 index must be between 0 and 255"

      assert Validator.error_message(:hue_out_of_range) ==
               "Hue must be between 0.00 and 360.00 degrees"

      assert Validator.error_message(:invalid_hue) == "Hue must be a number between 0 and 360"

      assert Validator.error_message(:percentage_out_of_range) ==
               "Percentage must be between 0 and 100"

      assert Validator.error_message(:invalid_percentage) ==
               "Percentage must be a number between 0 and 100"

      assert Validator.error_message(:hsl_wrong_part_count) ==
               "HSL format requires exactly 3 values: H,S,L"

      assert Validator.error_message(:hsv_wrong_part_count) ==
               "HSV format requires exactly 3 values: H,S,V"

      assert Validator.error_message(:cmyk_wrong_part_count) ==
               "CMYK format requires exactly 4 values: C,M,Y,K"

      assert Validator.error_message(:hwb_wrong_part_count) ==
               "HWB format requires exactly 3 values: H,W,B"

      assert Validator.error_message(:ratio_out_of_range) ==
               "HWB whiteness/blackness must be between 0.0 and 1.0"

      assert Validator.error_message(:invalid_ratio) ==
               "HWB whiteness/blackness must be a number between 0.0 and 1.0"

      assert Validator.error_message(:rgb_wrong_part_count) ==
               "RGB format requires exactly 3 values: R,G,B"

      assert Validator.error_message(:argb_wrong_part_count) ==
               "ARGB format requires exactly 4 values: A,R,G,B"

      assert Validator.error_message(:unknown_color_format) ==
               "Unknown color format. Use a supported format like: hex:RRGGBB, rgb:R,G,B, argb:A,R,G,B, xterm:N, hsl:H,S,L, hsv:H,S,V, cmyk:C,M,Y,K, or plain hex/number"
    end

    test "returns generic message for unknown error" do
      assert Validator.error_message(:some_unknown_error) ==
               "Invalid color value: :some_unknown_error"
    end
  end

  describe "input validation edge cases" do
    test "whitespace handling in hex" do
      assert Validator.validate("hex:FF0000 ") == :ok
      assert Validator.validate("  hex:FF0000") == :ok
    end

    test "whitespace handling in rgb" do
      assert Validator.validate("rgb:255, 0, 0") == :ok
      assert Validator.validate("rgb:255,0,0 ") == :ok
    end

    test "whitespace handling in hsl" do
      assert Validator.validate("hsl:120 , 50, 50") == :ok
    end

    test "multiple spaces between values" do
      assert Validator.validate("rgb:255  ,  0  ,  0") == :ok
    end

    test "invalid_rgb_returns_correct_error" do
      assert Validator.validate("rgb:not,integers,here") == {:error, :rgb_value_out_of_range}
    end

    test "invalid_cmyk_returns_correct_error" do
      assert Validator.validate("cmyk:not,values,here,too") == {:error, :invalid_percentage}
    end

    test "hsl_with_max_decimals" do
      assert Validator.validate("hsl:120.12,50,50") == :ok
    end

    test "normalize_with_zero_value" do
      assert Validator.validate("hwb:120,0,0") == :ok
    end

    test "normalize_with_one_value" do
      assert Validator.validate("hwb:120,1,1") == :ok
    end

    test "invalid_rgb_with_empty_parts" do
      assert Validator.validate("rgb:,0,0") == {:error, :rgb_value_out_of_range}
    end

    test "hsl_parsing_edge_cases" do
      assert Validator.validate("hsl:0,0,0") == :ok
      assert Validator.validate("hsl:360,100,100") == :ok
    end
  end
end
