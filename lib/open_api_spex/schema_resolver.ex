defmodule OpenApiSpex.SchemaResolver do
  @moduledoc """
  Internal module used to resolve `OpenApiSpex.Schema` structs from atoms.
  """
  alias OpenApiSpex.{
    OpenApi,
    Components,
    PathItem,
    Operation,
    Parameter,
    Reference,
    MediaType,
    Schema,
    RequestBody,
    Response
  }

  @doc """
  Adds schemas to the api spec from the modules specified in the Operations.

  Eg, if the response schema for an operation is defined with:

      responses: %{
        200 => Operation.response("User", "application/json", UserResponse)
      }

  Then the `UserResponse.schema()` function will be called to load the schema, and
  a `Reference` to the loaded schema will be used in the operation response.

  See `OpenApiSpex.schema` macro for a convenient syntax for defining schema modules.
  """
  @spec resolve_schema_modules(OpenApi.t()) :: OpenApi.t()
  def resolve_schema_modules(spec = %OpenApi{}) do
    components = spec.components || %Components{}
    schemas = components.schemas || %{}
    responses = components.responses || %{}
    {paths, schemas} = resolve_schema_modules_from_paths(spec.paths, schemas)
    schemas = resolve_schema_modules_from_schemas(schemas)
    {responses, _} = resolve_schema_modules_from_responses(responses, schemas)
    %{spec | paths: paths, components: %{components | schemas: schemas, responses: responses}}
  end

  @doc false
  def add_schemas(spec = %OpenApi{}, schemas) do
    {_, schemas} = resolve_schema_modules_from_schema(schemas, spec.components.schemas)
    put_in(spec.components.schemas, schemas)
  end

  defp resolve_schema_modules_from_paths(paths = %{}, schemas = %{}) do
    Enum.reduce(paths, {paths, schemas}, fn {path, path_item}, {paths, schemas} ->
      {new_path_item, schemas} = resolve_schema_modules_from_path_item(path_item, schemas)
      {Map.put(paths, path, new_path_item), schemas}
    end)
  end

  defp resolve_schema_modules_from_path_item(path = %PathItem{}, schemas) do
    path
    |> Map.from_struct()
    |> Enum.filter(fn {_k, v} -> match?(%Operation{}, v) end)
    |> Enum.reduce({path, schemas}, fn {k, operation}, {path, schemas} ->
      {new_operation, schemas} = resolve_schema_modules_from_operation(operation, schemas)
      {Map.put(path, k, new_operation), schemas}
    end)
  end

  defp resolve_schema_modules_from_operation(operation = %Operation{}, schemas) do
    {parameters, schemas} = resolve_schema_modules_from_parameters(operation.parameters, schemas)

    {request_body, schemas} =
      resolve_schema_modules_from_request_body(operation.requestBody, schemas)

    {responses, schemas} = resolve_schema_modules_from_responses(operation.responses, schemas)

    new_operation = %{
      operation
      | parameters: parameters,
        requestBody: request_body,
        responses: responses
    }

    {new_operation, schemas}
  end

  defp resolve_schema_modules_from_parameters(nil, schemas), do: {nil, schemas}

  defp resolve_schema_modules_from_parameters(parameters, schemas) do
    {parameters, schemas} =
      Enum.reduce(parameters, {[], schemas}, fn parameter, {parameters, schemas} ->
        {new_parameter, schemas} = resolve_schema_modules_from_parameter(parameter, schemas)
        {[new_parameter | parameters], schemas}
      end)

    {Enum.reverse(parameters), schemas}
  end

  defp resolve_schema_modules_from_parameter(
         parameter = %Parameter{schema: schema, content: nil},
         schemas
       ) do
    {schema, schemas} = resolve_schema_modules_from_schema(schema, schemas)
    new_parameter = %{parameter | schema: schema}
    {new_parameter, schemas}
  end

  defp resolve_schema_modules_from_parameter(
         parameter = %Parameter{schema: nil, content: content = %{}},
         schemas
       ) do
    {new_content, schemas} = resolve_schema_modules_from_content(content, schemas)
    {%{parameter | content: new_content}, schemas}
  end

  defp resolve_schema_modules_from_parameter(parameter = %Parameter{}, schemas) do
    {parameter, schemas}
  end

  defp resolve_schema_modules_from_parameter(parameter = %Reference{}, schemas) do
    {parameter, schemas}
  end

  defp resolve_schema_modules_from_content(nil, schemas), do: {nil, schemas}

  defp resolve_schema_modules_from_content(content, schemas) do
    Enum.reduce(content, {content, schemas}, fn {mime, media}, {content, schemas} ->
      {new_media, schemas} = resolve_schema_modules_from_media_type(media, schemas)
      {Map.put(content, mime, new_media), schemas}
    end)
  end

  defp resolve_schema_modules_from_media_type(media = %MediaType{schema: schema}, schemas) do
    {schema, schemas} = resolve_schema_modules_from_schema(schema, schemas)
    new_media = %{media | schema: schema}
    {new_media, schemas}
  end

  defp resolve_schema_modules_from_media_type(media = %MediaType{}, schemas) do
    {media, schemas}
  end

  defp resolve_schema_modules_from_request_body(nil, schemas), do: {nil, schemas}

  defp resolve_schema_modules_from_request_body(request_body = %RequestBody{}, schemas) do
    {content, schemas} = resolve_schema_modules_from_content(request_body.content, schemas)
    new_request_body = %{request_body | content: content}
    {new_request_body, schemas}
  end

  defp resolve_schema_modules_from_request_body(request_body = %Reference{}, schemas) do
    {request_body, schemas}
  end

  defp resolve_schema_modules_from_responses(responses, schemas = %{}) when is_list(responses) do
    resolve_schema_modules_from_responses(Map.new(responses), schemas)
  end

  defp resolve_schema_modules_from_responses(responses = %{}, schemas = %{}) do
    Enum.reduce(responses, {responses, schemas}, fn {status, response}, {responses, schemas} ->
      {new_response, schemas} = resolve_schema_modules_from_response(response, schemas)
      {Map.put(responses, status, new_response), schemas}
    end)
  end

  defp resolve_schema_modules_from_response(response = %Response{}, schemas = %{}) do
    {content, schemas} = resolve_schema_modules_from_content(response.content, schemas)
    new_response = %{response | content: content}
    {new_response, schemas}
  end

  defp resolve_schema_modules_from_response(response = %Reference{}, schemas = %{}) do
    {response, schemas}
  end

  defp resolve_schema_modules_from_schemas(schemas = %{}) do
    Enum.reduce(schemas, schemas, fn {name, schema}, schemas ->
      {schema, schemas} = resolve_schema_modules_from_schema(schema, schemas)
      Map.put(schemas, name, schema)
    end)
  end

  defp resolve_schema_modules_from_schema(false, schemas), do: {false, schemas}
  defp resolve_schema_modules_from_schema(true, schemas), do: {true, schemas}
  defp resolve_schema_modules_from_schema(nil, schemas), do: {nil, schemas}

  defp resolve_schema_modules_from_schema(schema_list, schemas) when is_list(schema_list) do
    Enum.map_reduce(schema_list, schemas, &resolve_schema_modules_from_schema/2)
  end

  defp resolve_schema_modules_from_schema(schema, schemas) when is_atom(schema) do
    title = schema.schema().title

    new_schemas =
      if Map.has_key?(schemas, title) do
        schemas
      else
        {new_schema, schemas} = resolve_schema_modules_from_schema(schema.schema(), schemas)
        Map.put(schemas, title, new_schema)
      end

    {%Reference{"$ref": "#/components/schemas/#{title}"}, new_schemas}
  end

  defp resolve_schema_modules_from_schema(schema = %Schema{}, schemas) do
    {all_of, schemas} = resolve_schema_modules_from_schema(schema.allOf, schemas)
    {one_of, schemas} = resolve_schema_modules_from_schema(schema.oneOf, schemas)
    {any_of, schemas} = resolve_schema_modules_from_schema(schema.anyOf, schemas)
    {not_schema, schemas} = resolve_schema_modules_from_schema(schema.not, schemas)
    {items, schemas} = resolve_schema_modules_from_schema(schema.items, schemas)

    {additional, schemas} =
      resolve_schema_modules_from_schema(schema.additionalProperties, schemas)

    {properties, schemas} =
      resolve_schema_modules_from_schema_properties(schema.properties, schemas)

    schema = %{
      schema
      | allOf: all_of,
        oneOf: one_of,
        anyOf: any_of,
        not: not_schema,
        items: items,
        additionalProperties: additional,
        properties: properties
    }

    {schema, schemas}
  end

  defp resolve_schema_modules_from_schema(ref = %Reference{}, schemas), do: {ref, schemas}

  defp resolve_schema_modules_from_schema_properties(nil, schemas), do: {nil, schemas}

  defp resolve_schema_modules_from_schema_properties(properties, schemas)
       when is_map(properties) do
    Enum.reduce(properties, {properties, schemas}, fn {name, property}, {properties, schemas} ->
      {new_property, schemas} = resolve_schema_modules_from_schema(property, schemas)
      {Map.put(properties, name, new_property), schemas}
    end)
  end

  defp resolve_schema_modules_from_schema_properties(properties, _schemas) do
    raise "Expected :properties to be a map. Got: #{inspect(properties)}"
  end
end
