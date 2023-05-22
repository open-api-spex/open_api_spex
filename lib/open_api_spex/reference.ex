defmodule OpenApiSpex.Reference do
  @moduledoc """
  Defines the `OpenApiSpex.Reference.t` type.
  """

  alias OpenApiSpex.{Components, Parameter, Reference, RequestBody, Response, Schema}

  @enforce_keys :"$ref"
  defstruct [
    :"$ref"
  ]

  @typedoc """
  [Reference Object](https://swagger.io/specification/#referenceObject)

  A simple object to allow referencing other components in the specification, internally and externally.
  The Reference Object is defined by JSON Reference and follows the same structure, behavior and rules.
  """
  @type t :: %Reference{
          "$ref": String.t()
        }

  @doc """
  Resolve a `Reference` to the `Schema` it refers to.

  ## Examples

      iex> alias OpenApiSpex.{Reference, Schema}
      ...> schemas = %{"user" => %Schema{title: "user", type: :object}}
      ...> Reference.resolve_schema(%Reference{"$ref": "#/components/schemas/user"}, schemas)
      %OpenApiSpex.Schema{type: :object, title: "user"}
  """
  @spec resolve_schema(Reference.t(), Components.schemas_map()) :: Schema.t() | nil
  def resolve_schema(%Reference{"$ref": "#/components/schemas/" <> name}, schemas),
    do: schemas[name]

  @spec resolve_parameter(Reference.t(), %{String.t() => Parameter.t()}) :: Parameter.t() | nil
  def resolve_parameter(%Reference{"$ref": "#/components/parameters/" <> name}, parameters),
    do: parameters[name]

  @spec resolve_request_body(Reference.t(), %{String.t() => RequestBody.t()}) ::
          RequestBody.t() | nil
  def resolve_request_body(
        %Reference{"$ref": "#/components/requestBodies/" <> name},
        request_bodies
      ),
      do: request_bodies[name]

  @spec resolve_response(Reference.t(), %{String.t() => Response.t()}) ::
          Response.t() | nil
  def resolve_response(%Reference{"$ref": "#/components/responses/" <> name}, responses),
    do: responses[name]
end
