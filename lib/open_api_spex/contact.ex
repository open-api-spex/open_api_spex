defmodule OpenApiSpex.Contact do
  @moduledoc """
  Defines the `OpenApiSpex.Contact.t` type.
  """

  defstruct [
    :name,
    :url,
    :email,
    extensions: nil
  ]

  @typedoc """
  [Contact Object](https://swagger.io/specification/#contactObject)

  Contact information for the exposed API.
  """
  @type t :: %__MODULE__{
          name: String.t() | nil,
          url: String.t() | nil,
          email: String.t() | nil,
          extensions: %{String.t() => any()} | nil
        }
end
