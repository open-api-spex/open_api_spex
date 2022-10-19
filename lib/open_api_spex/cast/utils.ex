defmodule OpenApiSpex.Cast.Utils do
  @moduledoc false

  alias OpenApiSpex.Cast.Error

  # Merge 2 maps considering as equal keys that are atom or string representation
  # of that atom. Atom keys takes precedence over string ones.
  def merge_maps(map1, map2) do
    result = Map.merge(map1, map2)

    Enum.reduce(result, result, fn
      {k, _v}, result when is_atom(k) -> Map.delete(result, to_string(k))
      _, result -> result
    end)
  end

  def check_required_fields(%{value: input_map} = ctx), do: check_required_fields(ctx, input_map)

  def check_required_fields(ctx, %{} = input_map) do
    required = ctx.schema.required || []

    # Adjust required fields list, based on read_write_scope
    required =
      Enum.filter(required, fn key ->
        case {ctx.read_write_scope, ctx.schema.properties[key]} do
          {:read, %{writeOnly: true}} -> false
          {:write, %{readOnly: true}} -> false
          _ -> true
        end
      end)

    input_keys = Map.keys(input_map)
    missing_keys = required -- input_keys

    if missing_keys == [] do
      :ok
    else
      errors =
        Enum.map(missing_keys, fn key ->
          ctx = %{ctx | path: [key | ctx.path]}
          Error.new(ctx, {:missing_field, key})
        end)

      {:error, ctx.errors ++ errors}
    end
  end

  def check_required_fields(_ctx, _acc), do: :ok
end
