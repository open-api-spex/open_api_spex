defmodule OpenApiSpex.Cast.OneOf do
  @moduledoc false
  alias OpenApiSpex.Cast
  alias OpenApiSpex.Schema

  def cast(%_{schema: %{type: _, oneOf: []}} = ctx) do
    error(ctx, [])
  end

  def cast(%{schema: %{type: _, oneOf: schemas}} = ctx) do
    castable_schemas =
      Enum.reduce(schemas, {[], [], 0}, fn schema, {results, error_schemas, count} ->
        schema = OpenApiSpex.resolve_schema(schema, ctx.schemas)

        case Cast.cast(%{ctx | schema: schema}) do
          {:ok, value} -> {[{:ok, value, schema} | results], error_schemas, count + 1}
          _error -> {results, [schema | error_schemas], count}
        end
      end)

    case castable_schemas do
      {[{:ok, %_{} = value, _}], _, 1} -> {:ok, value}
      {[{:ok, value, %Schema{"x-struct": nil}}], _, 1} -> {:ok, value}
      {[{:ok, value, %Schema{"x-struct": module}}], _, 1} -> {:ok, struct(module, value)}
      {success_schemas, _failed_schemas, count} when count > 1 -> error(ctx, success_schemas)
      {[], failed_schemas, _count} -> error(ctx, failed_schemas)
    end
  end

  ## Private functions

  defp error(ctx, results) do
    valid_schemas =
      results
      |> Enum.filter(&match?({:ok, _, _}, &1))
      |> Enum.map(&elem(&1, 2))

    failed_schemas = Enum.filter(results, &match?(%Schema{}, &1))

    message =
      case {valid_schemas, failed_schemas} do
        {[], []} -> "no schemas given"
        {[], _} -> "no schemas validate"
        {_, []} -> "more than one schema validate"
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
