defmodule OpenApiSpex.Responses do
  alias OpenApiSpex.{Response, Reference}
  @type t :: %{
    :default => Response.t | Reference.t,
    integer => Response.t | Reference.t
  }
end