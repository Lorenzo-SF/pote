defmodule Pote.Validator.Hex do
  @moduledoc """
  Hex color string validation.

  Splits out the hex-specific validation from `Pote.Validator` so that
  the validator remains a thin façade dispatching to per-format modules.

  Not part of the public API — used only by `Pote.Validator`.

  Accepts:
    * `RRGGBB` (6 hex chars)
    * `#RRGGBB` (with optional `#` prefix)
  """

  @doc """
  Validates a hex color code (with or without `#` prefix).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(code) do
    code = String.replace(code, "#", "")

    if byte_size(code) == 6 and String.match?(code, ~r/^[0-9A-Fa-f]{6}$/) do
      :ok
    else
      {:error, :invalid_hex}
    end
  end

  @doc """
  Returns the error message for `:invalid_hex`.
  """
  @spec error_message(atom()) :: String.t()
  def error_message(:invalid_hex),
    do: "Hex color must be 6 hexadecimal characters (0-9, A-F)"
end
