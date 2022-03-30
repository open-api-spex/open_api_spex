defmodule OpenApiSpex.Cast.OneOf do
  @moduledoc false
  alias OpenApiSpex.Cast
  alias OpenApiSpex.Cast.Utils
  alias OpenApiSpex.Schema

  def cast(%_{schema: %{type: _, oneOf: []}} = ctx) do
    error(ctx, [], [])
  end

  def cast(%{schema: %{type: _, oneOf: schemas}} = ctx) do
    castable_schemas =
      Enum.reduce(schemas, {ctx, [], []}, fn schema, {ctx, results, error_schemas} ->
        schema = OpenApiSpex.resolve_schema(schema, ctx.schemas)
        relaxed_schema = %{schema | "x-struct": nil}

        with {:ok, value} <- Cast.cast(%{ctx | errors: [], schema: relaxed_schema}),
             :ok <- Utils.check_required_fields(ctx, value) do
          {ctx, [{:ok, value, schema} | results], error_schemas}
        else
          {:error, errors} ->
            {%Cast{ctx | errors: ctx.errors ++ errors}, results, [schema | error_schemas]}
        end
      end)

    case castable_schemas do
      {_, [{:ok, %_{} = value, _}], _} -> {:ok, value}
      {_, [{:ok, value, %Schema{"x-struct": nil}}], _} -> {:ok, value}
      {_, [{:ok, value, %Schema{"x-struct": module}}], _} -> {:ok, struct(module, value)}
      {ctx, success_results, failed_schemas} -> error(ctx, success_results, failed_schemas)
    end
  end

  ## Private functions

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
