defmodule OpenApiSpex.Cast.Object do
  @moduledoc false
  alias OpenApiSpex.Cast
  alias OpenApiSpex.Cast.Error

  def cast(%{value: value} = ctx) when not is_map(value) do
    Cast.error(ctx, {:invalid_type, :object})
  end

  def cast(%{value: value, schema: %{properties: nil}}) do
    {:ok, value}
  end

  def cast(%{value: value, schema: schema} = ctx) do
    original_value = value
    schema_properties = schema.properties || %{}

    with :ok <- check_unrecognized_properties(ctx, schema_properties),
         value = cast_atom_keys(value, schema_properties),
         ctx = %{ctx | value: value},
         {:ok, ctx} <- cast_additional_properties(ctx, original_value),
         :ok <- check_required_fields(ctx, schema),
         :ok <- check_max_properties(ctx),
         :ok <- check_min_properties(ctx),
         {:ok, value} <- cast_properties(%{ctx | schema: schema_properties}) do
      value_with_defaults = apply_defaults(value, schema_properties)
      ctx = to_struct(%{ctx | value: value_with_defaults})
      {:ok, ctx}
    end
  end

  # When additionalProperties is not false, extra properties are allowed in input
  defp check_unrecognized_properties(%{schema: %{additionalProperties: ap}}, _expected_keys)
       when ap != false do
    :ok
  end

  defp check_unrecognized_properties(%{value: value} = ctx, expected_keys) do
    input_keys = value |> Map.keys() |> Enum.map(&to_string/1)
    schema_keys = expected_keys |> Map.keys() |> Enum.map(&to_string/1)
    extra_keys = input_keys -- schema_keys

    if extra_keys == [] do
      :ok
    else
      [name | _] = extra_keys
      ctx = %{ctx | path: [name | ctx.path]}
      Cast.error(ctx, {:unexpected_field, name})
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
          Error.new(ctx, {:missing_field, key})
        end)

      {:error, ctx.errors ++ errors}
    end
  end

  defp check_max_properties(%{schema: %{maxProperties: max_properties}} = ctx)
       when is_integer(max_properties) do
    count = ctx.value |> Map.keys() |> length()

    if count > max_properties do
      Cast.error(ctx, {:max_properties, max_properties, count})
    else
      :ok
    end
  end

  defp check_max_properties(_ctx), do: :ok

  defp check_min_properties(%{schema: %{minProperties: min_properties}} = ctx)
       when is_integer(min_properties) do
    count = ctx.value |> Map.keys() |> length()

    if count < min_properties do
      Cast.error(ctx, {:min_properties, min_properties, count})
    else
      :ok
    end
  end

  defp check_min_properties(_ctx), do: :ok

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

  defp cast_additional_properties(%{schema: %{additionalProperties: ap}} = ctx, original_value) do
    original_value
    |> get_additional_properties(ctx)
    |> Enum.reduce({:ok, ctx}, fn
      {key, value}, {:ok, ctx} ->
        ap_cast_context = %{ctx | key: key, value: value, path: [key | ctx.path], schema: ap}
        cast_additional_property(ap_cast_context, ctx)

      _, error ->
        error
    end)
  end

  defp get_additional_properties(original_value, ctx) do
    recognized_keys =
      (ctx.schema.properties || %{})
      |> Map.keys()
      |> Enum.flat_map(&[&1, to_string(&1)])
      |> MapSet.new()

    for {key, _value} = prop <- original_value,
        not MapSet.member?(recognized_keys, key) do
      prop
    end
  end

  defp cast_additional_property(%{schema: ap} = ctx, output_ctx) when is_map(ap) do
    with {:ok, value} <- Cast.cast(ctx) do
      {:ok, %{output_ctx | value: Map.put(output_ctx.value, ctx.key, value)}}
    end
  end

  defp cast_additional_property(%{schema: ap} = ctx, output_ctx) when ap in [nil, true] do
    {:ok, %{output_ctx | value: Map.put(output_ctx.value, ctx.key, ctx.value)}}
  end

  defp cast_property(%{key: key, schema: schema_properties} = ctx, output) do
    prop_schema = Map.get(schema_properties, key)
    path = [key | ctx.path]

    with {:ok, value} <- Cast.cast(%{ctx | path: path, schema: prop_schema}) do
      {:ok, Map.put(output, key, value)}
    end
  end

  defp apply_defaults(object_value, schema_properties) do
    Enum.reduce(schema_properties, object_value, &apply_default/2)
  end

  defp apply_default({_key, %{default: nil}}, object_value), do: object_value

  defp apply_default({key, %{default: default_value}}, object_value) do
    if Map.has_key?(object_value, key) do
      object_value
    else
      Map.put(object_value, key, default_value)
    end
  end

  defp apply_default(_, object_value), do: object_value

  defp to_struct(%{value: value = %_{}}), do: value
  defp to_struct(%{value: value, schema: %{"x-struct": nil}}), do: value

  defp to_struct(%{value: value, schema: %{"x-struct": module}}),
    do: struct(module, value)
end
