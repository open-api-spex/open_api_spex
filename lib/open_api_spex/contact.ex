defmodule OpenApiSpex.Contact do
  defstruct [
    :name,
    :url,
    :email
  ]
  @type t :: %__MODULE__{
    name: String.t,
    url: String.t,
    email: String.t
  }
end