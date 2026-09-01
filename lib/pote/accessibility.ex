defmodule Pote.Accessibility do
  @moduledoc """
  Color-blindness simulation helpers.

  `simulate/2` applies the standard dichromacy simulation matrices from
  Machado, Oliveira and Fernandes ("A Physiologically-based Model for
  Simulation of Color Vision Deficiency", 2009) to an RGB color.

  Supported deficiencies:

    * `:protanopia` - missing L cone (red-blind)
    * `:deuteranopia` - missing M cone (green-blind)
    * `:tritanopia` - missing S cone (blue-blind)

  The simulation is useful to check that palette choices remain
  distinguishable for color-blind users.

  ## Examples

      iex> Pote.Accessibility.simulate({255, 0, 0}, :protanopia)
      {39, 29, 0}
  """

  @type deficiency :: :protanopia | :deuteranopia | :tritanopia

  # Machado et al. 2009 — anomaly matrices for full deficiency (1.0).
  @matrices %{
    protanopia: [
      [0.152286, 1.052583, -0.204868],
      [0.114503, 0.786281, 0.099216],
      [-0.003882, -0.048116, 1.051998]
    ],
    deuteranopia: [
      [0.367322, 0.860646, -0.227968],
      [0.280085, 0.672501, 0.047413],
      [-0.011820, 0.042940, 0.968881]
    ],
    tritanopia: [
      [1.255528, -0.076749, -0.178779],
      [-0.078411, 0.930809, 0.147602],
      [0.004733, 0.691367, 0.303900]
    ]
  }

  @doc """
  Simulates how a person with `deficiency` perceives the given RGB
  color, returning the simulated RGB tuple.

  ## Examples

      iex> Pote.Accessibility.simulate({255, 0, 0}, :protanopia)
      {39, 29, 0}

      iex> Pote.Accessibility.simulate({0, 255, 0}, :deuteranopia)
      {219, 171, 11}
  """
  @spec simulate(Pote.rgb(), deficiency()) :: Pote.rgb()
  def simulate({r, g, b}, deficiency)
      when deficiency in [:protanopia, :deuteranopia, :tritanopia] do
    matrix = Map.fetch!(@matrices, deficiency)

    [r, g, b]
    |> apply_matrix(matrix)
    |> Enum.map(&clamp/1)
    |> List.to_tuple()
  end

  @doc """
  Returns `true` when two colors remain distinguishable (WCAG contrast
  ratio above `threshold`, default 3.0 — large-text AA) after
  simulating `deficiency`.

  ## Examples

      iex> Pote.Accessibility.distinguishable?({255, 0, 0}, {0, 255, 0}, :protanopia)
      true
  """
  @spec distinguishable?(Pote.rgb(), Pote.rgb(), deficiency(), float()) :: boolean()
  def distinguishable?(c1, c2, deficiency, threshold \\ 3.0) do
    import Pote.Converters.Advanced, only: [contrast_ratio: 2]

    s1 = simulate(c1, deficiency)
    s2 = simulate(c2, deficiency)
    contrast_ratio(s1, s2) >= threshold
  end

  defp apply_matrix(channels, matrix) do
    Enum.map(matrix, fn row ->
      row
      |> Enum.zip(channels)
      |> Enum.map(fn {coef, value} -> coef * value end)
      |> Enum.sum()
      |> round()
    end)
  end

  defp clamp(v), do: min(max(v, 0), 255)
end
