defmodule OpenApiSpex.License do
  defstruct [
    :name,
    :url
  ]
  @type t :: %__MODULE__{
    name: String.t,
    url: String.t
  }
end