defmodule OpenApiSpex.OperationBuilder do
  @moduledoc false

  alias OpenApiSpex.{Operation, Parameter, Response, Reference}

  def ensure_type_and_schema_exclusive!(name, type, schema) do
    if type != nil && schema != nil do
      raise ArgumentError,
        message: """
        Both :type and :schema options were specified for #{inspect(name)}. Please specify only one.
        :type is a shortcut for base data types https://swagger.io/docs/specification/data-models/data-types/
        which at the end imports as `%Schema{type: type}`. For more control over schemas please
        use @doc parameters: [
          id: [in: :path, schema: MyCustomSchema]
        ]
        """
    end
  end

  def build_operation_id(meta, mod, name) do
    Map.get(meta, :operation_id, "#{inspect(mod)}.#{name}")
  end

  def build_parameters(%{parameters: params}) when is_list(params) or is_map(params) do
    params
    |> Enum.reduce([], fn
      parameter = %Parameter{}, acc ->
        [parameter | acc]

      ref = %Reference{}, acc ->
        [ref | acc]

      {:"$ref", ref = "#/components/parameters/" <> _name}, acc ->
        [%Reference{"$ref": ref} | acc]

      {name, options}, acc ->
        {location, options} = Keyword.pop(options, :in, :query)
        {type, options} = Keyword.pop(options, :type, nil)
        {schema, options} = Keyword.pop(options, :schema, nil)
        {description, options} = Keyword.pop(options, :description, "")

        ensure_type_and_schema_exclusive!(name, type, schema)

        schema = type || schema || :string

        [Operation.parameter(name, location, schema, description, options) | acc]

      unsupported, acc ->
        IO.warn("Invalid parameters declaration found: " <> inspect(unsupported))

        acc
    end)
    |> Enum.reverse()
  end

  def build_parameters(%{parameters: _params}) do
    IO.warn("""
    parameters tag should be map or list, for example:
    @doc parameters: [
      id: [in: :path, schema: MyCustomSchema]
    ]
    """)

    []
  end

  def build_parameters(_), do: []

  def build_responses(%{responses: responses}) when is_list(responses) or is_map(responses) do
    Map.new(responses, fn
      {status, {description, mime, schema}} ->
        {status_to_code(status), Operation.response(description, mime, schema)}

      {status, {description, mime, schema, opts}} ->
        {status_to_code(status), Operation.response(description, mime, schema, opts)}

      {status, %Response{} = response} ->
        {status_to_code(status), response}

      {status, description} when is_binary(description) ->
        {status_to_code(status), %Response{description: description}}
    end)
  end

  def build_responses(%{responses: _responses}) do
    IO.warn("""
    responses tag should be map or keyword list, for example:
    @doc responses: %{
      200 => {"Response name", "application/json", schema},
      :not_found => {"Response name", "application/json", schema}
    }
    """)

    []
  end

  def build_responses(_), do: []

  defp status_to_code(:default), do: :default
  defp status_to_code(status), do: Plug.Conn.Status.code(status)

  def build_request_body(%{body: {name, mime, schema}}) do
    IO.warn("Using :body key for requestBody is deprecated. Please use :request_body instead.")
    Operation.request_body(name, mime, schema)
  end

  def build_request_body(%{request_body: {name, mime, schema}}) do
    Operation.request_body(name, mime, schema)
  end

  def build_request_body(%{request_body: {name, mime, schema, opts}}) do
    Operation.request_body(name, mime, schema, opts)
  end

  def build_request_body(_), do: nil

  def build_security(operation_spec, module_spec) do
    Map.get(module_spec, :security, []) ++ Map.get(operation_spec, :security, [])
  end

  def build_tags(operation_spec, module_spec) do
    Map.get(module_spec, :tags, []) ++ Map.get(operation_spec, :tags, [])
  end
end
