defmodule OpenApiSpex.JsonApiHelpers.JsonApiError do
  alias OpenApiSpex.Schema

  @moduledoc """
  @see https://jsonapi.org/format/#errors
  """

  @behaviour OpenApiSpex.Schema
  def schema do
    %OpenApiSpex.Schema{
      title: "JsonApiError",
      type: :object,
      properties: %{
        id: %Schema{
          type: :string,
          description: "A unique identifier for this particular occurrence of the problem."
        },
        status: %Schema{
          type: :string,
          description:
            "The HTTP status code applicable to this problem, expressed as a string value."
        },
        code: %Schema{
          type: :string,
          description: "An application-specific error code, expressed as a string value."
        },
        title: %Schema{
          type: :string,
          description:
            "A short, human-readable summary of the problem that *SHOULD NOT* change from occurrence to occurrence of the problem, except for purposes of localization."
        },
        detail: %Schema{
          type: :string,
          description: "A human-readable explanation specific to this occurrence of the problem."
        }
        # TODO: Props:
        # links: %Schema{type: JsonApiLinks, description: "a links object containing the following members"},
        # source: %Schema{type: NEED_PROPPER_DEFINITION, description: "An object containing references to the source of the error."},
        # meta: %Schema{
        #   type:  NEED_PROPPER_DEFINITION,
        #   description: "A meta object containing non-standard meta-information about the error."
        # }
      }
    }
  end
end
