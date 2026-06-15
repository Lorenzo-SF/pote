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
  """
  @spec sanitize(String.t()) :: String.t()
  def sanitize(input) do
    input
    |> String.trim()
    |> String.replace(~r/(º|degrees|deg|%)/i, "")
    |> String.trim()
  end

  @doc """
  Cleans a list of strings or a delimiter-separated string.
  Useful for inputs like "360º, 50%, 50%".
  """
  @spec sanitize_list(any(), String.t()) :: {:ok, list(String.t())} | :error
  def sanitize_list(input, separator) when is_binary(input) do
    case String.split(input, separator) |> Enum.map(&sanitize/1) do
      parts -> {:ok, parts}
    end
  rescue
    _ -> :error
  end

  @spec sanitize_list(list(String.t()), nil) :: {:ok, list(String.t())} | :error
  def sanitize_list(list, nil) when is_list(list) do
    {:ok, Enum.map(list, &sanitize/1)}
  end

  def sanitize_list(_list, nil), do: :error
end
