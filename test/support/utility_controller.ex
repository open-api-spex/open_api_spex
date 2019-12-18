defmodule OpenApiSpexTest.UtilityController do
  use Phoenix.Controller
  alias OpenApiSpex.Operation
  alias OpenApiSpexTest.Schemas
  alias OpenApiSpex.Schema

  plug OpenApiSpex.Plug.CastAndValidate

  def open_api_operation(action) do
    apply(__MODULE__, :"#{action}_operation", [])
  end

  def echo_any_operation() do
    import Operation

    %Operation{
      tags: ["utility"],
      summary: "Echo parameters",
      operationId: "UtilityController.echo",
      parameters: [
        parameter(:freeForm, :query, %Schema{type: :object, additionalProperties: true}, "unspecified list of anything")
      ],
      responses: %{
        200 => response("Casted Result", "application/json", %Schema{type: :object, additionalProperties: true})
      }
    }
  end

  def echo_any(conn, params) do
    json(conn, params)
  end
end
