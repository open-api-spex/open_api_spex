defmodule OpenApiSpex.Operation do
  alias OpenApiSpex.{
    ExternalDocumentation, Parameter, Reference,
    RequestBody, Responses, Callback,
    SecurityRequirement, Server, MediaType, Response
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
  @spec parameter(String.t, String.t, String.t, keyword) :: RequestBody.t
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
  @spec request_body(String.t, String.t, String.t, keyword) :: RequestBody.t
  def request_body(description, media_type, schema_ref, opts \\ []) do
    %RequestBody{
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
  Shorthand for constructing a Response with description, media_type, schema and optional examples
  """
  @spec response(String.t, String.t, String.t, keyword) :: Response.t
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
end