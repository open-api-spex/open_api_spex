defmodule OpenApiSpex.MediaType do
  @moduledoc """
  Defines the `OpenApiSpex.MediaType.t` type.
  """
  alias OpenApiSpex.{Encoding, Example, Reference, Schema}

  defstruct [
    :schema,
    :example,
    :examples,
    :encoding,
    :extensions
  ]

  @typedoc """
  [Media Type Object](https://swagger.io/specification/#mediaTypeObject)

  Each Media Type Object provides schema and examples for the media type identified by its key.
  """
  @type t :: %__MODULE__{
          schema: Schema.t() | Reference.t() | nil,
          example: any,
          examples: %{String.t() => Example.t() | Reference.t()} | nil,
          encoding: %{String => Encoding.t()} | nil,
          extensions: %{String.t() => any()} | nil
        }
end
