defmodule OpenApiSpex.CastObject do
  @moduledoc false
  alias OpenApiSpex.{Cast, CastError, CastContext}

  def cast(%{value: value} = ctx) when not is_map(value) do
    CastContext.error(ctx, {:invalid_type, :object})
  end

  def cast(%{value: value, schema: %{properties: nil}}) do
    {:ok, value}
  end

  def cast(%{value: value, schema: schema} = ctx) do
    schema_properties = schema.properties || %{}

    with :ok <- check_unrecognized_properties(ctx, schema_properties),
         value = cast_atom_keys(value, schema_properties),
         ctx = %{ctx | value: value},
         :ok <- check_required_fields(ctx, schema),
         {:ok, value} <- cast_properties(%{ctx | schema: schema_properties}) do
      ctx = to_struct(%{ctx | value: value})
      {:ok, ctx}
    end
  end

  defp check_unrecognized_properties(%{value: value} = ctx, expected_keys) do
    input_keys = value |> Map.keys() |> Enum.map(&to_string/1)
    schema_keys = expected_keys |> Map.keys() |> Enum.map(&to_string/1)
    extra_keys = input_keys -- schema_keys

    if extra_keys == [] do
      :ok
    else
      [name | _] = extra_keys
      CastContext.error(ctx, {:unexpected_field, name})
    end
  end

  defp check_required_fields(%{value: input_map} = ctx, schema) do
    required = schema.required || []
    input_keys = Map.keys(input_map)
    missing_keys = required -- input_keys

    if missing_keys == [] do
      :ok
    else
      errors =
        Enum.map(missing_keys, fn key ->
          ctx = %{ctx | path: [key | ctx.path]}
          CastError.new(ctx, {:missing_field, key})
        end)

      {:error, ctx.errors ++ errors}
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

  defp cast_properties(%{value: object, schema: schema_properties} = ctx) do
    Enum.reduce(object, {:ok, %{}}, fn
      {key, value}, {:ok, output} ->
        cast_property(%{ctx | key: key, value: value, schema: schema_properties}, output)

      _, error ->
        error
    end)
  end

  defp cast_property(%{key: key, schema: schema_properties} = ctx, output) do
    prop_schema = Map.get(schema_properties, key)
    path = [key | ctx.path]

    with {:ok, value} <- Cast.cast(%{ctx | path: path, schema: prop_schema}) do
      {:ok, Map.put(output, key, value)}
    end
  end

  defp to_struct(%{value: value = %_{}}), do: value
  defp to_struct(%{value: value, schema: %{"x-struct": nil}}), do: value

  defp to_struct(%{value: value, schema: %{"x-struct": module}}),
    do: struct(module, value)
end
