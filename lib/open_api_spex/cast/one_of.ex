defmodule OpenApiSpex.Cast.OneOf do
  @moduledoc false
  alias OpenApiSpex.Cast
  alias OpenApiSpex.Schema

  def cast(%_{schema: %{type: _, oneOf: []}} = ctx) do
    error(ctx, [])
  end

  def cast(%{schema: %{type: _, oneOf: schemas}} = ctx) do
    castable_schemas =
      Enum.reduce(schemas, {[], 0}, fn schema, {results, count} ->
        schema = OpenApiSpex.resolve_schema(schema, ctx.schemas)

        case Cast.cast(%{ctx | schema: %{schema | anyOf: nil}}) do
          {:ok, value} -> {[{:ok, value, schema} | results], count + 1}
          _ -> {results, count}
        end
      end)

    case castable_schemas do
      {[{:ok, value, %Schema{"x-struct": nil}}], 1} -> {:ok, value}
      {[{:ok, value, %Schema{"x-struct": module}}], 1} -> {:ok, struct(module, value)}
      {failed_schemas, _count} -> error(ctx, failed_schemas)
    end
  end

  ## Private functions

  defp error(ctx, failed_schemas) do
    Cast.error(ctx, {:one_of, error_message(failed_schemas)})
  end

  defp error_message([]) do
    "[] (no schemas provided)"
  end

  defp error_message(failed_schemas) do
    for {:ok, _value, schema} <- failed_schemas do
      case schema do
        %{title: title, type: type} when not is_nil(title) ->
          "Schema(title: #{inspect(title)}, type: #{inspect(type)})"

        %{type: type} ->
          "Schema(type: #{inspect(type)})"
      end
    end
    |> Enum.join(", ")
  end
end
