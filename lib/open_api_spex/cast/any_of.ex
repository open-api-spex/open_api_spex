defmodule OpenApiSpex.Cast.AnyOf do
  @moduledoc false
  alias OpenApiSpex.Cast

  def cast(ctx, failed_schemas \\ [])

  def cast(%_{schema: %{type: _, anyOf: []}} = ctx, failed_schemas) do
    Cast.error(ctx, {:any_of, error_message(failed_schemas, ctx.schemas)})
  end

  def cast(
        %{schema: %{type: _, anyOf: [schema | schemas]}} = ctx,
        failed_schemas
      ) do
    with {:ok, value} <- Cast.cast(%{ctx | schema: schema}) do
      {:ok, value}
    else
      _ ->
        new_schema = %{ctx.schema | anyOf: schemas}
        cast(%{ctx | schema: new_schema}, [schema | failed_schemas])
    end
  end

  ## Private functions

  defp error_message([], _) do
    "[] (no schemas provided)"
  end

  defp error_message(failed_schemas, schemas) do
    for schema <- failed_schemas do
      schema = OpenApiSpex.resolve_schema(schema, schemas)

      case schema do
        %{title: title, type: type} when not is_nil(title) ->
          "Schema(title: #{inspect(title)}, type: #{inspect(type)})"

        %{type: type} ->
          "Schema(type: #{inspect(type)})"
      end
    end
    |> Enum.join(", ")
  end
end
