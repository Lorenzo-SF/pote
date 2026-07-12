defmodule Pote.Converters.Generic do
  @moduledoc """
  General‑purpose color conversion engine.

  `convert/3` accepts two %{format: :rgb, ...} structs and a conversion table.
  If a conversion is defined in the table, the corresponding function is
  invoked with the *source* struct and the result is returned as `{:ok, result}`;
  otherwise `{:error, :unsupported}`.
  """

  @spec convert(Pote.ColorInfo.t(), Pote.ColorInfo.t(), map()) ::
          {:ok, Pote.ColorInfo.t()} | {:error, :unsupported}
  def convert(
        %Pote.ColorInfo{format: from} = from_ci,
        %Pote.ColorInfo{format: to} = _to_ci,
        table
      )
      when from != to do
    case Map.fetch(table, {from, to}) do
      {:ok, fun} -> {:ok, fun.(from_ci)}
      :error -> {:error, :unsupported}
    end
  end

  def convert(_from_ci, input_ci, _table), do: {:ok, input_ci}
end
