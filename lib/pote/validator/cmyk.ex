defmodule Pote.Validator.CMYK do
  @moduledoc """
  CMYK color string validation.

  Splits out CMYK-specific validation from `Pote.Validator`.

  Not part of the public API — used only by `Pote.Validator`.
  """

  alias Pote.Validator.Parser

  @doc """
  Validates a CMYK color code: `C,M,Y,K` (4 values 0-100%).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(code) do
    parts = String.split(code, ",")

    if length(parts) != 4 do
      {:error, :cmyk_wrong_part_count}
    else
      Enum.reduce_while(parts, :ok, fn part, :ok -> validate_part(part) end)
    end
  end

  defp validate_part(part) do
    case Parser.parse_percentage(String.trim(part)) do
      {:ok, _} -> {:cont, :ok}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  @doc """
  Returns error messages for CMYK validation errors.
  """
  @spec error_message(atom()) :: String.t()
  def error_message(:cmyk_wrong_part_count),
    do: "CMYK format requires exactly 4 values: C,M,Y,K"
end
