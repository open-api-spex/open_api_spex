defmodule OpenApiSpex.Cast.AnyOf do
  @moduledoc false
  alias OpenApiSpex.Cast
  alias OpenApiSpex.Schema

  def cast(ctx, failed_schemas \\ [], acc \\ nil), do: cast_any_of(ctx, failed_schemas, acc)

  defp cast_any_of(%_{schema: %{anyOf: []}} = ctx, failed_schemas, nil) do
    Cast.error(ctx, {:any_of, error_message(failed_schemas, ctx.schemas)})
  end

  defp cast_any_of(
         %{schema: %{anyOf: [%Schema{} = schema | remaining]}} = ctx,
         failed_schemas,
         acc
       ) do
    relaxed_schema = %{schema | "x-struct": nil}
    new_ctx = put_in(ctx.schema.anyOf, remaining)

    case Cast.cast(%{ctx | errors: [], schema: relaxed_schema}) do
      {:ok, value} when is_map(value) ->
        cast_any_of(new_ctx, failed_schemas, Map.merge(acc || %{}, value))

      {:ok, value} ->
        cast_any_of(new_ctx, failed_schemas, acc || value)

      {:error, errors} ->
        new_ctx =
          if is_object?(relaxed_schema) do
            # Since in a allOf Schema, every
            %Cast{new_ctx | errors: new_ctx.errors ++ errors}
          else
            new_ctx
          end

        cast_any_of(new_ctx, [schema | failed_schemas], acc)
    end
  end

  defp cast_any_of(%{schema: %{anyOf: [schema | remaining]}} = ctx, failed_schemas, acc) do
    schema = OpenApiSpex.resolve_schema(schema, ctx.schemas)
    cast_any_of(%{ctx | schema: %{anyOf: [schema | remaining]}}, failed_schemas, acc)
  end

  defp cast_any_of(%_{schema: %{anyOf: [], "x-struct": module}}, _failed_schemas, acc)
       when not is_nil(module),
       do: {:ok, struct(module, acc)}

  defp cast_any_of(%_{schema: %{anyOf: []}}, _failed_schemas, acc), do: {:ok, acc}

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

  defp is_object?(%{type: :object}), do: true
  defp is_object?(_), do: false
end
