defmodule OpenApiSpex.Cast.Array do
  @moduledoc false
  alias OpenApiSpex.Cast
  alias OpenApiSpex.Cast.Context

  @spec cast(atom() | %{value: any()}) ::
          {:error, nonempty_maybe_improper_list()} | {:ok, [any()]}
  def cast(%{value: []}), do: {:ok, []}

  def cast(%{value: items} = ctx) when is_list(items) do
    case cast_items(ctx) do
      {items, []} -> {:ok, items}
      {_, errors} -> {:error, errors}
    end
  end

  def cast(ctx),
    do: Context.error(ctx, {:invalid_type, :array})

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
      for({:error, errors} <- cast_results, do: errors)
      |> Enum.concat()

    items = for {:ok, item} <- cast_results, do: item

    {items, errors}
  end
end
