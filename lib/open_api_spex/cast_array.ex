defmodule OpenApiSpex.CastArray do
  @moduledoc false
  alias OpenApiSpex.{Cast, CastContext}

  def cast(%{value: []}) do
    {:ok, []}
  end

  def cast(%{value: items} = ctx) when is_list(items) do
    case cast_items(ctx) do
      {items, []} -> {:ok, items}
      {_, errors} -> {:error, errors}
    end
  end

  def cast(ctx) do
    CastContext.error(ctx, {:invalid_type, :array})
  end

  ## Private functions

  defp cast_items(%{value: items} = ctx) do
    cast_results =
      items
      |> Enum.with_index()
      |> Enum.map(fn {item, index} ->
        path = [index | ctx.path]
        Cast.cast(%{ctx | value: item, schema: ctx.schema.items, path: path})
      end)

    errors =
      Enum.flat_map(cast_results, fn
        {:error, errors} -> errors
        _ -> []
      end)

    items = for {:ok, item} <- cast_results, do: item

    {items, errors}
  end
end
