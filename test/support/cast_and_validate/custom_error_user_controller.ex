defmodule OpenApiSpexTest.CastAndValidate.CustomErrorUserController do
  use Phoenix.Controller
  alias OpenApiSpexTest.Schemas
  alias Plug.Conn

  defmodule CustomRenderErrorPlug do
    @behaviour Plug

    alias Plug.Conn

    @impl Plug
    def init(opts), do: opts

    @impl Plug
    def call(conn, errors) do
      reason = Enum.map(errors, &to_string/1) |> Enum.join(", ")
      Conn.send_resp(conn, 400, reason)
    end
  end

  plug OpenApiSpex.Plug.CastAndValidate, render_error: CustomRenderErrorPlug

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
