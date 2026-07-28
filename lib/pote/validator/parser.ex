defmodule Pote.Validator.Parser do
  @moduledoc """
  Internal parser helpers used by `Pote.Validator`.

  Splits out the numeric parsing (hue, percentage, normalized, decimals)
  from the format dispatch logic so that `Pote.Validator` remains a thin
  façade.

  Not part of the public API — used only by `Pote.Validator`.
  """

  @doc """
  Parses a hue string (0-360 degrees, up to 2 decimal places).
  """
  @spec parse_hue(String.t()) :: {:ok, float()} | {:error, atom()}
  def parse_hue(str) do
    str = String.trim(str) |> String.replace("°", "")

    case Float.parse(str) do
      {val, ""} ->
        if val >= 0 and val <= 360 and valid_decimals?(str, 2) do
          {:ok, val}
        else
          {:error, :hue_out_of_range}
        end

      _ ->
        {:error, :invalid_hue}
    end
  end

  @doc """
  Parses a normalized value (0.0-1.0, up to 2 decimal places).
  """
  @spec parse_normalized(String.t()) :: {:ok, float()} | {:error, atom()}
  def parse_normalized(str) do
    str = String.trim(str)

    case Float.parse(str) do
      {val, ""} ->
        if val >= 0 and val <= 1.0 and valid_decimals?(str, 2) do
          {:ok, val}
        else
          {:error, :ratio_out_of_range}
        end

      _ ->
        {:error, :invalid_ratio}
    end
  end

  @doc """
  Parses a percentage (0-100, up to 2 decimal places).
  """
  @spec parse_percentage(String.t()) :: {:ok, float()} | {:error, atom()}
  def parse_percentage(str) do
    str = String.trim(str) |> String.replace("%", "")

    case Float.parse(str) do
      {val, ""} ->
        if val >= 0 and val <= 100.0 and valid_decimals?(str, 2) do
          {:ok, val}
        else
          {:error, :percentage_out_of_range}
        end

      _ ->
        {:error, :invalid_percentage}
    end
  end

  @doc """
  Validates that a string has at most `max_decimals` decimal places.
  """
  @spec valid_decimals?(String.t(), non_neg_integer()) :: boolean()
  def valid_decimals?(str, max_decimals) do
    if String.contains?(str, ".") do
      [_, dec] = String.split(str, ".")
      String.length(dec) <= max_decimals
    else
      true
    end
  end
end
