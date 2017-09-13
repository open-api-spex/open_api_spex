defmodule OpenApiSpex.Components do
  alias OpenApiSpex.{
    Schema, Reference, Response, Parameter, Example,
    RequestBody, Header, SecurityScheme, Link, Callback
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
  @type t :: %{
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