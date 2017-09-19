defmodule OpenApiSpex.RequestBody do
  alias OpenApiSpex.MediaType
  defstruct [
    :description,
    :content,
    required: false
  ]
  @type t :: %__MODULE__{
    description: String.t,
    content: %{String.t => MediaType.t},
    required: boolean
  }
end