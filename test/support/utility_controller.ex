defmodule OpenApiSpexTest.UtilityController do
  use Phoenix.Controller
  alias OpenApiSpex.Operation
  alias OpenApiSpex.Schema
  alias OpenApiSpexTest.Schemas

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

  def echo_body_params_operation() do
    import Operation

    %Operation{
      tags: ["utility"],
      summary: "Echo body params",
      operationId: "UtilityController.echo_body_params",
      requestBody: request_body("Echo body params", "application/json", Schemas.EchoBodyParamsRequest),
      responses: %{
        200 =>
          response("Echo Body Params Result", "application/json", %Schema{
            type: :array,
            items: %Schema{
              type: :object,
              properties: %{
                one: %Schema{type: :string}
              }
            }
          })
      }
    }
  end

  def echo_body_params(conn, _) do
    json(conn, conn.body_params)
  end

  def echo_any(conn, params) do
    json(conn, params)
  end
end
