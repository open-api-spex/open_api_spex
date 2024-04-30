defmodule OpenApiSpexTest.UserNoReplaceController do
  @moduledoc tags: ["users_no_replace"]

  use Phoenix.Controller
  use OpenApiSpex.Controller

  alias OpenApiSpexTest.Schemas

  plug OpenApiSpex.Plug.CastAndValidate,
    json_render_error_v2: true,
    replace_params: false

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

  @doc """
  Create user.

  Create a user.
  """
  @doc request_body: {"The user attributes", "application/json", Schemas.UserRequest},
       responses: [
         created: {"User", "application/json", Schemas.UserResponse},
         unprocessable_entity: OpenApiSpex.JsonErrorResponse.response()
       ]
  def create(
        conn = %{
          private: %{
            open_api_spex: %{body_params: %Schemas.UserRequest{user: user = %Schemas.User{}}}
          }
        },
        _
      ) do
    user =
      user
      |> Map.from_struct()
      |> Map.put(:id, 1234)
      |> Map.delete(:password)

    json(conn, %Schemas.UserResponse{data: user})
  end
end
