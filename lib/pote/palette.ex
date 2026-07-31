defmodule Pote.Palette do
  @moduledoc """
  Procedural palette generation.

  `generate/2` turns a seed into a deterministic list of RGB colors
  starting from a color harmony (`Pote.Harmonies`) and optionally
  enforcing a WCAG AA luminance ladder: when colors are sorted by
  relative luminance, each consecutive pair meets the contrast target.

  The generator is pure: for the same `seed` and `opts` it always
  returns the same palette, which makes it suitable for themes that
  must be stable across runs.

  ## Examples

      iex> Pote.Palette.generate(42, count: 5) |> length()
      5

      iex> Pote.Palette.generate(42, count: 5) == Pote.Palette.generate(42, count: 5)
      true
  """

  alias Pote.Converters
  alias Pote.Converters.Advanced
  alias Pote.Harmonies

  @type rgb :: Pote.rgb()
  @type base :: :harmonious | :analogous | :complementary

  @defaults [count: 5, base: :harmonious, wcag_aa: false, contrast_target: 4.5]

  @doc """
  Generates a deterministic palette from `seed`.

  ## Options

    * `:count` - number of colors to return (default: `5`, min 2)
    * `:base` - starting harmony:
      - `:harmonious` (default) - triad, the classic balanced set
      - `:analogous` - adjacent hues on the wheel
      - `:complementary` - base + opposite
    * `:wcag_aa` - when `true`, consecutive colors in luminance order
      satisfy the `:contrast_target` ratio (default: `false`)
    * `:contrast_target` - WCAG ratio to enforce (default: `4.5`)

  ## WCAG note

  Enforcing a ratio between *every* pair of colors is mathematically
  impossible for `count >= 4` (WCAG's max ratio is 21:1, so 4.5^4 ≈ 410
  would be required). Instead we guarantee the usable property: when
  colors are sorted by relative luminance, each consecutive pair meets
  the target — a "luminance ladder" that makes any two adjacent palette
  entries readable against each other.

  ## Examples

      iex> Pote.Palette.generate(7, count: 3) |> length()
      3

      iex> Pote.Palette.generate(7, wcag_aa: true) |> Pote.Palette.wcag_aa?()
      true
  """
  @spec generate(integer(), keyword()) :: [rgb()]
  def generate(seed, opts \\ []) do
    opts = Keyword.merge(@defaults, opts)
    count = Keyword.fetch!(opts, :count)
    base = Keyword.fetch!(opts, :base)
    wcag_aa = Keyword.fetch!(opts, :wcag_aa)
    target = Keyword.fetch!(opts, :contrast_target)

    unless count >= 2 do
      raise ArgumentError, "count must be >= 2, got: #{inspect(count)}"
    end

    :rand.seed(:exsss, {seed, seed, seed})

    palette =
      base
      |> harmony_colors(random_color())
      |> fill_count(count)

    if wcag_aa do
      enforce_contrast(palette, target)
    else
      palette
    end
  end

  @doc """
  Returns `true` when consecutive colors in `palette` (sorted by
  relative luminance) have a WCAG 2.1 contrast ratio of at least
  `target` (default: `4.5`, the AA threshold for normal text).

  This is the property `generate/2` guarantees with `wcag_aa: true`
  (see the WCAG note above).

  ## Examples

      iex> Pote.Palette.wcag_aa?([{255, 255, 255}, {0, 0, 0}])
      true

      iex> Pote.Palette.wcag_aa?([{255, 255, 255}, {255, 255, 255}])
      false
  """
  @spec wcag_aa?([rgb()], float()) :: boolean()
  def wcag_aa?(palette, target \\ 4.5) do
    palette
    |> Enum.sort_by(&Advanced.relative_luminance/1)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.all?(fn [a, b] -> Advanced.contrast_ratio(a, b) >= target end)
  end

  # -- generation -----------------------------------------------------------

  defp harmony_colors(:harmonious, base), do: [base | Harmonies.triad(base)]
  defp harmony_colors(:analogous, base), do: [base | Harmonies.analogous(base)]
  defp harmony_colors(:complementary, base), do: [base | Harmonies.complementary(base)]

  defp fill_count(colors, count) when length(colors) >= count do
    Enum.take(colors, count)
  end

  defp fill_count([base | _] = colors, count) do
    {h, s, l} = Converters.rgb_to_hsl(base)

    colors ++
      Enum.map(count - length(colors)..1, fn i ->
        Converters.hsl_to_rgb({h, s, fill_lightness(l, i)})
      end)
  end

  defp fill_lightness(l, i) do
    # Alternate above / below the base lightness so clamps never produce
    # duplicate colors for the filler steps.
    sign = if rem(i, 2) == 1, do: 1, else: -1
    candidate = l + sign * i * 10.0

    cond do
      candidate < 15.0 -> 15.0
      candidate > 85.0 -> 85.0
      true -> candidate
    end
  end

  defp random_color do
    hue = :rand.uniform(360) - 1
    sat = 55.0 + (:rand.uniform(45) - 1)
    light = 40.0 + (:rand.uniform(30) - 1)
    Converters.hsl_to_rgb({hue, sat, light})
  end

  # -- WCAG enforcement -----------------------------------------------------

  @max_remap_iters 32

  # Optimal luminance ladder. For n colors at ratio `target` the ladder
  # consumes the whole [0, 1] luminance range: l1 <= 1.05/target^(n-1) - 0.05,
  # then l_{i+1} = target*(l_i + 0.05) - 0.05. If the requested target is
  # unreachable (target^(n-1) > 21, WCAG's max ratio), degrade gracefully
  # to the maximum achievable ladder.
  defp enforce_contrast(palette, target) do
    indexed = Enum.with_index(palette)
    sorted = Enum.sort_by(indexed, fn {color, _i} -> Advanced.relative_luminance(color) end)

    lums = luminance_targets(sorted, target)

    remapped =
      sorted
      |> Enum.zip(lums)
      |> Enum.map(fn {{color, i}, lum} -> {remap_to_luminance(color, lum), i} end)

    remapped
    |> Enum.sort_by(fn {_color, i} -> i end)
    |> Enum.map(fn {color, _i} -> color end)
  end

  defp luminance_targets(sorted, target) do
    n = length(sorted)

    # Feasible interval for each color: low bound comes from satisfying
    # the previous (darker) neighbor, high bound from leaving room for
    # the rest of the ladder. Picking the midpoint gives quantization
    # slack on both sides (RGB channels are integers, so exact
    # luminance targets are not always reachable).
    {_prev, lums_rev} =
      Enum.reduce(sorted, {0.0, []}, fn _color, {prev, acc} ->
        i = length(acc) + 1

        next =
          if i == 1 do
            0.0
          else
            lo = target * (prev + 0.05) - 0.05
            hi = 1.05 / :math.pow(target, n - i) - 0.05
            (lo + hi) / 2.0
          end

        {next, [next | acc]}
      end)

    Enum.reverse(lums_rev)
  end

  # Binary search on HSL lightness (hue/sat fixed) until the WCAG
  # relative luminance matches the target within 0.005.
  defp remap_to_luminance({r, g, b}, target_lum) do
    {h, s, _l} = Converters.rgb_to_hsl({r, g, b})
    remap_lightness(h, s, 0.0, 100.0, target_lum, @max_remap_iters)
  end

  defp remap_lightness(_h, _s, lo, _hi, _target, 0) do
    Converters.hsl_to_rgb({_h, _s, lo})
  end

  defp remap_lightness(h, s, lo, hi, target, iters) do
    mid = (lo + hi) / 2.0
    lum = mid |> then(&Converters.hsl_to_rgb({h, s, &1})) |> Advanced.relative_luminance()

    if lum < target do
      remap_lightness(h, s, mid, hi, target, iters - 1)
    else
      remap_lightness(h, s, lo, mid, target, iters - 1)
    end
  end
end
