defmodule OpenApiSpex.Cast do
  alias OpenApiSpex.{CastObject, CastPrimitive, Error}
  @primitives [:boolean, :integer, :number, :string]

  def cast(value, schema, schemas \\ nil)

  def cast(value, nil, _schemas),
    do: {:ok, value}

  def cast(value, %{type: type} = schema, _schemas) when type in @primitives do
    CastPrimitive.cast(value, schema)
  end

  def cast(value, %{type: :array} = schema, schemas),
    do: cast_array(value, schema, schemas)

  def cast(value, %{type: :object} = schema, schemas),
    do: CastObject.cast(value, schema, schemas)

  ## Private functions

  ## Array

  defp cast_array(_value, _schema, _schemas, index \\ 0)

  defp cast_array([], _schema, _schemas, _index) do
    {:ok, []}
  end

  defp cast_array([item | rest], schema, schemas, index) do
    with {:ok, cast_item} <- cast_array_item(item, schema.items, schemas, index),
         {:ok, cast_rest} <- cast_array(rest, schema, schemas, index + 1) do
      {:ok, [cast_item | cast_rest]}
    end
  end

  defp cast_array(value, _schema, _schemas, _index) do
    {:error, Error.new(:invalid_type, :array, value)}
  end

  defp cast_array_item(item, items_schema, schemas, index) do
    with {:error, error} <- cast(item, items_schema, schemas) do
      {:error, %{error | path: [index | error.path]}}
    end
  end
end
