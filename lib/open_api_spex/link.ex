defmodule OpenApiSpex.Link do
  @moduledoc """
  Defines the `OpenApiSpex.Link.t` type.
  """
  alias OpenApiSpex.Server

  defstruct [
    :operationRef,
    :operationId,
    :parameters,
    :requestBody,
    :description,
    :server,
    :extensions
  ]

  @typedoc """
  [Link Object](https://swagger.io/specification/#linkObject)

  The Link object represents a possible design-time link for a response.

  The presence of a link does not guarantee the caller's ability to successfully invoke it,
  rather it provides a known relationship and traversal mechanism between responses and other operations.

  Unlike dynamic links (i.e. links provided in the response payload),
  the OAS linking mechanism does not require link information in the runtime response.

  For computing links, and providing instructions to execute them,
  a runtime expression is used for accessing values in an operation and
  using them as parameters while invoking the linked operation.
  """
  @type t :: %__MODULE__{
          operationRef: String.t() | nil,
          operationId: String.t() | nil,
          parameters: %{String.t() => any} | nil,
          requestBody: any,
          description: String.t() | nil,
          server: Server.t() | nil,
          extensions: %{String.t() => any()} | nil
        }
end
