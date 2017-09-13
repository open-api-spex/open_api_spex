defmodule OpenApiSpex.OAuthFlow do
  defstruct [
    :authorizationUrl,
    :tokenUrl,
    :refreshUrl,
    :scopes
  ]
  @type t :: %__MODULE__{
    authorizationUrl: String.t,
    tokenUrl: String.t,
    refreshUrl: String.t,
    scopes: %{String.t => String.t}
  }
end