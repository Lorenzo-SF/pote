defmodule Pote.Gradients do
  @moduledoc """
  Linear and multi-stop color gradient generation.

  All operations are pure functions returning lists of RGB tuples
  or iodata-ready ANSI strings for terminal output.

  Type aliases defined here reference the canonical types in `Pote`.

  ## Usage

      iex> Pote.Gradients.linear({255, 0, 0}, {0, 0, 255}, 5)
      [{255, 0, 0}, {191, 0, 64}, {128, 0, 128}, {64, 0, 191}, {0, 0, 255}]

      iex> Pote.Gradients.apply_to_text("Hello", {255, 0, 0}, {0, 0, 255})
      # returns iodata with ANSI sequences applying the gradient to each character
  """

  alias Pote
  alias Pote.Converters
  alias Pote.Converters.RGB

  @type rgb :: Pote.rgb()
  @type direction :: :left_to_right | :right_to_left | :top_to_bottom | :bottom_to_top

  @doc """
  Generates a linear gradient between two colors.

  Returns `steps` RGB tuples evenly interpolated from `from` to `to`.

  ## Parameters

  - `from` - Start color as RGB tuple
  - `to` - End color as RGB tuple
  - `steps` - Number of color stops (minimum 2)

  ## Examples

      iex> linear({255, 0, 0}, {0, 0, 255}, 3)
      [{255, 0, 0}, {128, 0, 128}, {0, 0, 255}]
  """
  @spec linear(rgb(), rgb(), pos_integer()) :: [rgb()]
  def linear(from, to, steps) when steps >= 2 do
    Enum.map(0..(steps - 1), fn i ->
      t = i / (steps - 1)
      interpolate(from, to, t)
    end)
  end

  @doc """
  Generates a multi-stop gradient across a list of colors.

  Returns `steps` total RGB tuples interpolated across all provided
  color stops with equal spacing between stops.

  ## Parameters

  - `colors` - List of RGB tuples (minimum 2)
  - `steps` - Total number of output colors

  ## Examples

      iex> multicolor([{255,0,0}, {0,255,0}, {0,0,255}], 5)
      [{255, 0, 0}, {128, 128, 0}, {0, 255, 0}, {0, 128, 128}, {0, 0, 255}]
  """
  @spec multicolor([rgb()], pos_integer()) :: [rgb()]
  def multicolor([], _steps), do: []
  def multicolor([color], _steps), do: [color]

  def multicolor(colors, steps) when length(colors) >= 2 do
    n = length(colors)

    if steps < n do
      Enum.map(0..(steps - 1), fn i ->
        Enum.at(colors, round(i * (n - 1) / (steps - 1)))
      end)
    else
      segment_count = n - 1
      total_intervals = steps - 1

      colors
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.with_index()
      |> Enum.flat_map(fn {[from, to], segment_idx} ->
        multicolor_segment(from, to, segment_idx, segment_count, total_intervals)
      end)
    end
  end

  defp multicolor_segment(from, to, segment_idx, segment_count, total_intervals) do
    intervals =
      ceil((segment_idx + 1) * total_intervals / segment_count) -
        ceil(segment_idx * total_intervals / segment_count)

    stops =
      Enum.map(0..intervals, fn i ->
        t = if intervals > 0, do: i / intervals, else: 0.5
        interpolate(from, to, t)
      end)

    if segment_idx == segment_count - 1, do: stops, else: Enum.drop(stops, -1)
  end

  @doc """
  Applies a gradient to a text string, coloring each character individually.

  Returns iodata with ANSI escape sequences applying the gradient
  from `from` color to `to` color across the full string length.

  ## Parameters

  - `text` - The string to colorize
  - `from` - Start color
  - `to` - End color
  - `direction` - Direction of the gradient (default: `:left_to_right`)

  ## Examples

      iex> apply_to_text("Hi", {255, 0, 0}, {0, 0, 255})
      # iodata with each char in a gradient color
  """
  @spec apply_to_text(String.t(), rgb(), rgb(), direction()) :: iodata()
  def apply_to_text(text, from, to, direction \\ :left_to_right) do
    chars = String.graphemes(text)
    count = length(chars)
    colors = get_gradient_colors(from, to, count, direction)

    chars
    |> Enum.with_index()
    |> Enum.map(fn {char, i} ->
      {r, g, b} = Enum.at(colors, i, to)
      ["\e[38;2;#{r};#{g};#{b}m", char]
    end)
    |> then(fn parts -> [parts, "\e[0m"] end)
  end

  defp get_gradient_colors(from, to, count, :right_to_left), do: linear(to, from, max(count, 2))
  defp get_gradient_colors(from, to, count, _), do: linear(from, to, max(count, 2))

  @doc """
  Applies a gradient background to a text string.

  Similar to `apply_to_text/4` but applies the gradient to the background color
  instead of the foreground, using a contrasting text color.

  ## Parameters

  - `text` - The string to colorize
  - `from` - Start background color
  - `to` - End background color
  - `text_color` - Foreground color for the text (default: white)
  """
  @spec apply_bg_to_text(String.t(), rgb(), rgb(), rgb()) :: iodata()
  def apply_bg_to_text(text, from, to, text_color \\ {255, 255, 255}) do
    {tr, tg, tb} = text_color
    chars = String.graphemes(text)
    count = length(chars)
    colors = linear(from, to, max(count, 2))

    chars
    |> Enum.with_index()
    |> Enum.map(fn {char, i} ->
      {r, g, b} = Enum.at(colors, i, to)
      ["\e[48;2;#{r};#{g};#{b}m\e[38;2;#{tr};#{tg};#{tb}m", char]
    end)
    |> then(fn parts -> [parts, "\e[0m"] end)
  end

  @doc """
  Generates a vertical gradient as a list of lines where each line
  gets a different color stop.

  Useful for rendering gradient backgrounds in multi-line UI areas.

  ## Parameters

  - `from` - Top color
  - `to` - Bottom color
  - `lines` - Number of lines (height of the area)
  - `width` - Width in characters of each line
  - `char` - Fill character (default: space `" "`)
  """
  @spec vertical_fill(rgb(), rgb(), pos_integer(), pos_integer(), String.t()) :: iodata()
  def vertical_fill(from, to, lines, width, char \\ " ") do
    colors = linear(from, to, max(lines, 2))
    row = String.duplicate(char, width)

    colors
    |> Enum.map(fn {r, g, b} ->
      ["\e[48;2;#{r};#{g};#{b}m", row, "\e[0m\n"]
    end)
  end

  @doc """
  Generates a linear gradient interpolating in CIELAB space.

  Same API as `linear/3` (RGB endpoints, `steps` RGB results) but the
  interpolation happens in perceptual LAB space, which avoids the
  "muddy middle gray" that direct RGB interpolation produces between
  saturated colors.

  ## Examples

      iex> linear_lab({255, 0, 0}, {0, 0, 255}, 3) |> length()
      3
  """
  @spec linear_lab(rgb(), rgb(), pos_integer()) :: [rgb()]
  def linear_lab(from, to, steps) when steps >= 2 do
    {fl, fa, fb} = Converters.Advanced.to_lab(from)
    {tl, ta, tb} = Converters.Advanced.to_lab(to)

    Enum.map(0..(steps - 1), fn i ->
      t = i / (steps - 1)
      {l, a, b} = {fl + (tl - fl) * t, fa + (ta - fa) * t, fb + (tb - fb) * t}
      Converters.Advanced.from_lab({l, a, b})
    end)
  end

  @doc """
  Generates a linear gradient interpolating in OKLCH space.

  Same API as `linear/3`. Interpolates lightness, chroma and hue
  (taking the shortest hue path), producing perceptually even steps —
  the current best practice for smooth color transitions.

  ## Examples

      iex> linear_oklch({255, 0, 0}, {0, 0, 255}, 3) |> length()
      3
  """
  @spec linear_oklch(rgb(), rgb(), pos_integer()) :: [rgb()]
  def linear_oklch(from, to, steps) when steps >= 2 do
    {fl, fc, fh} = Converters.Advanced.to_oklch(from)
    {tl, tc, th} = Converters.Advanced.to_oklch(to)
    dh = shortest_hue_delta(fh, th)

    Enum.map(0..(steps - 1), fn i ->
      t = i / (steps - 1)
      l = fl + (tl - fl) * t
      c = fc + (tc - fc) * t
      h = wrap_hue(fh + dh * t)
      Converters.Advanced.from_oklch({l, c, h})
    end)
  end

  defp shortest_hue_delta(from, to) do
    delta = to - from

    cond do
      delta > 180.0 -> delta - 360.0
      delta < -180.0 -> delta + 360.0
      true -> delta
    end
  end

  defp wrap_hue(h) when h < 0, do: h + 360.0
  defp wrap_hue(h) when h >= 360, do: h - 360.0
  defp wrap_hue(h), do: h

  @doc """
  Converts a list of RGB tuples to their corresponding HSL tuples.

  Useful for analyzing or transforming gradient stops in HSL space.
  """
  @spec to_hsl_stops([rgb()]) :: [Pote.hsl()]
  def to_hsl_stops(colors) do
    Enum.map(colors, &Converters.rgb_to_hsl/1)
  end

  defp interpolate({r1, g1, b1}, {r2, g2, b2}, t) do
    r = round(r1 + (r2 - r1) * t)
    g = round(g1 + (g2 - g1) * t)
    b = round(b1 + (b2 - b1) * t)

    {RGB.clamp(r), RGB.clamp(g), RGB.clamp(b)}
  end
end
