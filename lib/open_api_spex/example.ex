defmodule OpenApiSpex.Example do
  @moduledoc """
  Defines the `OpenApiSpex.Example.t` type.
  """
  defstruct [
    :summary,
    :description,
    :value,
    :externalValue
  ]

  @typedoc """
  [Example Object](https://swagger.io/specification/#exampleObject)

  In all cases, the example value is expected to be compatible with the type schema of its associated value.
  """
  @type t :: %__MODULE__{
          summary: String.t() | nil,
          description: String.t() | nil,
          value: any,
          externalValue: String.t() | nil
        }
end
