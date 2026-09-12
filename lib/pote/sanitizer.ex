defmodule Pote.Sanitizer do
  @moduledoc """
  Handles cleaning user input for colour formats.

  Its purpose is to strip unit symbols (%, º, deg) from numeric values
  so that format modules can parse them without errors.
  """

  @doc """
  Cleans a string by removing common unit suffixes.
  Examples:
  - "360º" -> "360"
  - "50%" -> "50"
  - "12.5 deg" -> "12.5"

  Raises `ArgumentError` if the input is not a binary. Use
  `sanitize_list/2` for non-binary inputs (lists) or pre-validate.
  """
  @spec sanitize(String.t()) :: String.t()
  def sanitize(input) when is_binary(input) do
    input
    |> String.trim()
    |> String.replace(~r/(º|degrees|deg|%)/i, "")
    |> String.trim()
  end

  def sanitize(other) do
    raise ArgumentError,
          "Pote.Sanitizer.sanitize/1 expected a binary, got: #{inspect(other)}"
  end

  @doc """
  Cleans a list of strings or a delimiter-separated string.
  Useful for inputs like "360º, 50%, 50%".

  The binary variant returns `{:error, :invalid_input}` if the
  separator is invalid (not a binary). The list variant returns
  `{:error, :invalid_input}` if the input is not a list.
  """
  @spec sanitize_list(any(), String.t() | nil) ::
          {:ok, list(String.t())} | {:error, atom() | String.t()}
  def sanitize_list(input, separator) when is_binary(input) and is_binary(separator) do
    {:ok, input |> String.split(separator) |> Enum.map(&sanitize/1)}
  end

  def sanitize_list(_input, _separator), do: {:error, :invalid_input}
end
