defmodule OpenApiSpex.Responses do
  @moduledoc """
  Defines the `OpenApiSpex.Responses.t` type.
  """
  alias OpenApiSpex.{Reference, Response}

  @typedoc """
  [Responses Object](https://swagger.io/specification/#responsesObject)

  A container for the expected responses of an operation. The container maps a HTTP response code to the expected response.
  The documentation is not necessarily expected to cover all possible HTTP response codes because they may not be known in advance.
  However, documentation is expected to cover a successful operation response and any known errors.
  The default MAY be used as a default response object for all HTTP codes that are not covered individually by the specification.
  The Responses Object MUST contain at least one response code, and it SHOULD be the response for a successful operation call.
  """
  @type t :: %{
          (integer | :default) => Response.t() | Reference.t()
        }
end
