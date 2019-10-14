defmodule OpenApiSpexTest.CustomErrorUserController do
  use Phoenix.Controller
  alias OpenApiSpex.Operation
  alias OpenApiSpexTest.Schemas
  alias Plug.Conn

  defmodule CustomRenderErrorPlug do
    @behaviour Plug

    alias Plug.Conn

    @impl Plug
    def init(opts), do: opts

    @impl Plug
    def call(conn, errors) do
      errors = errors |> Enum.map(&OpenApiSpex.error_message/1) |> Enum.join(",")
      conn |> Conn.send_resp(400, "#{errors}")
    end
  end

  plug OpenApiSpex.Plug.CastAndValidate, render_error: CustomRenderErrorPlug

  def open_api_operation(action) do
    apply(__MODULE__, :"#{action}_operation", [])
  end

  def index_operation() do
    import Operation

    %Operation{
      tags: ["users"],
      summary: "List users",
      description: "List all useres",
      operationId: "UserController.index",
      parameters: [
        parameter(:validParam, :query, :boolean, "Valid Param", example: true)
      ],
      responses: %{
        200 => response("User List Response", "application/json", Schemas.UsersResponse)
      }
    }
  end

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
