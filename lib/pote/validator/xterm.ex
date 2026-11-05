defmodule Pote.Validator.XTerm do
  @moduledoc """
  XTerm256 color index validation.

  Splits out XTerm-specific validation from `Pote.Validator`.

  Not part of the public API — used only by `Pote.Validator`.
  """

  @doc """
  Validates an XTerm256 color index (0-255).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(str) do
    str = String.trim(str)

    case Integer.parse(str) do
      {val, ""} when val in 0..255 -> :ok
      _ -> {:error, :xterm_out_of_range}
    end
  end

  @doc """
  Returns error message for XTerm256 validation errors.
  """
  @spec error_message(atom()) :: String.t()
  def error_message(:xterm_out_of_range),
    do: "XTerm256 index must be between 0 and 255"
end
