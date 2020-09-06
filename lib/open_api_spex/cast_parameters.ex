defmodule OpenApiSpex.CastParameters do
  @moduledoc false
  alias OpenApiSpex.{Cast, Operation, Parameter, Schema, Reference, Components}
  alias OpenApiSpex.Cast.Error
  alias Plug.Conn

  @spec cast(Plug.Conn.t(), Operation.t(), Components.t()) ::
          {:error, [Error.t()]} | {:ok, Conn.t()}
  def cast(conn, operation, components) do
    with {:ok, params} <- cast_to_params(conn, operation, components) do
      {:ok, %{conn | params: params}}
    end
  end

  defp cast_to_params(conn, operation, components) do
    operation
    |> schemas_by_location(components)
    |> Enum.map(fn {location, schema} -> cast_location(location, schema, components, conn) end)
    |> reduce_cast_results()
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

  # Matching is done using the downcase version of the expected_names but the original
  # version of the expected_names is kept
  defp get_params_by_location(conn, :header, expected_names) do
    name_lookup = Map.new(expected_names, &{String.downcase(&1), &1})

    for {key, value} <- conn.req_headers,
        property_name = name_lookup[String.downcase(key)],
        into: %{},
        do: {property_name, value}
  end

  defp create_location_schema(parameters) do
    %Schema{
      type: :object,
      additionalProperties: false,
      properties: parameters |> Map.new(fn p -> {p.name, Parameter.schema(p)} end),
      required: parameters |> Enum.filter(& &1.required) |> Enum.map(& &1.name)
    }
    |> maybe_add_additional_properties()
  end

  defp schemas_by_location(operation, components) do
    param_specs_by_location =
      operation.parameters
      |> Enum.map(fn
        %Reference{} = ref ->
          Reference.resolve_parameter(ref, components.parameters)

        %Parameter{schema: ref = %Reference{"$ref": "#/components/parameters/" <> _}} = param ->
          schema = Reference.resolve_parameter(ref, components.parameters)
          %{param | schema: schema}

        %Parameter{schema: ref = %Reference{"$ref": "#/components/schemas/" <> _}} = param ->
          schema = Reference.resolve_schema(ref, components.schemas)
          %{param | schema: schema}

        %Parameter{} = param ->
          param
      end)
      |> Enum.group_by(& &1.in)

    Map.new(param_specs_by_location, fn {location, parameters} ->
      {location, create_location_schema(parameters)}
    end)
  end

  defp cast_location(location, schema, components, conn) do
    params =
      get_params_by_location(
        conn,
        location,
        schema.properties |> Map.keys() |> Enum.map(&Atom.to_string/1)
      )

    Cast.cast(schema, params, components.schemas)
  end

  defp reduce_cast_results(results) do
    Enum.reduce_while(results, {:ok, %{}}, fn
      {:ok, params}, {:ok, all_params} -> {:cont, {:ok, Map.merge(all_params, params)}}
      cast_error, _ -> {:halt, cast_error}
    end)
  end

  defp maybe_add_additional_properties(schema) do
    ap_schema =
      Enum.reject(
        schema.properties,
        fn {_name, %{additionalProperties: ap}} ->
          is_nil(ap) or ap == false
        end
      )

    case ap_schema do
      [{_, %{additionalProperties: ap}}] -> %{schema | additionalProperties: ap}
      _ -> schema
    end
  end
end
