defmodule OpenApiSpex.Link do
  alias OpenApiSpex.Server
  defstruct [
    :operationRef,
    :operationId,
    :parameters,
    :requestBody,
    :description,
    :server
  ]
  @type t :: %__MODULE__{
    operationRef: String.t,
    operationId: String.t,
    parameters: %{String.t => any},
    requestBody: any,
    description: String.t,
    server: Server.t
  }
end