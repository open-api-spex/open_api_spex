defmodule OpenApiSpex.Components do
  @moduledoc """
  Defines the `OpenApiSpex.Components.t` type.
  """
  alias OpenApiSpex.{
    Schema, Reference, Response, Parameter, Example,
    RequestBody, Header, SecurityScheme, Link, Callback,
    Components
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
  ]

  @typedoc """
  [Components Object](https://swagger.io/specification/#componentsObject)

  Holds a set of reusable objects for different aspects of the OAS.
  All objects defined within the components object will have no effect on the API unless
  they are explicitly referenced from properties outside the components object.
  """
  @type t :: %Components{
    schemas: %{String.t => Schema.t | Reference.t},
    responses: %{String.t =>  Response.t | Reference.t},
    parameters: %{String.t =>  Parameter.t | Reference.t},
    examples: %{String.t => Example.t | Reference.t},
    requestBodies: %{String.t => RequestBody.t | Reference.t},
    headers: %{String.t =>  Header.t | Reference.t},
    securitySchemes: %{String.t =>  SecurityScheme.t | Reference.t},
    links: %{String.t => Link.t | Reference.t},
    callbacks: %{String.t => Callback.t | Reference.t}
  }
end