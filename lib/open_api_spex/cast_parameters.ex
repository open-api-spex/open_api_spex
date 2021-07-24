defmodule OpenApiSpex.CastParameters do
  @moduledoc false
  alias OpenApiSpex.{Cast, Operation, Parameter, Schema, Reference, Components}
  alias OpenApiSpex.Cast.Error
  alias Plug.Conn

  unless Application.compile_env(:open_api_spex, :do_not_cast_conn_params) do
    require Logger

    Logger.warn(fn -> "
    Casting of Plug.Conn params by open_api_spex is deprected and will be
    removed in the next major release:

    def function(%Conn{params: params}, _params)

    or

    def function(_conn, params)

    Consider migrating from using the Plug.Conn body_params argument to reading
    casted parameters from the connection assigns:

    def function(%Conn{assigns: %{casted_params: body_params}}, _params) do ...

    If you have already migrated to the new behaviour, you can disable the old one:

    config :open_api_spex, do_not_cast_conn_params: true
    " end)
  end

  @spec cast(Plug.Conn.t(), Operation.t(), Components.t()) ::
          {:error, [Error.t()]} | {:ok, Conn.t()}
  def cast(conn, operation, components) do
    with {:ok, params} <- cast_to_params(conn, operation, components) do
      if Application.get_env(:open_api_spex, :do_not_cast_conn_params) do
        {:ok, Conn.assign(conn, :casted_params, params)}
      else
        {:ok, %{Conn.assign(conn, :casted_params, params) | params: params}}
      end
    end
  end

  defp cast_to_params(conn, operation, components) do
    operation
    |> schemas_by_location(components)
    |> Enum.map(fn {location, {schema, parameters_contexts}} ->
      cast_location(location, schema, parameters_contexts, components, conn)
    end)
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

  defp create_location_schema(parameters, components) do
    {
      %Schema{
        type: :object,
        additionalProperties: false,
        properties: parameters |> Map.new(fn p -> {p.name, Parameter.schema(p)} end),
        required: parameters |> Enum.filter(& &1.required) |> Enum.map(& &1.name)
      }
      |> maybe_add_additional_properties(components),
      parameters_contexts(parameters)
    }
  end

  # Extract context information from parameters, useful later when casting
  defp parameters_contexts(parameters) do
    Map.new(parameters, fn parameter ->
      {Atom.to_string(parameter.name), Map.take(parameter, [:explode, :style])}
    end)
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
      {location, create_location_schema(parameters, components)}
    end)
  end

  defp cast_location(location, schema, parameters_contexts, components, conn) do
    params =
      get_params_by_location(
        conn,
        location,
        schema.properties |> Map.keys() |> Enum.map(&Atom.to_string/1)
      )
      |> pre_parse_parameters(parameters_contexts)

    Cast.cast(schema, params, components.schemas)
  end

  defp pre_parse_parameters(%{} = parameters, %{} = parameters_context) do
    Map.new(parameters, fn {key, value} = _parameter ->
      {key, pre_parse_parameter(value, Map.get(parameters_context, key, %{}))}
    end)
  end

  defp pre_parse_parameter(parameter, %{explode: false, style: :form} = _context) do
    # e.g. sizes=S,L,M
    # This does not take care of cases where the value may contain a comma itself
    String.split(parameter, ",")
  end

  defp pre_parse_parameter(parameter, _) do
    parameter
  end

  defp reduce_cast_results(results) do
    Enum.reduce_while(results, {:ok, %{}}, fn
      {:ok, params}, {:ok, all_params} -> {:cont, {:ok, Map.merge(all_params, params)}}
      cast_error, _ -> {:halt, cast_error}
    end)
  end

  defp maybe_add_additional_properties(schema, components) do
    ap_schema =
      schema.properties
      |> Enum.map(fn
        {name, %Schema{} = schema} ->
          {name, schema}

        {name, %Reference{"$ref": "#/components/schemas/" <> _} = ref} ->
          {name, Reference.resolve_schema(ref, components.schemas)}
      end)
      |> Enum.filter(fn
        {_name, %{additionalProperties: ap}} -> ap
        _ -> false
      end)

    case ap_schema do
      [{_, %{additionalProperties: ap}}] -> %{schema | additionalProperties: ap}
      _ -> schema
    end
  end
end
