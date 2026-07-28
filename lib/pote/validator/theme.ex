defmodule Pote.Validator.Theme do
  @moduledoc """
  Theme color name validation.

  Splits out theme-specific validation from `Pote.Validator`.

  Not part of the public API — used only by `Pote.Validator`.
  """

  @doc """
  Validates a theme color name (any valid Elixir-like identifier).

  Accepts any string matching `~r/^[a-zA-Z_][a-zA-Z0-9_]*$/` as a valid
  theme color name (the actual color is resolved at runtime from the
  active theme).
  """
  @spec validate(String.t()) :: :ok | {:error, atom()}
  def validate(color_name) do
    color_name = String.trim(color_name)

    if color_name != "" and String.match?(color_name, ~r/^[a-zA-Z_][a-zA-Z0-9_]*$/) do
      :ok
    else
      {:error, :invalid_theme_color_name}
    end
  end

  @doc """
  Returns error message for theme validation errors.
  """
  @spec error_message(atom()) :: String.t()
  def error_message(:invalid_theme_color_name),
    do: "Theme color name must be a valid identifier (e.g., primary, success, text)"
end
