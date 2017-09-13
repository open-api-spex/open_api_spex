defmodule OpenApiSpex.ServerVariable do
  defstruct [
    :enum,
    :default,
    :description
  ]
  @type t :: %{
    enum: [String.t],
    default: String.t,
    description: String.t
  }
end