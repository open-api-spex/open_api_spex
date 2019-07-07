defmodule OpenApiSpexTest.CastAndValidate.CustomErrorUserController do
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
      reason = Enum.map(errors, &to_string/1) |> Enum.join(", ")
      Conn.send_resp(conn, 400, reason)
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
      operationId: "CustomErrorUserController.index",
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

  def create_operation() do
    import Operation

    %Operation{
      tags: ["users"],
      summary: "Create user",
      operationId: "CustomErrorUserController.create",
      requestBody:
        Operation.request_body(
          "Create User request body",
          "application/json",
          Schemas.UserRequest,
          required: true
        ),
      responses: %{
        200 => response("User Response", "application/json", Schemas.UserResponse)
      }
    }
  end

  def create(conn, _params) do
    conn
    |> put_status(:created)
    |> json(%Schemas.UsersResponse{
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
