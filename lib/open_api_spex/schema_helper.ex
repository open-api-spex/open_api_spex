defmodule OpenApiSpex.SchemaHelper do
  def term_type(v) when is_list(v), do: :array
  def term_type(v) when is_map(v), do: :object
  def term_type(v) when is_binary(v), do: :string
  def term_type(v) when is_boolean(v), do: :boolean
  def term_type(v) when is_integer(v), do: :integer
  def term_type(v) when is_number(v), do: :number
  def term_type(v) when is_nil(v), do: nil
  def term_type(v), do: inspect(v)
end
