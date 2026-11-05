defmodule Pote.SanitizerTest do
  use ExUnit.Case
  alias Pote.Sanitizer

  describe "sanitize/1" do
    test "removes degree symbols" do
      assert Sanitizer.sanitize("360º") == "360"
      assert Sanitizer.sanitize(" 180º ") == "180"
    end

    test "removes deg and degrees suffixes" do
      assert Sanitizer.sanitize("12.5 deg") == "12.5"
      assert Sanitizer.sanitize("90 degrees") == "90"
      assert Sanitizer.sanitize("45 DEG") == "45"
    end

    test "removes percent signs" do
      assert Sanitizer.sanitize("50%") == "50"
      assert Sanitizer.sanitize(" 100% ") == "100"
      assert Sanitizer.sanitize("0.5%") == "0.5"
    end

    test "returns clean strings unchanged" do
      assert Sanitizer.sanitize("255") == "255"
      assert Sanitizer.sanitize("128") == "128"
    end

    test "handles combined units" do
      assert Sanitizer.sanitize("360º, 50%, 50%") == "360, 50, 50"
    end

    test "raises ArgumentError for non-binary input (P0-1 fix)" do
      assert_raise ArgumentError, ~r/expected a binary/, fn ->
        Sanitizer.sanitize(123)
      end

      assert_raise ArgumentError, ~r/expected a binary/, fn ->
        Sanitizer.sanitize(nil)
      end
    end
  end

  describe "sanitize_list/2" do
    test "sanitizes a delimited string" do
      assert Sanitizer.sanitize_list("360º, 50%, 50%", ",") == {:ok, ["360", "50", "50"]}
      assert Sanitizer.sanitize_list("100;50;25", ";") == {:ok, ["100", "50", "25"]}
    end

    test "sanitizes a list of strings" do
      assert Sanitizer.sanitize_list(["360º", "50%", "25%"], nil) == {:ok, ["360", "50", "25"]}
    end

    test "returns error for invalid list input" do
      assert {:error, _} = Sanitizer.sanitize_list(123, nil)
    end

    test "returns error when not a proper list with nil separator" do
      assert {:error, _} = Sanitizer.sanitize_list("not a list", nil)
    end

    test "returns error when separator is not a binary (P0-2 fix)" do
      assert {:error, :invalid_input} = Sanitizer.sanitize_list("a,b,c", :not_a_binary)
    end

    test "binary input with nil separator still returns invalid_input (P0-2 fix)" do
      assert {:error, :invalid_input} = Sanitizer.sanitize_list("a,b,c", nil)
    end
  end
end
