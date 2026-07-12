defmodule Pote.Converters.Table do
  @moduledoc """
  Holds the conversion table mapping between color formats.
  For now, the table is empty. It should be populated with conversion
  lambdas from one format to another.
  """
  @spec get() :: map()
  def get, do: %{}
end
