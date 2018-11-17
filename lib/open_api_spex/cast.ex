defmodule OpenApiSpex.Cast do
  alias OpenApiSpex.{CastPrimitive, Error}
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
    do: cast_object(value, schema, schemas)

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

  ## Object

  defp cast_object(value, %{properties: nil}, _schemas) do
    {:ok, value}
  end

  defp cast_object(value, schema, _schemas) do
    with :ok <- check_unrecognized_properties(value, schema.properties) do
      {:ok, cast_atom_keys(value, schema.properties)}
    end
  end

  defp check_unrecognized_properties(value, expected_keys) do
    input_keys = value |> Map.keys() |> Enum.map(&to_string/1)
    schema_keys = expected_keys |> Map.keys() |> Enum.map(&to_string/1)
    extra_keys = input_keys -- schema_keys

    if extra_keys == [] do
      :ok
    else
      [name | _] = extra_keys
      {:error, Error.new(:unexpected_field, name)}
    end
  end

  defp cast_atom_keys(input_map, properties) do
    Enum.reduce(properties, %{}, fn {key, _}, output ->
      string_key = to_string(key)

      case input_map do
        %{^key => value} -> Map.put(output, key, value)
        %{^string_key => value} -> Map.put(output, key, value)
        _ -> output
      end
    end)
  end
end
