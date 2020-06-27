defmodule OpenApiSpexTest.JsonRenderErrorController do
  use Phoenix.Controller
  use OpenApiSpex.Controller
  alias OpenApiSpexTest.Schemas

  plug OpenApiSpex.Plug.CastAndValidate

  @doc """
  List users

  List all users
  """
  @doc parameters: [
         validParam: [in: :query, type: :boolean, description: "Valid Param", example: true]
       ],
       responses: [
         ok: {"User List Response", "application/json", Schemas.UsersResponse}
       ]
  def index(conn, _params) do
    json(conn, %Schemas.UsersResponse{
      data: [
        %Schemas.User{
          id: 123,
          name: "joe user",
          email: "joe@gmail.com"
        }
      ]
    })
  end
end
