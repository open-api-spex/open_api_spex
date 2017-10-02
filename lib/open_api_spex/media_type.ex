defmodule OpenApiSpex.MediaType do
  @moduledoc """
  Defines the `OpenApiSpex.MediaType.t` type.
  """
  alias OpenApiSpex.{Schema, Reference, Example, Encoding}
  defstruct [
    :schema,
    :example,
    :examples,
    :encoding
  ]

  @typedoc """
  [Media Type Object](https://swagger.io/specification/#mediaTypeObject)

  Each Media Type Object provides schema and examples for the media type identified by its key.
  """
  @type t :: %__MODULE__{
    schema: Schema.t | Reference.t,
    example: any,
    examples: %{String.t => Example.t | Reference.t},
    encoding: %{String => Encoding.t}
  }
end
