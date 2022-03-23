defmodule OpenApiSpex.OAuthFlows do
  @moduledoc """
  Defines the `OpenApiSpex.OAuthFlows.t` type.
  """
  alias OpenApiSpex.OAuthFlow

  defstruct [
    :implicit,
    :password,
    :clientCredentials,
    :authorizationCode,
    :extensions
  ]

  @typedoc """
  [OAuth Flows Object](https://swagger.io/specification/#oauthFlowsObject)

  Allows configuration of the supported OAuth Flows.
  """
  @type t :: %__MODULE__{
          implicit: OAuthFlow.t() | nil,
          password: OAuthFlow.t() | nil,
          clientCredentials: OAuthFlow.t() | nil,
          authorizationCode: OAuthFlow.t() | nil,
          extensions: %{String.t() => any()} | nil
        }
end
