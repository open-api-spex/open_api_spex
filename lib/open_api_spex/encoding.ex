defmodule OpenApiSpex.Encoding do
  @moduledoc """
  Defines the `OpenApiSpex.Encoding.t` type.
  """
  alias OpenApiSpex.{Header, Reference, Parameter}
  defstruct [
    :contentType,
    :headers,
    :style,
    :explode,
    :allowReserved
  ]

  @typedoc """
  [Encoding Object](https://swagger.io/specification/#encodingObject)

  A single encoding definition applied to a single schema property.
  """
  @type t :: %__MODULE__{
    contentType: String.t,
    headers: %{String.t => Header.t | Reference.t},
    style: Parameter.style,
    explode: boolean,
    allowReserved: boolean
  }
end