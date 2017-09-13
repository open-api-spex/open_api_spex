defmodule OpenApiSpex.Reference do
  defstruct [
    :"$ref"
  ]
  @type t :: %{
    "$ref": String.t
  }
end