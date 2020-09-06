defmodule OpenApiSpex.Response do
  @moduledoc """
  Defines the `OpenApiSpex.Response.t` type.
  """
  alias OpenApiSpex.{Header, Reference, MediaType, Link}

  @enforce_keys :description
  defstruct [
    :description,
    :headers,
    :content,
    :links
  ]

  @typedoc """
  [Response Object](https://swagger.io/specification/#responseObject)

  Describes a single response from an API Operation, including design-time, static links to operations based on the response.
  """
  @type t :: %__MODULE__{
          description: String.t(),
          headers: %{String.t() => Header.t() | Reference.t()} | nil,
          content: %{String.t() => MediaType.t()} | nil,
          links: %{String.t() => Link.t() | Reference.t()} | nil
        }
end
