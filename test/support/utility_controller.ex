defmodule OpenApiSpexTest.UtilityController do
  @moduledoc [
    tags: ["utility"]
  ]

  use Phoenix.Controller
  use OpenApiSpex.Controller

  alias OpenApiSpex.Schema
  alias OpenApiSpexTest.Schemas

  plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true

  @doc "Echo body params"
  @doc [
    operation_id: "UtilityController.echo_body_params",
    request_body: {"Echo body params", "application/json", Schemas.EchoBodyParamsRequest},
    responses: %{
      200 => {
        "Echo Body Params Result",
        "application/json",
        %Schema{
          type: :array,
          items: %Schema{
            type: :object,
            properties: %{
              one: %Schema{type: :string}
            }
          }
        }
      }
    }
  ]
  def echo_body_params(conn, _) do
    json(conn, conn.body_params)
  end

  @doc """
  Echo parameters
  """
  @doc parameters: [
         freeForm: [
           in: :query,
           type: %Schema{type: :object, additionalProperties: true},
           description: "unspecified list of anything"
         ]
       ],
       responses: [
         ok:
           {"Casted Result", "application/json", %Schema{type: :object, additionalProperties: true}}
       ]
  def echo_any(conn, params) do
    json(conn, params)
  end
end
