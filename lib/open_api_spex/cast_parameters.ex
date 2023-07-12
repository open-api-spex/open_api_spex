defmodule OpenApiSpex.CastParameters do
  @moduledoc false
  alias OpenApiSpex.{Cast, OpenApi, Operation, Parameter, Reference, Schema}
  alias OpenApiSpex.Cast.Error
  alias Plug.Conn

  @default_parsers %{~r/^application\/.*json.*$/ => OpenApi.json_encoder()}

  @spec cast(Plug.Conn.t(), Operation.t(), OpenApi.t(), opts :: [OpenApiSpex.cast_opt()]) ::
          {:error, [Error.t()]} | {:ok, Conn.t()}
  def cast(conn, operation, spec, opts \\ []) do
    replace_params = Keyword.get(opts, :replace_params, true)

    with {:ok, params} <- cast_to_params(conn, operation, spec, opts) do
      {:ok, conn |> cast_conn(params) |> maybe_replace_params(params, replace_params)}
    end
  end

  defp cast_conn(conn, params) do
    private_data =
      conn
      |> Map.get(:private)
      |> Map.get(:open_api_spex, %{})
      |> Map.put(:params, params)

    Plug.Conn.put_private(conn, :open_api_spex, private_data)
  end

  defp maybe_replace_params(conn, _params, false), do: conn
  defp maybe_replace_params(conn, params, true), do: %{conn | params: params}

  defp cast_to_params(conn, operation, %OpenApi{components: components} = spec, opts) do
    operation
    |> schemas_by_location(components)
    |> Enum.map(fn {location, {schema, parameters_contexts}} ->
      cast_location(location, schema, parameters_contexts, spec, conn, opts)
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
      context =
        parameter
        |> Map.take([:explode, :style])
        |> Map.put(:content_type, Parameter.media_type(parameter))

      {Atom.to_string(parameter.name), context}
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

  defp cast_location(
         location,
         schema,
         parameters_contexts,
         %OpenApi{components: components, extensions: ext},
         conn,
         opts
       ) do
    parsers = Map.get(ext || %{}, "x-parameter-content-parsers", %{})
    parsers = Map.merge(@default_parsers, parsers)

    conn
    |> get_params_by_location(
      location,
      schema.properties |> Map.keys() |> Enum.map(&Atom.to_string/1)
    )
    |> pre_parse_parameters(parameters_contexts, parsers)
    |> case do
      {:error, _} = err -> err
      params -> Cast.cast(schema, params, components.schemas, opts)
    end
  end

  defp pre_parse_parameters(%{} = parameters, %{} = parameters_context, parsers) do
    Enum.reduce_while(parameters, Map.new(), fn {key, value}, acc ->
      case pre_parse_parameter(value, Map.get(parameters_context, key, %{}), parsers) do
        {:ok, param} -> {:cont, Map.put(acc, key, param)}
        err -> {:halt, err}
      end
    end)
  end

  defp pre_parse_parameter(parameter, %{content_type: content_type}, parsers)
       when is_bitstring(content_type) and is_map_key(parsers, content_type) do
    parser = Map.fetch!(parsers, content_type)
    decode_parameter(parameter, content_type, parser)
  end

  defp pre_parse_parameter(parameter, %{content_type: content_type}, parsers)
       when is_bitstring(content_type) do
    Enum.reduce_while(parsers, {:ok, parameter}, fn {match, parser}, acc ->
      if is_struct(match, Regex) and Regex.match?(match, content_type) do
        {:halt, decode_parameter(parameter, content_type, parser)}
      else
        {:cont, acc}
      end
    end)
  end

  defp pre_parse_parameter(parameter, %{explode: false, style: :form} = _context, _parsers) do
    # e.g. sizes=S,L,M
    # This does not take care of cases where the value may contain a comma itself
    {:ok, String.split(parameter, ",")}
  end

  defp pre_parse_parameter(parameter, _context, _parsers) do
    {:ok, parameter}
  end

  defp decode_parameter(parameter, content_type, parser) when is_atom(parser) do
    decode_parameter(parameter, content_type, &parser.decode/1)
  end

  defp decode_parameter(parameter, content_type, parser) when is_function(parser, 1) do
    case parser.(parameter) do
      {:ok, result} -> {:ok, result}
      {:error, _error} -> Cast.error(%Cast{}, {:invalid_format, content_type})
    end
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
