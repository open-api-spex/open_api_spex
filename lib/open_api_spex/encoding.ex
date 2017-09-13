defmodule OpenApiSpex.Encoding do
  alias OpenApiSpex.{Header, Reference, Parameter}
  defstruct [
    :contentType,
    :headers,
    :style,
    :explode,
    :allowReserved
  ]
  @type t :: %__MODULE__{
    contentType: String.t,
    headers: %{String.t => Header.t | Reference.t},
    style: Parameter.style,
    explode: boolean,
    allowReserved: boolean
  }
end