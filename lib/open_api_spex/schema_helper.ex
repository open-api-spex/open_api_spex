defmodule OpenApiSpex.SchemaHelper do
  def convert_type(v) when is_list(v), do: :array
  def convert_type(v) when is_map(v), do: :object
  def convert_type(v) when is_binary(v), do: :string
  def convert_type(v) when is_boolean(v), do: :boolean
  def convert_type(v) when is_integer(v), do: :integer
  def convert_type(v) when is_number(v), do: :number
  def convert_type(v) when is_nil(v), do: nil
  def convert_type(v), do: inspect(v)
end
