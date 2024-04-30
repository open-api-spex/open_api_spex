defmodule OpenApiSpexTest.ResponseCodeRangesController do
  use Phoenix.Controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Operation

  defmodule GenericResponse do
    alias OpenApiSpex.Schema
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :object,
      properties: %{
        type: %Schema{
          type: :string,
          enum: ["generic"]
        }
      }
    })
  end

  defmodule CreatedResponse do
    alias OpenApiSpex.Schema
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :object,
      properties: %{
        type: %Schema{
          type: :string,
          enum: ["created"]
        }
      }
    })
  end

  operation :index,
    operation_id: "response_code_ranges",
    summary: "String response codes index",
    responses: [
      created:
        Operation.response(
          "Created response",
          "application/json",
          CreatedResponse
        ),
      "2XX":
        Operation.response(
          "Generic response",
          "application/json",
          GenericResponse
        )
    ]

  def index(conn, _) do
    json(conn, %{type: "generic"})
  end
end
