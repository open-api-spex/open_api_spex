defmodule OpenApiSpex.OAuthFlows do
  @moduledoc """
  Defines the `OpenApiSpex.OAuthFlows.t` type.
  """
  alias OpenApiSpex.OAuthFlow
  defstruct [
    :implicit,
    :password,
    :clientCredentials,
    :authorizationCode
  ]

  @typedoc """
  [OAuth Flows Object](https://swagger.io/specification/#oauthFlowsObject)

  Allows configuration of the supported OAuth Flows.
  """
  @type t :: %__MODULE__{
    implicit: OAuthFlow.t,
    password: OAuthFlow.t,
    clientCredentials: OAuthFlow.t,
    authorizationCode: OAuthFlow.t
  }
end