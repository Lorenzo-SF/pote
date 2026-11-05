defmodule Pote.Error do
  @moduledoc """
  Typed error returned by Pote APIs that parse or validate structured
  input (currently theme JSON loading).

  Unlike raising functions (`parse!/1`), the fallible variants
  (`parse/1`, `load_json/1`) return `{:error, %Pote.Error{}}` so
  callers can pattern-match on `kind` without string matching.

  ## Fields

    * `kind` - atom category of the error (`:invalid_theme`, ...)
    * `message` - human-readable explanation
    * `details` - optional extra context (e.g. the offending key)

  ## Examples

      iex> {:error, %Pote.Error{kind: :invalid_theme}} = Pote.Theme.parse("{bad json")
      true
  """

  @type t :: %__MODULE__{
          kind: atom(),
          message: String.t(),
          details: term()
        }

  defexception [:kind, :message, :details]

  @impl true
  def exception(opts) do
    kind = Keyword.fetch!(opts, :kind)
    message = Keyword.get(opts, :message, to_string(kind))
    details = Keyword.get(opts, :details)

    %__MODULE__{kind: kind, message: message, details: details}
  end

  @impl true
  def message(%__MODULE__{message: message}), do: message
end
