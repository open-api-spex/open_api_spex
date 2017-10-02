defmodule OpenApiSpex.ServerVariable do
  @moduledoc """
  Defines the `OpenApiSpex.ServerVariable.t` type.
  """
  defstruct [
    :enum,
    :default,
    :description
  ]

  @typedoc """
  [Server Variable Object](https://swagger.io/specification/#serverVariableObject)

  An object representing a Server Variable for server URL template substitution.
  """
  @type t :: %__MODULE__{
    enum: [String.t],
    default: String.t,
    description: String.t
  }
end