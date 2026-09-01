defmodule Pote.ContrastSnapshotTest do
  use ExUnit.Case
  alias Pote.Converters.Advanced

  # Deterministic snapshot of WCAG 2.1 contrast ratios for known
  # fg/bg pairs. Guards against regressions in relative_luminance/1 or
  # contrast_ratio/2. Values are rounded to 2 decimals like the
  # implementation.
  @snapshots [
    # name, fg, bg, expected ratio
    {"black on white", {0, 0, 0}, {255, 255, 255}, 21.0},
    {"white on black", {255, 255, 255}, {0, 0, 0}, 21.0},
    {"white on white", {255, 255, 255}, {255, 255, 255}, 1.0},
    {"black on black", {0, 0, 0}, {0, 0, 0}, 1.0},
    {"white on red", {255, 255, 255}, {255, 0, 0}, 4.0},
    {"red on white", {255, 0, 0}, {255, 255, 255}, 4.0},
    {"white on blue", {255, 255, 255}, {0, 0, 255}, 8.59},
    {"black on yellow", {0, 0, 0}, {255, 255, 0}, 19.56},
    {"gray on white", {128, 128, 128}, {255, 255, 255}, 3.95},
    {"light gray on dark", {200, 200, 200}, {40, 44, 52}, 8.37},
    {"pote success on bg", {151, 197, 60}, {40, 44, 52}, 6.91},
    {"pote primary on bg", {161, 231, 250}, {40, 44, 52}, 10.22},
    {"pote error on bg", {255, 91, 91}, {40, 44, 52}, 4.6},
    {"catppuccin text on base", {205, 214, 244}, {30, 30, 46}, 11.34}
  ]

  test "snapshot values match the implementation" do
    for {name, fg, bg, expected} <- @snapshots do
      assert Advanced.contrast_ratio(fg, bg) == expected,
             "#{name}: expected #{expected}, got #{Advanced.contrast_ratio(fg, bg)}"
    end
  end

  test "contrast_ratio is symmetric" do
    for {_name, fg, bg, _expected} <- @snapshots do
      assert Advanced.contrast_ratio(fg, bg) == Advanced.contrast_ratio(bg, fg)
    end
  end

  test "snapshot table has no duplicates" do
    names = Enum.map(@snapshots, &elem(&1, 0))
    assert length(names) == length(Enum.uniq(names))
  end
end
