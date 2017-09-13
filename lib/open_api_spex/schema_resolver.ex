defmodule OpenApiSpex.SchemaResolver do
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

  def resolve_schema_modules(spec = %OpenApi{}) do
    components = spec.components || %Components{}
    schemas = components.schemas || %{}
    {paths, schemas} = resolve_schema_modules_from_paths(spec.paths, schemas)
    schemas = resolve_schema_modules_from_schemas(schemas)
    %{spec | paths: paths, components: %{components| schemas: schemas}}
  end

  def resolve_schema_modules_from_paths(paths = %{}, schemas = %{}) do
    Enum.reduce(paths, {paths, schemas}, fn {path, path_item}, {paths, schemas} ->
      {new_path_item, schemas} = resolve_schema_modules_from_path_item(path_item, schemas)
      {Map.put(paths, path, new_path_item), schemas}
    end)
  end

  def resolve_schema_modules_from_path_item(path = %PathItem{}, schemas) do
    path
    |> Map.from_struct()
    |> Enum.filter(fn {_k, v} -> match?(%Operation{}, v) end)
    |> Enum.reduce({path, schemas}, fn {k, operation}, {path, schemas} ->
      {new_operation, schemas} = resolve_schema_modules_from_operation(operation, schemas)
      {Map.put(path, k, new_operation), schemas}
    end)
  end

  def resolve_schema_modules_from_operation(operation = %Operation{}, schemas) do
    {parameters, schemas} = resolve_schema_modules_from_parameters(operation.parameters, schemas)
    {request_body, schemas} = resolve_schema_modules_from_request_body(operation.requestBody, schemas)
    {responses, schemas} = resolve_schema_modules_from_responses(operation.responses, schemas)
    new_operation = %{operation | parameters: parameters, requestBody: request_body, responses: responses}
    {new_operation, schemas}
  end

  def resolve_schema_modules_from_parameters(nil, schemas), do: {nil, schemas}
  def resolve_schema_modules_from_parameters(parameters, schemas) do
    {parameters, schemas} =
      Enum.reduce(parameters, {[], schemas}, fn parameter, {parameters, schemas} ->
        {new_parameter, schemas} = resolve_schema_modules_from_parameter(parameter, schemas)
        {[new_parameter | parameters], schemas}
      end)
    {Enum.reverse(parameters), schemas}
  end

  def resolve_schema_modules_from_parameter(parameter = %Parameter{schema: schema, content: nil}, schemas) when is_atom(schema) do
    {ref, new_schemas} = resolve_schema_modules_from_schema(schema, schemas)
    new_parameter = %{parameter | schema: ref}
    {new_parameter, new_schemas}
  end
  def resolve_schema_modules_from_parameter(parameter = %Parameter{schema: nil, content: content = %{}}, schemas) do
    {new_content, schemas} = resolve_schema_modules_from_content(content, schemas)
    {%{parameter | content: new_content}, schemas}
  end
  def resolve_schema_modules_from_parameter(parameter = %Parameter{}, schemas) do
    {parameter, schemas}
  end

  def resolve_schema_modules_from_content(nil, schemas), do: {nil, schemas}
  def resolve_schema_modules_from_content(content, schemas) do
    Enum.reduce(content, {content, schemas}, fn {mime, media}, {content, schemas} ->
      {new_media, schemas} = resolve_schema_modules_from_media_type(media, schemas)
      {Map.put(content, mime, new_media), schemas}
    end)
  end

  def resolve_schema_modules_from_media_type(media = %MediaType{schema: schema}, schemas) when is_atom(schema) do
    {ref, new_schemas} = resolve_schema_modules_from_schema(schema, schemas)
    new_media = %{media | schema: ref}
    {new_media, new_schemas}
  end
  def resolve_schema_modules_from_media_type(media = %MediaType{}, schemas) do
    {media, schemas}
  end

  def resolve_schema_modules_from_request_body(nil, schemas), do: {nil, schemas}
  def resolve_schema_modules_from_request_body(request_body = %RequestBody{}, schemas) do
    {content, schemas} = resolve_schema_modules_from_content(request_body.content, schemas)
    new_request_body = %{request_body | content: content}
    {new_request_body, schemas}
  end

  def resolve_schema_modules_from_responses(responses = %{}, schemas = %{}) do
    Enum.reduce(responses, {responses, schemas}, fn {status, response}, {responses, schemas} ->
      {new_response, schemas} = resolve_schema_modules_from_response(response, schemas)
      {Map.put(responses, status, new_response), schemas}
    end)
  end

  def resolve_schema_modules_from_response(response = %Response{}, schemas = %{}) do
    {content, schemas} = resolve_schema_modules_from_content(response.content, schemas)
    new_response = %{response | content: content}
    {new_response, schemas}
  end

  def resolve_schema_modules_from_schemas(schemas = %{}) do
    Enum.reduce(schemas, schemas, fn {name, schema}, schemas ->
      {schema, schemas} = resolve_schema_modules_from_schema(schema, schemas)
      Map.put(schemas, name, schema)
    end)
  end

  def resolve_schema_modules_from_schema(false, schemas), do: {false, schemas}
  def resolve_schema_modules_from_schema(true, schemas), do: {true, schemas}
  def resolve_schema_modules_from_schema(nil, schemas), do: {nil, schemas}
  def resolve_schema_modules_from_schema(schema, schemas) when is_atom(schema) do
    title = schema.schema().title
    new_schemas = cond do
      Map.has_key?(schemas, title) ->
        schemas

      true ->
        {new_schema, schemas} = resolve_schema_modules_from_schema(schema.schema(), schemas)
        Map.put(schemas, title, new_schema)
    end
    {%Reference{"$ref": "#/components/schemas/#{title}"}, new_schemas}
  end
  def resolve_schema_modules_from_schema(schema = %Schema{}, schemas) do
    {all_of, schemas} = resolve_schema_modules_from_schema(schema.allOf, schemas)
    {one_of, schemas} = resolve_schema_modules_from_schema(schema.oneOf, schemas)
    {any_of, schemas} = resolve_schema_modules_from_schema(schema.anyOf, schemas)
    {not_schema, schemas} = resolve_schema_modules_from_schema(schema.not, schemas)
    {items, schemas} = resolve_schema_modules_from_schema(schema.items, schemas)
    {additional, schemas} = resolve_schema_modules_from_schema(schema.additionalProperties, schemas)
    {properties, schemas} = resolve_schema_modules_from_schema_properties(schema.properties, schemas)
    schema =
      %{schema |
        allOf: all_of,
        oneOf: one_of,
        anyOf: any_of,
        not: not_schema,
        items: items,
        additionalProperties: additional,
        properties: properties
      }
    {schema, schemas}
  end
  def resolve_schema_modules_from_schema(ref = %Reference{}, schemas), do: {ref, schemas}

  def resolve_schema_modules_from_schema_properties(nil, schemas), do: {nil, schemas}
  def resolve_schema_modules_from_schema_properties(properties, schemas) do
    Enum.reduce(properties, {properties, schemas}, fn {name, property}, {properties, schemas} ->
      {new_property, schemas} = resolve_schema_modules_from_schema(property, schemas)
      {Map.put(properties, name, new_property), schemas}
    end)
  end
end