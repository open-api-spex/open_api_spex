defmodule OpenApiSpex.OAuthFlow do
  @moduledoc """
  Defines the `OpenApiSpex.OAuthFlow.t` type.
  """
  defstruct [
    :authorizationUrl,
    :tokenUrl,
    :refreshUrl,
    :scopes
  ]

  @typedoc """
  [OAuth Flow Object](https://swagger.io/specification/#oauthFlowObject)

  Configuration details for a supported OAuth Flow
  """
  @type t :: %__MODULE__{
          authorizationUrl: String.t() | nil,
          tokenUrl: String.t() | nil,
          refreshUrl: String.t() | nil,
          scopes: %{String.t() => String.t()} | nil
        }
end
