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
  alias Pote.Conversions

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

  def linear(_from, _to, 0), do: []
  def linear(from, _to, 1), do: [from]

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
    segment_count = length(colors) - 1
    steps_per_segment = max(1, div(steps - 1, segment_count))

    colors
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.with_index()
    |> Enum.flat_map(fn {[from, to], segment_idx} ->
      process_segment(from, to, segment_idx, segment_count, steps_per_segment, steps)
    end)
  end

  defp process_segment(from, to, segment_idx, segment_count, steps_per_segment, total_steps) do
    is_last = segment_idx == segment_count - 1

    segment_steps =
      if is_last, do: total_steps - segment_idx * steps_per_segment, else: steps_per_segment

    range_end = if is_last, do: segment_steps - 1, else: segment_steps

    stops =
      Enum.map(0..range_end, fn i ->
        t = i / max(1, range_end)
        interpolate(from, to, t)
      end)

    if is_last, do: stops, else: Enum.drop(stops, -1)
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
  Converts a list of RGB tuples to their corresponding HSL tuples.

  Useful for analyzing or transforming gradient stops in HSL space.
  """
  @spec to_hsl_stops([rgb()]) :: [Conversions.hsl()]
  def to_hsl_stops(colors) do
    Enum.map(colors, &Conversions.rgb_to_hsl/1)
  end

  @spec interpolate(rgb(), rgb(), float()) :: rgb()
  defp interpolate({r1, g1, b1}, {r2, g2, b2}, t) do
    r = round(r1 + (r2 - r1) * t)
    g = round(g1 + (g2 - g1) * t)
    b = round(b1 + (b2 - b1) * t)

    {Conversions.clamp(r), Conversions.clamp(g), Conversions.clamp(b)}
  end
end
