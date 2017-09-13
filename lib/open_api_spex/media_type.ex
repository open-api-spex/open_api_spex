defmodule OpenApiSpex.MediaType do
  alias OpenApiSpex.{Schema, Reference, Example, Encoding}
  defstruct [
    :schema,
    :example,
    :examples,
    :encoding
  ]
  @type t :: %__MODULE__{
    schema: Schema.t | Reference.t,
    example: any,
    examples: %{String.t => Example.t | Reference.t},
    encoding: %{String => Encoding.t}
  }
end
