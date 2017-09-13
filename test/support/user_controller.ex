defmodule OpenApiSpexTest.UserController do
  use Phoenix.Controller
  alias OpenApiSpex.Operation
  alias OpenApiSpexTest.Schemas

  def open_api_operation(action) do
    apply(__MODULE__, :"#{action}_operation", [])
  end

  def show_operation() do
    import Operation
    %Operation{
      tags: ["users"],
      summary: "Show user",
      description: "Show a user by ID",
      operationId: "UserController.show",
      parameters: [
        parameter(:id, :path, :integer, "User ID", example: 123)
      ],
      responses: %{
        200 => response("User", "application/json", Schemas.UserResponse)
      }
    }
  end
  def show(conn, _params) do
    conn
    |> Plug.Conn.send_resp(200, "HELLO")
  end

  def index_operation() do
    import Operation
    %Operation{
      tags: ["users"],
      summary: "List users",
      description: "List all useres",
      operationId: "UserController.index",
      parameters: [],
      responses: %{
        200 => response("User List Response", "application/json", Schemas.UsersResponse)
      }
    }
  end
  def index(conn, _params) do
    conn
    |> Plug.Conn.send_resp(200, "HELLO")
  end

  def create_operation() do
    import Operation
    %Operation{
      tags: ["users"],
      summary: "Create user",
      description: "Create a user",
      operationId: "UserController.create",
      parameters: [],
      requestBody: request_body("The user attributes", "application/json", Schemas.UserRequest),
      responses: %{
        201 => response("User", "application/json", Schemas.UserResponse)
      }
    }
  end
  def create(conn, _params) do
    conn
    |> Plug.Conn.send_resp(201, "DONE")
  end
end