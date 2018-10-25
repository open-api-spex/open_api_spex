defmodule OpenApiSpex.Tag do
  @moduledoc """
  Defines the `OpenApiSpex.Tag.t` type.
  """

  alias OpenApiSpex.ExternalDocumentation

  @enforce_keys :name
  defstruct [
    :name,
    :description,
    :externalDocs
  ]

  @typedoc """
  [Tag Object](https://swagger.io/specification/#tagObject)

  Adds metadata to a single tag that is used by the Operation Object.
  It is not mandatory to have a Tag Object per tag defined in the Operation Object instances.
  """
  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t() | nil,
          externalDocs: ExternalDocumentation.t() | nil
        }
end
