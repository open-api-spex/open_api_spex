defmodule OpenApiSpex.Encoding do
  @moduledoc """
  Defines the `OpenApiSpex.Encoding.t` type.
  """
  alias OpenApiSpex.{Header, Parameter, Reference}

  defstruct [
    :contentType,
    :headers,
    :style,
    :explode,
    :allowReserved,
    :extensions
  ]

  @typedoc """
  [Encoding Object](https://swagger.io/specification/#encodingObject)

  A single encoding definition applied to a single schema property.
  """
  @type t :: %__MODULE__{
          contentType: String.t() | nil,
          headers: %{String.t() => Header.t() | Reference.t()} | nil,
          style: Parameter.style() | nil,
          explode: boolean | nil,
          allowReserved: boolean | nil,
          extensions: %{String.t() => any()} | nil
        }
end
