defmodule OpenApiSpex.ExternalDocumentation do
  defstruct [
    :description,
    :url
  ]
  @type t :: %__MODULE__{
    description: String.t,
    url: String.t
  }
end