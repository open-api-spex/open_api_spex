defmodule OpenApiSpex.SecurityScheme do
  @moduledoc """
  Defines the `OpenApiSpex.SecurityScheme.t` type.
  """
  alias OpenApiSpex.OAuthFlows

  @enforce_keys :type
  defstruct [
    :type,
    :description,
    :name,
    :in,
    :scheme,
    :bearerFormat,
    :flows,
    :openIdConnectUrl
  ]

  @typedoc """
  [Security Scheme Object](https://swagger.io/specification/#securitySchemeObject)

  Defines a security scheme that can be used by the operations.
  Supported schemes are HTTP authentication, an API key (either as a header or as a query parameter),
  OAuth2's common flows (implicit, password, application and access code) as defined in RFC6749, and OpenID Connect Discovery.
  """
  @type t :: %__MODULE__{
          type: String.t(),
          description: String.t() | nil,
          name: String.t() | nil,
          in: String.t() | nil,
          scheme: String.t() | nil,
          bearerFormat: String.t() | nil,
          flows: OAuthFlows.t() | nil,
          openIdConnectUrl: String.t() | nil
        }
end
