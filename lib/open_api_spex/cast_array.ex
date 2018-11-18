defmodule OpenApiSpex.CastArray do
  @moduledoc false
  alias OpenApiSpex.{Cast, Error}

  def cast(%{value: []}) do
    {:ok, []}
  end

  def cast(%{value: [item | rest]} = ctx) do
    with {:ok, cast_item} <- cast_item(%{ctx | value: item, schema: ctx.schema.items}),
         {:ok, cast_rest} <- cast(%{ctx | value: rest, index: ctx.index + 1}) do
      {:ok, [cast_item | cast_rest]}
    end
  end

  def cast(ctx) do
    {:error, Error.new(:invalid_type, :array, ctx.value)}
  end

  defp cast_item(%{value: item, schema: items_schema} = ctx) do
    with {:error, error} <- Cast.cast(item, items_schema, ctx.schemas) do
      {:error, %{error | path: [ctx.index | error.path]}}
    end
  end
end
