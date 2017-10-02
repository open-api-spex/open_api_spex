defmodule OpenApiSpex.Contact do
  @moduledoc """
  Defines the `OpenApiSpex.Contact.t` type.
  """

  defstruct [
    :name,
    :url,
    :email
  ]

  @typedoc """
  [Contact Object](https://swagger.io/specification/#contactObject)

  Contact information for the exposed API.
  """
  @type t :: %__MODULE__{
    name: String.t,
    url: String.t,
    email: String.t
  }
end