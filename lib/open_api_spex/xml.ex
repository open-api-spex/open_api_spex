defmodule OpenApiSpex.Xml do
  defstruct [
    :name,
    :namespace,
    :prefix,
    :attribute,
    :wrapped
  ]
  @type t :: %__MODULE__{
    name: String.t,
    namespace: String.t,
    prefix: String.t,
    attribute: boolean,
    wrapped: boolean
  }
end