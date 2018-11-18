defmodule OpenApiSpex.CastArray do
  @moduledoc false
  alias OpenApiSpex.{Cast, CastContext}

  def cast(%{value: []}) do
    {:ok, []}
  end

  def cast(%{value: items} = ctx) when is_list(items) do
    results =
      items
      |> Enum.with_index()
      |> Enum.map(fn {item, index} ->
        path = [index | ctx.path]
        Cast.cast(%{ctx | value: item, schema: ctx.schema.items, path: path})
      end)

    errors =
      Enum.flat_map(results, fn
        {:error, errors} when is_list(errors) -> errors
        {:error, error} -> [error]
        _ -> []
      end)

    if errors == [] do
      items = Enum.map(results, fn {:ok, item} -> item end)
      {:ok, items}
    else
      {:error, errors}
    end
  end

  def cast(ctx) do
    CastContext.error(ctx, {:invalid_type, :array})
  end
end
