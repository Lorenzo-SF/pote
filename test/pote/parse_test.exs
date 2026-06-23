defmodule Pote.ParseTest do
  use ExUnit.Case, async: true

  alias Pote

  describe "parse/1" do
    test "parses hex string with #" do
      assert {:ok, {255, 0, 0}} = Pote.parse("#FF0000")
    end

    test "parses rgb tuple" do
      assert {:ok, {128, 64, 32}} = Pote.parse({128, 64, 32})
    end

    test "parses atom from palette" do
      assert {:ok, _rgb} = Pote.parse(:error)
    end

    test "parses xterm256 integer" do
      assert {:ok, {r, g, b}} = Pote.parse(42)
      assert is_integer(r) and is_integer(g) and is_integer(b)
    end

    test "returns error tuple for unrecognized input" do
      assert {:error, _} = Pote.parse("not_a_color")
    end
  end

  describe "parse!/1" do
    test "returns rgb on success" do
      assert {255, 0, 0} = Pote.parse!("#FF0000")
    end

    test "raises on failure" do
      assert_raise ArgumentError, fn -> Pote.parse!("invalid") end
    end
  end
end
