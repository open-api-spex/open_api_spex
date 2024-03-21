defmodule OpenApiSpex.Cast.Object do
  @moduledoc false
  alias OpenApiSpex.Cast
  alias OpenApiSpex.Cast.Utils
  alias OpenApiSpex.Reference

  def cast(%{value: value} = ctx) when not is_map(value) do
    Cast.error(ctx, {:invalid_type, :object})
  end

  def cast(%{value: value, schema: %{properties: nil, additionalProperties: nil}}) do
    {:ok, value}
  end

  def cast(ctx) do
    ctx = handle_struct_value(ctx)

    with :ok <- check_unrecognized_properties(ctx),
         ctx = resolve_schema_properties_references(ctx),
         ctx = cast_atom_keys(ctx),
         {:ok, ctx} <- cast_additional_properties(ctx),
         :ok <- Utils.check_required_fields(ctx),
         :ok <- check_max_properties(ctx),
         :ok <- check_min_properties(ctx),
         {:ok, ctx} <- cast_properties(ctx) do
      ctx =
        ctx
        |> apply_defaults()
        |> to_struct()

      {:ok, ctx}
    end
  end

  defp resolve_schema_properties_references(%{schema: schema, schemas: schemas} = ctx) do
    schema_properties = schema.properties || %{}

    resolved_schema_properties =
      Enum.reduce(schema_properties, schema_properties, fn property, properties ->
        resolve_property_if_reference(property, properties, schemas)
      end)

    %{ctx | schema: %{schema | properties: resolved_schema_properties}}
  end

  defp resolve_property_if_reference({key, %Reference{} = reference}, properties, schemas) do
    Map.put(properties, key, Reference.resolve_schema(reference, schemas))
  end

  defp resolve_property_if_reference(_not_a_reference, properties, _schemas), do: properties

  # When additionalProperties is not false, extra properties are allowed in input
  defp check_unrecognized_properties(%{schema: %{additionalProperties: ap}}) when ap != false do
    :ok
  end

  defp check_unrecognized_properties(%{value: value, schema: schema} = ctx) do
    schema_properties = schema.properties || %{}
    input_keys = value |> Map.keys() |> Enum.map(&to_string/1)
    schema_keys = schema_properties |> Map.keys() |> Enum.map(&to_string/1)
    extra_keys = input_keys -- schema_keys

    if extra_keys == [] do
      :ok
    else
      [name | _] = extra_keys
      ctx = %{ctx | path: [name | ctx.path]}
      Cast.error(ctx, {:unexpected_field, name})
    end
  end

  defp check_max_properties(%{schema: %{maxProperties: max_properties}} = ctx)
       when is_integer(max_properties) do
    count = map_size(ctx.value)

    if count > max_properties do
      Cast.error(ctx, {:max_properties, max_properties, count})
    else
      :ok
    end
  end

  defp check_max_properties(_ctx), do: :ok

  defp check_min_properties(%{schema: %{minProperties: min_properties}} = ctx)
       when is_integer(min_properties) do
    count = map_size(ctx.value)

    if count < min_properties do
      Cast.error(ctx, {:min_properties, min_properties, count})
    else
      :ok
    end
  end

  defp check_min_properties(_ctx), do: :ok

  defp cast_atom_keys(%{value: input_map, schema: %{properties: properties}} = ctx) do
    value =
      Enum.reduce(properties, input_map, fn {key, _}, output ->
        string_key = to_string(key)

        if Map.has_key?(output, string_key) do
          {value, output} = Map.pop!(output, string_key)
          Map.put(output, key, value)
        else
          output
        end
      end)

    %{ctx | value: value}
  end

  defp cast_properties(%{value: object, schema: %{properties: schema_properties}} = ctx) do
    object
    |> Enum.reduce({%{}, []}, fn {key, value}, {output, object_errors} ->
      case cast_property(%{ctx | key: key, value: value, schema: schema_properties}, output) do
        {:ok, output} ->
          {output, object_errors}

        {:error, errors} ->
          {output, object_errors ++ errors}
      end
    end)
    |> case do
      {value, []} ->
        {:ok, %{ctx | value: value}}

      {_, errors} ->
        {:error, errors}
    end
  end

  defp cast_additional_properties(%{value: value, schema: %{additionalProperties: ap}} = ctx) do
    value
    |> get_additional_properties(ctx)
    |> Enum.reduce({:ok, ctx}, fn
      {key, value}, {:ok, ctx} ->
        ap_cast_context = %{ctx | key: key, value: value, path: [key | ctx.path], schema: ap}
        cast_additional_property(ap_cast_context, ctx)

      _, error ->
        error
    end)
  end

  defp get_additional_properties(value, ctx) do
    recognized_keys =
      (ctx.schema.properties || %{})
      |> Map.keys()
      |> Enum.flat_map(&[&1, to_string(&1)])
      |> MapSet.new()

    for {key, _value} = prop <- value, not MapSet.member?(recognized_keys, key) do
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

  defp apply_defaults(%{opts: opts, value: value, schema: %{properties: properties}} = ctx) do
    value =
      if Keyword.get(opts, :apply_defaults, true) do
        Enum.reduce(properties, value, &apply_default/2)
      else
        value
      end

    %{ctx | value: value}
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

  defp to_struct(%{value: value, schema: %{"x-struct": module}}) when not is_nil(module),
    do: struct(module, value)

  defp to_struct(%{value: value}), do: value

  defp handle_struct_value(%{value: %_{} = value, schema: %{"x-struct": module}} = ctx)
       when not is_nil(module) do
    %{ctx | value: Map.from_struct(value)}
  end

  defp handle_struct_value(%{value: %struct{} = value, schema: schema} = ctx) do
    %{ctx | value: Map.from_struct(value), schema: %{schema | "x-struct": struct}}
  end

  defp handle_struct_value(ctx), do: ctx
end
