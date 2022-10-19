defmodule OpenApiSpex.Cast.AnyOf do
  @moduledoc false
  alias OpenApiSpex.Cast
  alias OpenApiSpex.Cast.Utils
  alias OpenApiSpex.Schema

  def cast(ctx, failed_schemas \\ [], acc \\ :__not_casted),
    do: cast_any_of(ctx, failed_schemas, acc)

  defp cast_any_of(%_{schema: %{anyOf: []}} = ctx, failed_schemas, :__not_casted) do
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
      {:ok, value} when is_struct(value) ->
        {:ok, value}

      {:ok, value} when is_map(value) ->
        acc = acc |> value_if_not_casted(%{}) |> Utils.merge_maps(value)
        cast_any_of(new_ctx, failed_schemas, acc)

      {:ok, value} ->
        cast_any_of(new_ctx, failed_schemas, value_if_not_casted(acc, value))

      {:error, errors} ->
        cast_any_of(
          %Cast{new_ctx | errors: new_ctx.errors ++ errors},
          [schema | failed_schemas],
          acc
        )
    end
  end

  defp cast_any_of(
         %{schema: %{anyOf: [nested_schema | remaining]} = schema} = ctx,
         failed_schemas,
         acc
       ) do
    nested_schema = OpenApiSpex.resolve_schema(nested_schema, ctx.schemas)

    cast_any_of(
      %{ctx | schema: %{schema | anyOf: [nested_schema | remaining]}},
      failed_schemas,
      acc
    )
  end

  defp cast_any_of(%_{schema: %{anyOf: [], "x-struct": module}} = ctx, _failed_schemas, acc)
       when not is_nil(module) do
    with :ok <- Utils.check_required_fields(ctx, acc) do
      {:ok, struct(module, acc)}
    end
  end

  defp cast_any_of(%_{schema: %{anyOf: []}} = ctx, _failed_schemas, acc) do
    with :ok <- Utils.check_required_fields(ctx, acc) do
      {:ok, acc}
    end
  end

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

  defp value_if_not_casted(:__not_casted, value), do: value
  defp value_if_not_casted(value, _), do: value
end
