defmodule OpenApiSpex.CastObject do
  @moduledoc false
  alias OpenApiSpex.Error

  def cast(value, schema, schemas \\ %{})

  def cast(value, %{properties: nil}, _schemas) do
    {:ok, value}
  end

  def cast(value, schema, _schemas) do
    with :ok <- check_unrecognized_properties(value, schema.properties),
         value <- cast_atom_keys(value, schema.properties),
         :ok <- check_required_fields(value, schema) do
      {:ok, value}
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

  defp check_required_fields(input_map, schema) do
    required = schema.required || []
    input_keys = Map.keys(input_map)
    missing_keys = required -- input_keys

    if missing_keys == [] do
      :ok
    else
      [key | _] = missing_keys
      {:error, Error.new(:missing_field, key)}
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
