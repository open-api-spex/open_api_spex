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
    Server
  }

  @enforce_keys :responses
  defstruct tags: [],
            summary: nil,
            description: nil,
            externalDocs: nil,
            operationId: nil,
            parameters: [],
            requestBody: nil,
            responses: nil,
            callbacks: %{},
            deprecated: false,
            security: nil,
            servers: nil

  @typedoc """
  [Operation Object](https://swagger.io/specification/#operationObject)

  Describes a single API operation on a path.
  """
  @type t :: %__MODULE__{
          tags: [String.t()],
          summary: String.t() | nil,
          description: String.t() | nil,
          externalDocs: ExternalDocumentation.t() | nil,
          operationId: String.t() | nil,
          parameters: [Parameter.t() | Reference.t()],
          requestBody: RequestBody.t() | Reference.t() | nil,
          responses: Responses.t(),
          callbacks: %{String.t() => Callback.t() | Reference.t()},
          deprecated: boolean,
          security: [SecurityRequirement.t()] | nil,
          servers: [Server.t()] | nil
        }

  @doc """
  Constructs an Operation struct from the plug and opts specified in the given route
  """
  @spec from_route(PathItem.route()) :: t | nil
  def from_route(route)

  def from_route(route = %_{}) do
    route
    |> Map.from_struct()
    |> from_route()
  end

  def from_route(%{plug: plug, plug_opts: opts}) do
    from_plug(plug, opts)
  end

  def from_route(%{plug: plug, opts: opts}) do
    from_plug(plug, opts)
  end

  @doc """
  Constructs an Operation struct from plug module and opts
  """
  @spec from_plug(module, opts :: any) :: t | nil
  def from_plug(plug, opts) do
    plug.open_api_operation(opts)
  end

  @doc """
  Shorthand for constructing an `OpenApiSpex.Parameter` given name, location, type, description and optional examples
  """
  @spec parameter(
          name :: atom,
          location :: Parameter.location(),
          type :: Reference.t() | Schema.t() | atom,
          description :: String.t(),
          opts :: keyword
        ) :: Parameter.t()
  def parameter(name, location, type, description, opts \\ [])
      when is_atom(name) and
             is_atom(location) and
             (is_map(type) or is_atom(type)) and
             is_binary(description) and
             is_list(opts) do
    params =
      [name: name, in: location, description: description, required: location == :path]
      |> Keyword.merge(opts)

    Parameter
    |> struct!(params)
    |> Parameter.put_schema(type)
  end

  @doc """
  Shorthand for constructing a RequestBody with description, media_type, schema and optional examples
  """
  @spec request_body(
          description :: String.t(),
          media_type :: String.t(),
          schema_ref :: Schema.t() | Reference.t() | module,
          opts :: keyword
        ) :: RequestBody.t()
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
  @spec response(
          description :: String.t(),
          media_type :: String.t(),
          schema_ref :: Schema.t() | Reference.t() | module,
          opts :: keyword
        ) :: Response.t()
  def response(description, media_type, schema_ref, opts \\ []) do
    %Response{
      description: description,
      content: %{
        media_type => %MediaType{
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
  @spec cast(
          Operation.t(),
          Conn.t(),
          content_type :: String.t() | nil,
          schemas :: %{String.t() => Schema.t()}
        ) :: {:ok, Plug.Conn.t()} | {:error, String.t()}
  def cast(operation = %Operation{}, conn = %Plug.Conn{}, content_type, schemas) do
    parameters =
      Enum.filter(operation.parameters || [], fn p ->
        Map.has_key?(conn.params, Atom.to_string(p.name))
      end)

    with :ok <- check_query_params_defined(conn, operation.parameters),
         {:ok, parameter_values} <- cast_parameters(parameters, conn.params, schemas),
         {:ok, body} <-
           cast_request_body(operation.requestBody, conn.body_params, content_type, schemas) do
      {:ok, %{conn | params: parameter_values, body_params: body}}
    end
  end

  @spec check_query_params_defined(Conn.t(), list | nil) :: :ok | {:error, String.t()}
  defp check_query_params_defined(%Plug.Conn{} = conn, defined_params)
       when is_nil(defined_params) do
    case conn.query_params do
      %{} -> :ok
      _ -> {:error, "No query parameters defined for this operation"}
    end
  end

  defp check_query_params_defined(%Plug.Conn{} = conn, defined_params)
       when is_list(defined_params) do
    defined_query_params =
      for param <- defined_params,
          param.in == :query,
          into: MapSet.new(),
          do: to_string(param.name)

    case validate_parameter_keys(Map.keys(conn.query_params), defined_query_params) do
      {:error, param} -> {:error, "Undefined query parameter: #{inspect(param)}"}
      :ok -> :ok
    end
  end

  @spec validate_parameter_keys([String.t()], MapSet.t()) :: {:error, String.t()} | :ok
  defp validate_parameter_keys([], _defined_params), do: :ok

  defp validate_parameter_keys([param | params], defined_params) do
    case MapSet.member?(defined_params, param) do
      false -> {:error, param}
      _ -> validate_parameter_keys(params, defined_params)
    end
  end

  @spec cast_parameters([Parameter.t()], map, %{String.t() => Schema.t()}) ::
          {:ok, map} | {:error, String.t()}
  defp cast_parameters([], _params, _schemas), do: {:ok, %{}}

  defp cast_parameters([p | rest], params = %{}, schemas) do
    with {:ok, cast_val} <-
           Schema.cast(Parameter.schema(p), params[Atom.to_string(p.name)], schemas),
         {:ok, cast_tail} <- cast_parameters(rest, params, schemas) do
      {:ok, Map.put_new(cast_tail, p.name, cast_val)}
    end
  end

  @spec cast_request_body(RequestBody.t() | nil, map, String.t() | nil, %{
          String.t() => Schema.t()
        }) :: {:ok, map} | {:error, String.t()}
  defp cast_request_body(nil, _, _, _), do: {:ok, %{}}

  defp cast_request_body(%RequestBody{content: content}, params, content_type, schemas) do
    schema = content[content_type].schema
    Schema.cast(schema, params, schemas)
  end

  @doc """
  Validate params against the schemas of the operation parameters and requestBody
  """
  @spec validate(Operation.t(), Conn.t(), String.t() | nil, %{String.t() => Schema.t()}) ::
          :ok | {:error, String.t()}
  def validate(operation = %Operation{}, conn = %Plug.Conn{}, content_type, schemas) do
    with :ok <- validate_required_parameters(operation.parameters || [], conn.params),
         parameters <-
           Enum.filter(operation.parameters || [], &Map.has_key?(conn.params, &1.name)),
         :ok <- validate_parameter_schemas(parameters, conn.params, schemas),
         :ok <-
           validate_body_schema(operation.requestBody, conn.body_params, content_type, schemas) do
      :ok
    end
  end

  @spec validate_required_parameters([Parameter.t()], map) :: :ok | {:error, String.t()}
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

  @spec validate_parameter_schemas([Parameter.t()], map, %{String.t() => Schema.t()}) ::
          :ok | {:error, String.t()}
  defp validate_parameter_schemas([], %{} = _params, _schemas), do: :ok

  defp validate_parameter_schemas([p | rest], %{} = params, schemas) do
    {:ok, parameter_value} = Map.fetch(params, p.name)

    with :ok <- Schema.validate(Parameter.schema(p), parameter_value, schemas) do
      validate_parameter_schemas(rest, params, schemas)
    end
  end

  @spec validate_body_schema(
          RequestBody.t() | nil,
          params :: map,
          content_type :: String.t() | nil,
          schemas :: %{String.t() => Schema.t()}
        ) :: :ok | {:error, String.t()}
  defp validate_body_schema(nil, _, _, _), do: :ok

  defp validate_body_schema(%RequestBody{required: false}, params, _content_type, _schemas)
       when map_size(params) == 0 do
    :ok
  end

  defp validate_body_schema(%RequestBody{content: content}, params, content_type, schemas) do
    content
    |> Map.get(content_type)
    |> Map.get(:schema)
    |> Schema.validate(params, schemas)
  end
end
