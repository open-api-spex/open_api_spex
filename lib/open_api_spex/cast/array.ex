defmodule OpenApiSpex.Cast.Array do
  @moduledoc false
  alias OpenApiSpex.Cast

  def cast(%{value: [], schema: %{minItems: nil}}) do
    {:ok, []}
  end

  def cast(%{value: items} = ctx) when is_list(items) do
    case cast_array(ctx) do
      {:cast, ctx} -> cast(ctx)
      {items, []} -> Cast.ok(%{ctx | value: items})
      {_, errors} -> {:error, errors}
    end
  end

  def cast(ctx),
    do: Cast.error(ctx, {:invalid_type, :array})

  ## Private functions

  defp cast_array(%{value: value, schema: %{minItems: minimum}} = ctx) when is_integer(minimum) do
    item_count = Enum.count(value)

    if item_count < minimum do
      Cast.error(ctx, {:min_items, minimum, item_count})
    else
      Cast.success(ctx, :minItems)
    end
  end

  defp cast_array(%{value: value, schema: %{maxItems: maximum}} = ctx) when is_integer(maximum) do
    item_count = Enum.count(value)

    if item_count > maximum do
      Cast.error(ctx, {:max_items, maximum, item_count})
    else
      Cast.success(ctx, :maxItems)
    end
  end

  defp cast_array(%{value: value, schema: %{uniqueItems: true}} = ctx) do
    unique_size =
      value
      |> MapSet.new()
      |> MapSet.size()

    if unique_size != Enum.count(value) do
      Cast.error(ctx, {:unique_items})
    else
      Cast.success(ctx, :uniqueItems)
    end
  end

  defp cast_array(%{value: items} = ctx) do
    cast_results =
      items
      |> Enum.with_index()
      |> Enum.map(fn {item, index} ->
        path = [index | ctx.path]
        Cast.cast(%{ctx | value: item, schema: ctx.schema.items, path: path})
      end)

    errors =
      for({:error, errors} <- cast_results, do: errors)
      |> Enum.concat()

    items = for {:ok, item} <- cast_results, do: item

    {items, errors}
  end
end
