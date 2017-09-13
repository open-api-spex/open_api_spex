defmodule OpenApiSpex.Example do
  defstruct [
    :summary,
    :description,
    :value,
    :externalValue
  ]
  @type t :: %{
    summary: String.t,
    description: String.t,
    value: any,
    externalValue: String.t
  }
end