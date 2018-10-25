defmodule OpenApiSpex.Header do
  @moduledoc """
  Defines the `OpenApiSpex.Header.t` type.
  """
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

  @typedoc """
  [Header Object](https://swagger.io/specification/#headerObject)

  The Header Object follows the structure of the Parameter Object with the following changes:

   - name MUST NOT be specified, it is given in the corresponding headers map.
   - in MUST NOT be specified, it is implicitly in header.
   - All traits that are affected by the location MUST be applicable to a location of header (for example, style).
  """
  @type t :: %__MODULE__{
          description: String.t() | nil,
          required: boolean | nil,
          deprecated: boolean | nil,
          allowEmptyValue: boolean | nil,
          style: :simple,
          explode: boolean | nil,
          schema: Schema.t() | Reference.t() | nil,
          example: any,
          examples: %{String.t() => Example.t() | Reference.t()} | nil
        }
end
