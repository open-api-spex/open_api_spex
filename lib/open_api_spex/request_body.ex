defmodule OpenApiSpex.RequestBody do
  @moduledoc """
  Defines the `OpenApiSpex.RequestBody.t` type.
  """
  alias OpenApiSpex.MediaType

  @enforce_keys :content
  defstruct [
    :description,
    :content,
    :extensions,
    required: false
  ]

  @typedoc """
  [Request Body Object](https://swagger.io/specification/#requestBodyObject)

  Describes a single request body.
  """
  @type t :: %__MODULE__{
          description: String.t() | nil,
          content: %{String.t() => MediaType.t()},
          required: boolean,
          extensions: %{String.t() => any()} | nil
        }
end
