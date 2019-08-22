defmodule OpenApiSpex.CastParameters do
  @moduledoc false
  alias OpenApiSpex.{Cast, Operation, Parameter, Schema, Reference, Components}
  alias OpenApiSpex.Cast.{Error, Object}
  alias Plug.Conn

  @spec cast(Plug.Conn.t(), Operation.t(), Components.t()) ::
          {:error, [Error.t()]} | {:ok, Conn.t()}
  def cast(conn, operation, components) do
    # Taken together as a set, operation parameters are similar to an object schema type.
    # Convert parameters to an object schema, then delegate to `Cast.Object.cast/1`

    # Operation's parameters list may include references - resolving here
    resolved_parameters =
      Enum.map(operation.parameters, fn
        ref = %Reference{} -> Reference.resolve_parameter(ref, components.parameters)
        param = %Parameter{} -> param
      end)

    properties =
      resolved_parameters
      |> Enum.map(fn parameter -> {parameter.name, Parameter.schema(parameter)} end)
      |> Map.new()

    required =
      resolved_parameters
      |> Enum.filter(& &1.required)
      |> Enum.map(& &1.name)

    object_schema = %Schema{
      type: :object,
      properties: properties,
      required: required
    }

    params = Map.merge(conn.path_params, conn.query_params)

    ctx = %Cast{value: params, schema: object_schema, schemas: components.schemas}

    with {:ok, params} <- Object.cast(ctx) do
      {:ok, %{conn | params: params}}
    end
  end
end
