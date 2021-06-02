defmodule OpenApiSpex.Cast.AnyOf do
  @moduledoc false
  alias OpenApiSpex.Cast

  def cast(ctx, failed_schemas \\ [], acc \\ nil)

  def cast(%_{schema: %{type: _, anyOf: []}} = ctx, failed_schemas, nil) do
    Cast.error(ctx, {:any_of, error_message(failed_schemas, ctx.schemas)})
  end

  def cast(
        %{schema: %{type: _, anyOf: [schema | remaining]}} = ctx,
        failed_schemas,
        acc
      ) do
    relaxed_schema = %{schema | additionalProperties: true, "x-struct": nil}
    new_ctx = put_in(ctx.schema.anyOf, remaining)

    case Cast.cast(%{ctx | schema: relaxed_schema}) do
      {:ok, value} when is_map(value) ->
        acc =
          value
          |> Enum.reject(fn {k, _} -> is_binary(k) end)
          |> Enum.concat(acc || %{})
          |> Map.new()

        cast(new_ctx, failed_schemas, acc)

      {:ok, value} ->
        cast(new_ctx, failed_schemas, acc || value)

      {:error, _} ->
        cast(new_ctx, [schema | failed_schemas], acc)
    end
  end

  def cast(%_{schema: %{type: _, anyOf: []}}, _failed_schemas, acc), do: {:ok, acc}

  ## Private functions

  defp error_message([], _) do
    "[] (no schemas provided)"
  end

  defp error_message(failed_schemas, schemas) do
    for schema <- failed_schemas do
      schema = OpenApiSpex.resolve_schema(schema, schemas)

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
