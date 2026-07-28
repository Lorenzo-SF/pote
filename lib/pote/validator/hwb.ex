defmodule Pote.Validator.HWB do
  @moduledoc """
  HWB (Hue-Whiteness-Blackness) color string validation.

  Splits out HWB-specific validation from `Pote.Validator`.

  Not part of the public API — used only by `Pote.Validator`.
  """

  alias Pote.Validator.Parser

  @doc """
  Validates an HWB color code: `H,W,B` (H: 0-360 degrees, W/B: 0.0-1.0).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(code) do
    parts = String.split(code, ",")

    if length(parts) != 3 do
      {:error, :hwb_wrong_part_count}
    else
      [h, w, b] = Enum.map(parts, &String.trim/1)

      with {:ok, _} <- Parser.parse_hue(h),
           {:ok, _} <- Parser.parse_normalized(w),
           {:ok, _} <- Parser.parse_normalized(b) do
        :ok
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Returns error messages for HWB validation errors.
  """
  @spec error_message(atom()) :: String.t()
  def error_message(:hwb_wrong_part_count),
    do: "HWB format requires exactly 3 values: H,W,B"

  def error_message(:ratio_out_of_range),
    do: "HWB whiteness/blackness must be between 0.0 and 1.0"

  def error_message(:invalid_ratio),
    do: "HWB whiteness/blackness must be a number between 0.0 and 1.0"
end
