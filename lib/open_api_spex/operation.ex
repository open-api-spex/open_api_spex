defmodule OpenApiSpex.Operation do
  alias OpenApiSpex.{
    Callback,
    ExternalDocumentation,
    MediaType,
    Operation,
    Parameter,
    Reference,
    RequestBody,
    Response,
    Responses,
    Schema,
    SecurityRequirement,
    Server,
  }

  defstruct [
    :tags,
    :summary,
    :description,
    :externalDocs,
    :operationId,
    :parameters,
    :requestBody,
    :responses,
    :callbacks,
    :deprecated,
    :security,
    :servers
  ]
  @type t :: %__MODULE__{
    tags: [String.t],
    summary: String.t,
    description: String.t,
    externalDocs: ExternalDocumentation.t,
    operationId: String.t,
    parameters: [Parameter.t | Reference.t],
    requestBody: [RequestBody.t | Reference.t],
    responses: Responses.t,
    callbacks: %{
      String.t => Callback.t | Reference.t
    },
    deprecated: boolean,
    security: [SecurityRequirement.t],
    servers: [Server.t]
  }

  @doc """
  Constructs an Operation struct from the plug and opts specified in the given route
  """
  @spec from_route(PathItem.route) :: t
  def from_route(route) do
    from_plug(route.plug, route.opts)
  end

  @doc """
  Constructs an Operation struct from plug module and opts
  """
  @spec from_plug(module, any) :: t
  def from_plug(plug, opts) do
    plug.open_api_operation(opts)
  end

  @doc """
  Shorthand for constructing a Parameter name, location, type, description and optional examples
  """
  @spec parameter(atom, atom, atom, String.t, keyword) :: RequestBody.t
  def parameter(name, location, type, description, opts \\ []) do
    params =
      [name: name, in: location, description: description, required: location == :path]
      |> Keyword.merge(opts)

    Parameter
    |> struct(params)
    |> Parameter.put_schema(type)
  end

  @doc """
  Shorthand for constructing a RequestBody with description, media_type, schema and optional examples
  """
  @spec request_body(String.t, String.t, (Schema.t | Reference.t | module), keyword) :: RequestBody.t
  def request_body(description, media_type, schema_ref, opts \\ []) do
    %RequestBody{
      description: description,
      content: %{
        media_type => %MediaType{
          schema: schema_ref,
          example: opts[:example],
          examples: opts[:examples]
        }
      },
      required: opts[:required] || false
    }
  end

  @doc """
  Shorthand for constructing a Response with description, media_type, schema and optional examples
  """
  @spec response(String.t, String.t, (Schema.t | Reference.t | module), keyword) :: Response.t
  def response(description, media_type, schema_ref, opts \\ []) do
    %Response{
      description: description,
      content: %{
        media_type => %MediaType {
          schema: schema_ref,
          example: opts[:example],
          examples: opts[:examples]
        }
      }
    }
  end

  @doc """
  Cast params to the types defined by the schemas of the operation parameters and requestBody
  """
  @spec cast(Operation.t, map, String.t | nil, %{String.t => Schema.t}) :: {:ok, map} | {:error, String.t}
  def cast(operation = %Operation{}, params = %{}, content_type, schemas) do
    parameters = Enum.filter(operation.parameters, fn p -> Map.has_key?(params, Atom.to_string(p.name)) end)
    with {:ok, parameter_values} <- cast_parameters(parameters, params, schemas),
         {:ok, body} <- cast_request_body(operation.requestBody, params, content_type, schemas) do
      {:ok, Map.merge(parameter_values, body)}
    end
  end

  def cast_parameters([], _params, _schemas), do: {:ok, %{}}
  def cast_parameters([p | rest], params = %{}, schemas) do
    with {:ok, cast_val} <- Schema.cast(Parameter.schema(p), params[Atom.to_string(p.name)], schemas),
         {:ok, cast_tail} <- cast_parameters(rest, params, schemas) do
      {:ok, Map.put_new(cast_tail, p.name, cast_val)}
    end
  end

  def cast_request_body(nil, _, _, _), do: {:ok, %{}}
  def cast_request_body(%RequestBody{content: content}, params, content_type, schemas) do
    schema = content[content_type].schema
    Schema.cast(schema, params, schemas)
  end


  @doc """
  Validate params against the schemas of the operation parameters and requestBody
  """
  @spec validate(Operation.t, map, String.t | nil, %{String.t => Schema.t}) :: :ok | {:error, String.t}
  def validate(operation = %Operation{}, params = %{}, content_type, schemas) do
    with :ok <- validate_required_parameters(operation.parameters, params),
         parameters <- Enum.filter(operation.parameters, &Map.has_key?(params, &1.name)),
         {:ok, remaining} <- validate_parameter_schemas(parameters, params, schemas),
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

  def validate_parameter_schemas([], params, _schemas), do: {:ok, params}
  def validate_parameter_schemas([p | rest], params, schemas) do
    with :ok <- Schema.validate(Parameter.schema(p), params[p.name], schemas),
         {:ok, remaining} <- validate_parameter_schemas(rest, params, schemas) do
      {:ok, Map.delete(remaining, p.name)}
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