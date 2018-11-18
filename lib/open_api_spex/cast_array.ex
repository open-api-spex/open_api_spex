defmodule OpenApiSpex.CastArray do
  @moduledoc false
  alias OpenApiSpex.{Cast, Error}

  def cast(value, schema, schemas \\ %{}, index \\ 0)

  def cast([], _schema, _schemas, _index) do
    {:ok, []}
  end

  def cast([item | rest], schema, schemas, index) do
    with {:ok, cast_item} <- cast_item(item, schema.items, schemas, index),
         {:ok, cast_rest} <- cast(rest, schema, schemas, index + 1) do
      {:ok, [cast_item | cast_rest]}
    end
  end

  def cast(value, _schema, _schemas, _index) do
    {:error, Error.new(:invalid_type, :array, value)}
  end

  defp cast_item(item, items_schema, schemas, index) do
    with {:error, error} <- Cast.cast(item, items_schema, schemas) do
      {:error, %{error | path: [index | error.path]}}
    end
  end
end
