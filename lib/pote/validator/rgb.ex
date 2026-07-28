defmodule Pote.Validator.RGB do
  @moduledoc """
  RGB and ARGB color string validation.

  Splits out the RGB/ARGB-specific validation from `Pote.Validator`.

  Not part of the public API — used only by `Pote.Validator`.
  """

  @doc """
  Validates an RGB color code: `R,G,B` (3 values 0-255).
  """
  @spec validate(String.t()) ::
          :ok | {:error, atom()}
  def validate(code) do
    parts = String.split(code, ",")

    if length(parts) != 3 do
      {:error, :rgb_wrong_part_count}
    else
      Enum.reduce_while(parts, :ok, fn part, :ok -> validate_part(part) end)
    end
  end

  @doc """
  Validates an ARGB color code: `A,R,G,B` (4 values 0-255).
  """
  @spec validate_argb(String.t()) ::
          :ok | {:error, atom()}
  def validate_argb(code) do
    parts = String.split(code, ",")

    if length(parts) != 4 do
      {:error, :argb_wrong_part_count}
    else
      Enum.reduce_while(parts, :ok, fn part, :ok -> validate_argb_part(part) end)
    end
  end

  defp validate_part(part) do
    case Integer.parse(String.trim(part)) do
      {val, ""} when val in 0..255 -> {:cont, :ok}
      _ -> {:halt, {:error, :rgb_value_out_of_range}}
    end
  end

  defp validate_argb_part(part) do
    case Integer.parse(String.trim(part)) do
      {val, ""} when val in 0..255 -> {:cont, :ok}
      _ -> {:halt, {:error, :argb_value_out_of_range}}
    end
  end

  @doc """
  Returns error messages for RGB/ARGB validation errors.
  """
  @spec error_message(atom()) :: String.t()
  def error_message(:rgb_value_out_of_range),
    do: "RGB values must be integers between 0 and 255"

  def error_message(:argb_value_out_of_range),
    do: "ARGB values must be integers between 0 and 255"

  def error_message(:rgb_wrong_part_count),
    do: "RGB format requires exactly 3 values: R,G,B"

  def error_message(:argb_wrong_part_count),
    do: "ARGB format requires exactly 4 values: A,R,G,B"
end
