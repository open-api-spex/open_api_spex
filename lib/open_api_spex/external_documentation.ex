defmodule OpenApiSpex.ExternalDocumentation do
  @moduledoc """
  Defines the `OpenApiSpex.ExternalDocumentation.t` type.
  """
  defstruct [
    :description,
    :url
  ]

  @typedoc """
  [External Documentation Object](https://swagger.io/specification/#externalDocumentationObject)

  Allows referencing an external resource for extended documentation.
  """
  @type t :: %__MODULE__{
    description: String.t,
    url: String.t
  }
end