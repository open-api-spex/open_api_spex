defmodule OpenApiSpexTest.JsonRenderErrorController do
  use Phoenix.Controller
  use OpenApiSpex.Controller
  alias OpenApiSpexTest.Schemas

  plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true

  @doc """
  List users

  List all users
  """
  @doc parameters: [
         validParam: [in: :query, type: :boolean, description: "Valid Param", example: true]
       ],
       responses: [
         no_content: Schemas.NoContent.response()
       ]
  def index(conn, _params) do
    json(conn, %{})
  end
end
