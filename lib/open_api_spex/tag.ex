defmodule OpenApiSpex.Tag do
  alias OpenApiSpex.ExternalDocumentation
  defstruct [
    :name,
    :description,
    :externalDocs
  ]
  @type t :: %{
    name: String.t,
    description: String.t,
    externalDocs: ExternalDocumentation.t
  }
end