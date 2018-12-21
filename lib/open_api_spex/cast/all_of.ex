defmodule OpenApiSpex.Cast.AllOf do
  @moduledoc false
  alias OpenApiSpex.Cast

  def cast(ctx),
    do: cast_all_of(ctx, nil)

  defp cast_all_of(%{schema: %{type: _, allOf: [schema | remaining]}} = ctx, result) do
    with {:ok, value} <- Cast.cast(%{ctx | schema: schema}) do
      new_schema = %{ctx.schema | allOf: remaining}
      cast_all_of(%{ctx | schema: new_schema}, result || {:ok, value})
    else
      _ -> Cast.error(ctx, {:all_of, to_string(schema.title || schema.type)})
    end
  end

  defp cast_all_of(_, {:ok, result}) do
    {:ok, result}
  end
end
