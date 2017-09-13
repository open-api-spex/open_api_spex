defmodule OpenApiSpex.Header do
  alias OpenApiSpex.{Schema, Reference, Example}
  defstruct [
    :description,
    :required,
    :deprecated,
    :allowEmptyValue,
    :explode,
    :schema,
    :example,
    :examples,
    style: :simple
  ]
  @type t :: %__MODULE__{
    description: String.t,
    required: boolean,
    deprecated: boolean,
    allowEmptyValue: boolean,
    style: :simple,
    explode: boolean,
    schema: Schema.t | Reference.t,
    example: any,
    examples: %{String.t => Example.t | Reference.t}
  }
end