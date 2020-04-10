defmodule OpenApiSpex.Operation do
  @moduledoc """
  Defines the `OpenApiSpex.Operation.t` type.
  """

  alias OpenApiSpex.{
    Callback,
    Cast,
    Cast.Error,
    CastParameters,
    Components,
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

  alias Plug.Conn

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

  @spec cast(Operation.t(), Conn.t(), String.t() | nil, Components.t()) ::
          {:error, [Error.t()]} | {:ok, Conn.t()}
  def cast(operation = %Operation{}, conn = %Conn{}, content_type, components = %Components{}) do
    with {:ok, conn} <- cast_parameters(conn, operation, components),
         {:ok, body} <-
           cast_request_body(operation.requestBody, conn.body_params, content_type, components) do
      {:ok, %{conn | body_params: body}}
    end
  end

  defp cast_parameters(conn, operation, components) do
    CastParameters.cast(conn, operation, components)
  end

  defp cast_request_body(nil, _, _, _), do: {:ok, %{}}

  defp cast_request_body(%{required: false}, _, nil, _), do: {:ok, %{}}

  defp cast_request_body(%{required: true}, _, nil, _) do
    {:error, [Error.new(%{path: [], value: nil}, {:missing_header, "content-type"})]}
  end

  defp cast_request_body(
         %RequestBody{content: content},
         params,
         content_type,
         components = %Components{}
       ) do
    case content do
      %{^content_type => media_type} ->
        Cast.cast(media_type.schema, params, components.schemas)

      _ ->
        {:error, [Error.new(%{path: [], value: content_type}, {:invalid_header, "content-type"})]}
    end
  end
end
