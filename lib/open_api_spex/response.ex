defmodule OpenApiSpex.Response do
  alias OpenApiSpex.{Header, Reference, MediaType, Link}
  defstruct [
    :description,
    :headers,
    :content,
    :links
  ]
  @type t :: %__MODULE__{
    description: String.t,
    headers: %{String.t => Header.t | Reference.t} | nil,
    content: %{String.t => MediaType.t},
    links: %{String.t => Link.t | Reference.t} | nil
  }
end