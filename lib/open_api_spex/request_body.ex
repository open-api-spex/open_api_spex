defmodule OpenApiSpex.RequestBody do
  @moduledoc """
  Defines the `OpenApiSpex.RequestBody.t` type.
  """
  alias OpenApiSpex.MediaType
  defstruct [
    :description,
    :content,
    required: false
  ]

  @typedoc """
  [Request Body Object](https://swagger.io/specification/#requestBodyObject)

  Describes a single request body.
  """
  @type t :: %__MODULE__{
    description: String.t,
    content: %{String.t => MediaType.t},
    required: boolean
  }
end