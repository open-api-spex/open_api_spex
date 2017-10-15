defmodule OpenApiSpex.Operation do
  @moduledoc """
  Defines the `OpenApiSpex.Operation.t` type.
  """
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

  @typedoc """
  [Operation Object](https://swagger.io/specification/#operationObject)

  Describes a single API operation on a path.
  """
  @type t :: %__MODULE__{
    tags: [String.t] | nil,
    summary: String.t | nil,
    description: String.t | nil,
    externalDocs: ExternalDocumentation.t | nil,
    operationId: String.t | nil,
    parameters: [Parameter.t | Reference.t] | nil,
    requestBody: [RequestBody.t | Reference.t] | nil,
    responses: Responses.t,
    callbacks: %{String.t => Callback.t | Reference.t} | nil,
    deprecated: boolean | nil,
    security: [SecurityRequirement.t] | nil,
    servers: [Server.t] | nil
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
  @spec parameter(atom, Parameter.location, Reference.t | Schema.t | atom, String.t, keyword) :: Parameter.t
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
    parameters = Enum.filter(operation.parameters || [], fn p -> Map.has_key?(params, Atom.to_string(p.name)) end)
    with {:ok, parameter_values} <- cast_parameters(parameters, params, schemas),
         {:ok, body} <- cast_request_body(operation.requestBody, params, content_type, schemas) do
      {:ok, Map.merge(parameter_values, body)}
    end
  end

  @spec cast_parameters([Parameter.t], map, %{String.t => Schema.t}) :: {:ok, map} | {:error, String.t}
  defp cast_parameters([], _params, _schemas), do: {:ok, %{}}
  defp cast_parameters([p | rest], params = %{}, schemas) do
    with {:ok, cast_val} <- Schema.cast(Parameter.schema(p), params[Atom.to_string(p.name)], schemas),
         {:ok, cast_tail} <- cast_parameters(rest, params, schemas) do
      {:ok, Map.put_new(cast_tail, p.name, cast_val)}
    end
  end

  @spec cast_request_body(RequestBody.t | nil, map, String.t | nil, %{String.t => Schema.t}) :: {:ok, map} | {:error, String.t}
  defp cast_request_body(nil, _, _, _), do: {:ok, %{}}
  defp cast_request_body(%RequestBody{content: content}, params, content_type, schemas) do
    schema = content[content_type].schema
    Schema.cast(schema, params, schemas)
  end


  @doc """
  Validate params against the schemas of the operation parameters and requestBody
  """
  @spec validate(Operation.t, map, String.t | nil, %{String.t => Schema.t}) :: :ok | {:error, String.t}
  def validate(operation = %Operation{}, params = %{}, content_type, schemas) do
    with :ok <- validate_required_parameters(operation.parameters || [], params),
         parameters <- Enum.filter(operation.parameters || [], &Map.has_key?(params, &1.name)),
         {:ok, remaining} <- validate_parameter_schemas(parameters, params, schemas),
         :ok <- validate_body_schema(operation.requestBody, remaining, content_type, schemas) do
      :ok
    end
  end

  @spec validate_required_parameters([Parameter.t], map) :: :ok | {:error, String.t}
  defp validate_required_parameters(parameter_list, params = %{}) do
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

  @spec validate_parameter_schemas([Parameter.t], map, %{String.t => Schema.t}) :: {:ok, map} | {:error, String.t}
  defp validate_parameter_schemas([], params, _schemas), do: {:ok, params}
  defp validate_parameter_schemas([p | rest], params, schemas) do
    with :ok <- Schema.validate(Parameter.schema(p), params[p.name], schemas),
         {:ok, remaining} <- validate_parameter_schemas(rest, params, schemas) do
      {:ok, Map.delete(remaining, p.name)}
    end
  end

  @spec validate_body_schema(RequestBody.t | nil, map, String.t | nil, %{String.t => Schema.t}) :: :ok | {:error, String.t}
  defp validate_body_schema(nil, _, _, _), do: :ok
  defp validate_body_schema(%RequestBody{required: false}, params, _content_type, _schemas) when map_size(params) == 0 do
    :ok
  end
  defp validate_body_schema(%RequestBody{content: content}, params, content_type, schemas) do
    content
    |> Map.get(content_type)
    |> Map.get(:schema)
    |> Schema.validate(params, schemas)
  end
end