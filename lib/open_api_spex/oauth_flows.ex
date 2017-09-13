defmodule OpenApiSpex.OAuthFlows do
  alias OpenApiSpex.OAuthFlow
  defstruct [
    :implicit,
    :password,
    :clientCredentials,
    :authorizationCode
  ]
  @type t :: %__MODULE__{
    implicit: OAuthFlow.t,
    password: OAuthFlow.t,
    clientCredentials: OAuthFlow.t,
    authorizationCode: OAuthFlow.t
  }
end