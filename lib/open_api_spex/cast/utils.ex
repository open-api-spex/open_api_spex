defmodule OpenApiSpex.Cast.Utils do
  @moduledoc false

  alias OpenApiSpex.Cast.Error

  # Merge 2 maps considering as equal keys that are atom or string representation
  # of that atom. Atom keys takes precedence over string ones.
  def merge_maps(map1, map2) do
    l1 = Enum.map(map1, fn {key, val} -> {to_string(key), key, val} end)
    l2 = Enum.map(map2, fn {key, val} -> {to_string(key), key, val} end)

    l1
    |> Kernel.++(l2)
    |> Enum.group_by(fn {ks, _, _} -> ks end, fn {_, k, v} -> {k, v} end)
    |> Map.new(fn
      {_ks, [{k, v}]} ->
        {k, v}

      {_ks, [{k1, v1}, {k2, v2}]} ->
        cond do
          is_atom(k2) -> {k2, v2}
          is_atom(k1) -> {k1, v1}
          true -> {k2, v2}
        end
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
