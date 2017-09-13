defmodule OpenApiSpex.Callback do
  alias OpenApiSpex.PathItem
  @type t :: %{
    String.t => PathItem.t
  }
end