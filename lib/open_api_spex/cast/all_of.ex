defmodule OpenApiSpex.Cast.AllOf do
  @moduledoc false
  alias OpenApiSpex.Cast
  alias OpenApiSpex.Schema

  def cast(ctx), do: cast_all_of(ctx, nil)

  defp cast_all_of(%{schema: %{allOf: [%Schema{type: :array} = schema | remaining]}} = ctx, acc)
       when is_list(acc) or acc == nil do
    # Since we parse a multi-type array, acc has to be a list or nil
    acc = acc || []

    case Cast.cast(%{ctx | schema: schema}) do
      {:ok, value} when is_list(value) ->
        # Since the cast for the list didn't result in a cast error,
        # we do not proceed the values through the remaining schemas
        {:ok, Enum.concat(acc, value)}

      {:error, errors} ->
        with {:ok, cleaned_ctx} <- reject_error_values(ctx, errors) do
          case Cast.cast(cleaned_ctx) do
            {:ok, cleaned_values} ->
              new_ctx = put_in(ctx.schema.allOf, remaining)
              new_ctx = update_in(new_ctx.value, fn values -> values -- cleaned_ctx.value end)
              cast_all_of(new_ctx, Enum.concat(acc, cleaned_values))
          end
        else
          _ -> Cast.error(ctx, {:all_of, to_string(schema.title || schema.type)})
        end
    end
  end

  defp cast_all_of(%{schema: %{allOf: [%Schema{} = schema | remaining]}} = ctx, acc) do
    relaxed_schema = %{schema | "x-struct": nil}
    new_ctx = put_in(ctx.schema.allOf, remaining)

    case Cast.cast(%{ctx | errors: [], schema: relaxed_schema}) do
      {:ok, value} when is_map(value) ->
        cast_all_of(new_ctx, Map.merge(acc || %{}, value))

      {:ok, value} ->
        # allOf definitions with primitives are a little bit strange..., we just return the cast for the first Schema,
        # but validate the values against every other schema as well, since the value must be compatible with all Schemas
        cast_all_of(new_ctx, acc || value)

      {:error, errors} ->
        ctx =
          if is_object?(relaxed_schema) do
            # Since in a allOf Schema, every
            %Cast{ctx | errors: ctx.errors ++ errors}
          else
            ctx
          end

        Cast.error(
          ctx,
          {:all_of, to_string(relaxed_schema.title || relaxed_schema.type)}
        )
    end
  end

  defp cast_all_of(%{schema: %{allOf: [schema | remaining]}} = ctx, result) do
    schema = OpenApiSpex.resolve_schema(schema, ctx.schemas)
    cast_all_of(%{ctx | schema: %{allOf: [schema | remaining]}}, result)
  end

  defp cast_all_of(%{schema: %{allOf: []}, errors: []}, acc) do
    # All values have been casted against the allOf schemas and there is no error - return accumulator
    {:ok, acc}
  end

  defp cast_all_of(%{schema: %{allOf: [], "x-struct": module}}, acc) when not is_nil(module),
    do: {:ok, struct(module, acc)}

  defp cast_all_of(%{schema: schema} = ctx, _acc) do
    Cast.error(ctx, {:all_of, to_string(schema.title || schema.type)})
  end

  defp reject_error_values(%{value: values} = ctx, [%{reason: :invalid_type} = error | tail]) do
    new_values = List.delete(values, error.value)
    reject_error_values(%{ctx | value: new_values}, tail)
  end

  defp reject_error_values(ctx, []) do
    # All errors should now be resolved for the current schema
    {:ok, ctx}
  end

  defp reject_error_values(_ctx, errors) do
    # Some errors couldn't be resolved, we break and return the remaining errors
    errors
  end

  defp is_object?(%{type: :object}), do: true
  defp is_object?(_), do: false
end
