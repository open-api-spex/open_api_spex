defmodule OpenApiSpex.CastParameters do
  @moduledoc false
  alias OpenApiSpex.{Cast, Operation, Parameter, Schema}
  alias OpenApiSpex.Cast.{Error, Object}
  alias Plug.Conn

  @spec cast(Plug.Conn.t(), Operation.t(), Schema.schemas()) ::
          {:error, [Error.t()]} | {:ok, Conn.t()}
  def cast(conn, operation, schemas) do
    # Taken together as a set, operation parameters are similar to an object schema type.
    # Convert parameters to an object schema, then delegate to `Cast.Object.cast/1`

    properties =
      operation.parameters
      |> Enum.map(fn parameter -> {parameter.name, Parameter.schema(parameter)} end)
      |> Map.new()

    required =
      operation.parameters
      |> Enum.filter(& &1.required)
      |> Enum.map(& &1.name)

    object_schema = %Schema{
      type: :object,
      properties: properties,
      required: required
    }

    params = Map.merge(conn.path_params, conn.query_params)

    ctx = %Cast{value: params, schema: object_schema, schemas: schemas}

    with {:ok, params} <- Object.cast(ctx) do
      {:ok, %{conn | params: params}}
    end
  end
end
