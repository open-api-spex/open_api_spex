defmodule OpenApiSpex.Callback do
  @moduledoc """
  Defines the `OpenApiSpex.Callback.t` type.
  """
  alias OpenApiSpex.PathItem

  @typedoc """
  [Callback Object](https://swagger.io/specification/#callbackObject)

  A map of possible out-of band callbacks related to the parent operation.
  Each value in the map is a Path Item Object that describes a set of requests
  that may be initiated by the API provider and the expected responses.
  The key value used to identify the callback object is an expression, evaluated at runtime,
  that identifies a URL to use for the callback operation.
  """
  @type t :: %{
          String.t() => PathItem.t()
        }
end
