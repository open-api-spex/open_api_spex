defmodule OpenApiSpex.TermType do
  @moduledoc false

  alias OpenApiSpex.Schema

  @spec type(term) :: Schema.data_type() | nil | String.t()
  def type(v) when is_list(v), do: :array
  def type(v) when is_map(v), do: :object
  def type(v) when is_binary(v), do: :string
  def type(v) when is_boolean(v), do: :boolean
  def type(v) when is_integer(v), do: :integer
  def type(v) when is_number(v), do: :number
  def type(v) when is_nil(v), do: nil
  def type(_), do: :unknown
end
