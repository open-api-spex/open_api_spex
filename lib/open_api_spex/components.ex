defmodule OpenApiSpex.Components do
  @moduledoc """
  Defines the `OpenApiSpex.Components.t` type.
  """
  alias OpenApiSpex.{
    Callback,
    Components,
    Example,
    Header,
    Link,
    Parameter,
    Reference,
    RequestBody,
    Response,
    Schema,
    SecurityScheme
  }

  defstruct [
    :schemas,
    :responses,
    :parameters,
    :examples,
    :requestBodies,
    :headers,
    :securitySchemes,
    :links,
    :callbacks,
    :extensions
  ]

  @type schemas_map :: %{String.t() => Schema.t() | Reference.t()}
  @type responses_map :: %{String.t() => Response.t() | Reference.t()}

  @typedoc """
  [Components Object](https://swagger.io/specification/#componentsObject)

  Holds a set of reusable objects for different aspects of the OAS.
  All objects defined within the components object will have no effect on the API unless
  they are explicitly referenced from properties outside the components object.
  """
  @type t :: %Components{
          schemas: schemas_map | nil,
          responses: responses_map | nil,
          parameters: %{String.t() => Parameter.t() | Reference.t()} | nil,
          examples: %{String.t() => Example.t() | Reference.t()} | nil,
          requestBodies: %{String.t() => RequestBody.t() | Reference.t()} | nil,
          headers: %{String.t() => Header.t() | Reference.t()} | nil,
          securitySchemes: %{String.t() => SecurityScheme.t() | Reference.t()} | nil,
          links: %{String.t() => Link.t() | Reference.t()} | nil,
          callbacks: %{String.t() => Callback.t() | Reference.t()} | nil,
          extensions: %{String.t() => any()} | nil
        }
end
