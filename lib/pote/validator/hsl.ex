defmodule Pote.Validator.HSL do
  @moduledoc """
  HSL and HSV color string validation.

  Splits out HSL/HSV-specific validation from `Pote.Validator`.

  Not part of the public API — used only by `Pote.Validator`.
  """

  alias Pote.Validator.Parser

  @doc """
  Validates an HSL color code: `H,S,L` (H: 0-360 degrees, S/L: 0-100%).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(code) do
    parts = String.split(code, ",")

    if length(parts) != 3 do
      {:error, :hsl_wrong_part_count}
    else
      [h_str, s_str, l_str] = parts

      with {:ok, _h} <- Parser.parse_hue(h_str),
           {:ok, _s} <- Parser.parse_percentage(s_str),
           {:ok, _l} <- Parser.parse_percentage(l_str) do
        :ok
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Validates an HSV color code: `H,S,V` (H: 0-360 degrees, S/V: 0-100%).
  """
  @spec validate_hsv(String.t()) :: :ok | {:error, atom()}
  def validate_hsv(code) do
    parts = String.split(code, ",")

    if length(parts) != 3 do
      {:error, :hsv_wrong_part_count}
    else
      [h_str, s_str, v_str] = parts

      with {:ok, _h} <- Parser.parse_hue(h_str),
           {:ok, _s} <- Parser.parse_percentage(s_str),
           {:ok, _v} <- Parser.parse_percentage(v_str) do
        :ok
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Returns error messages for HSL/HSV validation errors.
  """
  @spec error_message(atom()) :: String.t()
  def error_message(:hue_out_of_range),
    do: "Hue must be between 0.00 and 360.00 degrees"

  def error_message(:invalid_hue),
    do: "Hue must be a number between 0 and 360"

  def error_message(:percentage_out_of_range),
    do: "Percentage must be between 0 and 100"

  def error_message(:invalid_percentage),
    do: "Percentage must be a number between 0 and 100"

  def error_message(:hsl_wrong_part_count),
    do: "HSL format requires exactly 3 values: H,S,L"

  def error_message(:hsv_wrong_part_count),
    do: "HSV format requires exactly 3 values: H,S,V"
end
