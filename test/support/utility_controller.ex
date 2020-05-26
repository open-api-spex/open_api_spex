defmodule OpenApiSpexTest.UtilityController do
  use Phoenix.Controller
  use OpenApiSpex.Controller

  alias OpenApiSpex.Schema

  plug OpenApiSpex.Plug.CastAndValidate

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
           {"Casted Result", "application/json",
            %Schema{type: :object, additionalProperties: true}}
       ]
  def echo_any(conn, params) do
    json(conn, params)
  end
end
