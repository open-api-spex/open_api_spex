defmodule OpenApiSpex.SecurityScheme do
  alias OpenApiSpex.OAuthFlows
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
  @type t :: %__MODULE__{
    type: String.t,
    description: String.t,
    name: String.t,
    in: String.t,
    scheme: String.t,
    bearerFormat: String.t,
    flows: OAuthFlows.t,
    openIdConnectUrl: String.t
  }
end