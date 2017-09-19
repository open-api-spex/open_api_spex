defmodule OpenApiSpex do
  alias OpenApiSpex.{OpenApi, Operation, Parameter, RequestBody, Schema, SchemaResolver}

  @moduledoc """
  """
  def resolve_schema_modules(spec = %OpenApi{}) do
    SchemaResolver.resolve_schema_modules(spec)
  end

  def cast_parameters(spec = %OpenApi{}, operation = %Operation{}, params = %{}, content_type \\ nil) do
    schemas = spec.components.schemas

    parameters_result =
      operation.parameters
      |> Stream.filter(fn parameter -> Map.has_key?(params, Atom.to_string(parameter.name)) end)
      |> Stream.map(fn parameter -> %{name: parameter.name, schema: Parameter.schema(parameter)} end)
      |> Stream.map(fn %{schema: schema, name: name} -> {name, Schema.cast(schema, params[name], schemas)} end)
      |> Enum.reduce({:ok, %{}}, fn
          {name, {:ok, val}}, {:ok, acc} -> {:ok, Map.put(acc, name, val)}
          _, {:error, reason} -> {:error, reason}
          {_name, {:error, reason}}, _ -> {:error, reason}
        end)

    body_result =
      case operation.requestBody do
        nil -> {:ok, %{}}
        %RequestBody{content: content} ->
          schema = content[content_type].schema
          Schema.cast(schema, params, spec.components.schemas)
      end

    with {:ok, cast_params} <- parameters_result,
         {:ok, cast_body} <- body_result do
      params = Map.merge(cast_params, cast_body)
      {:ok, params}
    end
  end

  def validate_parameters(spec = %OpenApi{}, operation = %Operation{}, params = %{}, content_type \\ nil) do
    schemas = spec.components.schemas

    with :ok <- validate_required_parameters(operation.parameters, params),
         {:ok, remaining} <- validate_parameter_schemas(operation.parameters, params, schemas),
         :ok <- validate_body_schema(operation.requestBody, remaining, content_type, schemas) do
      :ok
    end
  end

  def validate_required_parameters(parameter_list, params = %{}) do
    required =
      parameter_list
      |> Stream.filter(fn parameter -> parameter.required end)
      |> Enum.map(fn parameter -> parameter.name end)

    missing = required -- Map.keys(params)
    case missing do
      [] -> :ok
      _ -> {:error, "Missing required parameters: #{inspect(missing)}"}
    end
  end

  def validate_parameter_schemas(parameter_list, params, schemas) do
    errors =
      parameter_list
      |> Stream.filter(fn parameter -> Map.has_key?(params, parameter.name) end)
      |> Stream.map(fn parameter -> Parameter.schema(parameter) end)
      |> Stream.map(fn schema -> Schema.validate(schema, params, schemas) end)
      |> Enum.filter(fn result -> result != :ok end)

    case errors do
      [] -> {:ok, Map.drop(params, Enum.map(parameter_list, fn p -> p.name end)) }
      _ -> {:error, "Parameter validation errors: #{inspect(errors)}"}
    end
  end

  def validate_body_schema(nil, _, _, _), do: :ok
  def validate_body_schema(%RequestBody{required: false}, params, _content_type, _schemas) when map_size(params) == 0 do
    :ok
  end
  def validate_body_schema(%RequestBody{content: content}, params, content_type, schemas) do
    content
    |> Map.get(content_type)
    |> Map.get(:schema)
    |> Schema.validate(params, schemas)
  end
end
