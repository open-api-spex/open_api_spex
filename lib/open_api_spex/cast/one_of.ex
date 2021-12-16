defmodule OpenApiSpex.Cast.OneOf do
  @moduledoc false
  alias OpenApiSpex.Cast
  alias OpenApiSpex.Schema

  def cast(%_{schema: %{type: _, oneOf: []}} = ctx) do
    error(ctx, [], [])
  end

  def cast(%{schema: %{type: _, oneOf: schemas} = properties} = ctx) do
    castable_schemas =
      Enum.reduce(schemas, {[], []}, fn schema, {results, error_schemas} ->
        schema =
          OpenApiSpex.resolve_schema(schema, ctx.schemas)
          |> put_required(properties)
          |> put_properties(properties)

        case Cast.cast(%{ctx | schema: schema}) do
          {:ok, value} -> {[{:ok, value, schema} | results], error_schemas}
          _error -> {results, [schema | error_schemas]}
        end
      end)

    case castable_schemas do
      {[{:ok, %_{} = value, _}], _} -> {:ok, value}
      {[{:ok, value, %Schema{"x-struct": nil}}], _} -> {:ok, value}
      {[{:ok, value, %Schema{"x-struct": module}}], _} -> {:ok, struct(module, value)}
      {success_results, failed_schemas} -> error(ctx, success_results, failed_schemas)
    end
  end

  ## Private functions

  defp put_properties(%{properties: schema_properties} = schema, %{properties: properties}) do
    new_properties = Map.merge(schema_properties, properties)

    Map.put(schema, :properties, new_properties)
  end

  defp put_properties(schema, _), do: schema

  defp put_required(schema, %{required: required}) do
    schema
    |> Map.put(:required, (schema.required || []) ++ (required || []))
  end

  defp put_required(schema, _), do: schema

  defp error(ctx, success_results, failed_schemas) do
    valid_schemas = Enum.map(success_results, &elem(&1, 2))

    message =
      case {valid_schemas, failed_schemas} do
        {[], []} -> "no schemas given"
        {[], _} -> "no schemas validate"
        {_, _} -> "more than one schemas validate"
      end

    Cast.error(
      ctx,
      {:one_of,
       %{
         message: message,
         failed_schemas: Enum.map(failed_schemas, &error_message_item/1),
         valid_schemas: Enum.map(valid_schemas, &error_message_item/1)
       }}
    )
  end

  defp error_message_item({:ok, _value, schema}) do
    error_message_item(schema)
  end

  defp error_message_item(schema) do
    case schema do
      %{title: title, type: type} when not is_nil(title) ->
        "Schema(title: #{inspect(title)}, type: #{inspect(type)})"

      %{type: type} ->
        "Schema(type: #{inspect(type)})"
    end
  end
end
