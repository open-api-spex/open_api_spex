defmodule OpenApiSpex.Cast.AllOf do
  @moduledoc false
  alias OpenApiSpex.Cast
  alias OpenApiSpex.Cast.Utils
  alias OpenApiSpex.Schema

  def cast(ctx), do: cast_all_of(ctx, nil)

  defp cast_all_of(%{schema: %{allOf: [%Schema{} = schema | remaining]}} = ctx, acc) do
    relaxed_schema = %{schema | "x-struct": nil}
    new_ctx = put_in(ctx.schema.allOf, remaining)

    case Cast.cast(%{ctx | errors: [], schema: relaxed_schema}) do
      {:ok, value} when is_map(value) ->
        cast_all_of(new_ctx, Utils.merge_maps(acc || %{}, value))

      {:ok, value} ->
        # allOf definitions with primitives are a little bit strange.
        # we just return the cast for the first Schema, but validate
        # the values against every other schema as well, since the value
        # must be compatible with all Schemas
        cast_all_of(new_ctx, acc || value)

      {:error, errors} ->
        Cast.error(
          %Cast{ctx | errors: ctx.errors ++ errors},
          {:all_of, to_string(relaxed_schema.title || relaxed_schema.type)}
        )
    end
  end

  defp cast_all_of(%{schema: %{allOf: [nested_schema | remaining]} = schema} = ctx, result) do
    nested_schema = OpenApiSpex.resolve_schema(nested_schema, ctx.schemas)
    cast_all_of(%{ctx | schema: %{schema | allOf: [nested_schema | remaining]}}, result)
  end

  defp cast_all_of(%{schema: %{allOf: [], "x-struct": module}, errors: []} = ctx, acc)
       when not is_nil(module) do
    with :ok <- Utils.check_required_fields(ctx, acc) do
      {:ok, struct(module, acc)}
    end
  end

  defp cast_all_of(%{schema: %{allOf: []}, errors: []} = ctx, acc) do
    with :ok <- Utils.check_required_fields(ctx, acc) do
      {:ok, acc}
    end
  end

  defp cast_all_of(%{schema: schema} = ctx, _acc) do
    Cast.error(ctx, {:all_of, to_string(schema.title || schema.type)})
  end
end
