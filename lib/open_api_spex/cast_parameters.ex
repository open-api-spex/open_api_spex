defmodule OpenApiSpex.CastParameters do
  @moduledoc false
  alias OpenApiSpex.{Cast, Operation, Parameter, Schema, Reference, Components}
  alias OpenApiSpex.Cast.{Error, Object}
  alias Plug.Conn

  @spec cast(Plug.Conn.t(), Operation.t(), Components.t()) ::
          {:error, [Error.t()]} | {:ok, Conn.t()}
  def cast(conn, operation, components) do
    # Convert parameters to an object schema for the set location
    casted_params =
      operation.parameters
      |> Enum.reduce(%{}, fn param, acc ->
        # Operation's parameters list may include references - resolving here
        parameter =
          case param do
            %Reference{} -> Reference.resolve_parameter(param, components.parameters)
            %Parameter{} -> param
          end

        location_schema =
          acc
          |> Map.get(parameter.in)
          |> add_to_location_schema(parameter)

        Map.put(acc, parameter.in, location_schema)
      end)
      # then delegate to `Cast.Object.cast/1`
      |> Enum.map(fn {location, location_schema} ->
        params = get_params_by_location(conn, location, Map.keys(location_schema.properties))

        ctx = %Cast{
          value: params,
          schema: location_schema,
          schemas: components.schemas
        }

        Object.cast(ctx)
      end)

    full_cast_result =
      Enum.reduce_while(casted_params, {:ok, %{}}, fn
        {:ok, entry}, {:ok, acc} -> {:cont, {:ok, Map.merge(acc, entry)}}
        cast_error, _ -> {:halt, cast_error}
      end)

    case full_cast_result do
      {:ok, result} -> {:ok, %{conn | params: result}}
      err -> err
    end
  end

  defp get_params_by_location(conn, :query, _) do
    Plug.Conn.fetch_query_params(conn).query_params
  end

  defp get_params_by_location(conn, :path, _) do
    conn.path_params
  end

  defp get_params_by_location(conn, :cookie, _) do
    Plug.Conn.fetch_cookies(conn).req_cookies
  end

  defp get_params_by_location(conn, :header, expected_names) do
    conn.req_headers
    |> Enum.filter(fn {key, _value} ->
      Enum.member?(expected_names, String.downcase(key))
    end)
    |> Map.new()
  end

  defp add_to_location_schema(nil, parameter) do
    # Since there is no Schema on the "parameter" level, we create one here
    template_schema = %Schema{
      type: :object,
      additionalProperties: false,
      properties: %{},
      required: []
    }

    add_to_location_schema(template_schema, parameter)
  end

  defp add_to_location_schema(location_schema, parameter) do
    # Put the operation parameter to the proper location schema for validation
    required =
      case parameter.required do
        true -> [parameter.name | location_schema.required]
        _ -> location_schema.required
      end

    properties = Map.put(location_schema.properties, parameter.name, Parameter.schema(parameter))

    location_schema =
      maybe_add_additional_properties(location_schema, parameter.schema)

    %{location_schema | properties: properties, required: required}
  end

  defp maybe_add_additional_properties(
         %Schema{additionalProperties: false} = location_schema,
         %Schema{type: :object, additionalProperties: ap}
       )
       when ap != false and not is_nil(ap) do
    %{location_schema | additionalProperties: ap}
  end

  defp maybe_add_additional_properties(location_schema, _param_schema), do: location_schema
end
