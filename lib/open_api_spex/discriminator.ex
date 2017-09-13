defmodule OpenApiSpex.Discriminator do
  defstruct [
    :propertyName,
    :mapping
  ]
  @type t :: %__MODULE__{
    propertyName: String.t,
    mapping: %{String.t => String.t}
  }
end