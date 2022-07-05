defmodule OpenApiSpex.Xml do
  @moduledoc """
  Defines the `OpenApiSpex.Xml.t` type.
  """
  defstruct [
    :name,
    :namespace,
    :prefix,
    :attribute,
    :wrapped,
    :extensions
  ]

  @typedoc """
  [XML Object](https://swagger.io/specification/#xmlObject)

  A metadata object that allows for more fine-tuned XML model definitions.
  When using arrays, XML element names are not inferred (for singular/plural forms)
  and the name property SHOULD be used to add that information. See examples for expected behavior.
  """
  @type t :: %__MODULE__{
          name: String.t() | nil,
          namespace: String.t() | nil,
          prefix: String.t() | nil,
          attribute: boolean | nil,
          wrapped: boolean | nil,
          extensions: %{String.t() => any()} | nil
        }
end
