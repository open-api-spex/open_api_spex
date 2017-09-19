defmodule OpenApiSpexTest.UserController do
  use Phoenix.Controller
  alias OpenApiSpex.Operation
  alias OpenApiSpexTest.Schemas

  plug OpenApiSpex.Plug.Cast
  plug OpenApiSpex.Plug.Validate

  def open_api_operation(action) do
    apply(__MODULE__, :"#{action}_operation", [])
  end

  @doc """
  API Spec for :show action
  """
  def show_operation() do
    import Operation
    %Operation{
      tags: ["users"],
      summary: "Show user",
      description: "Show a user by ID",
      operationId: "UserController.show",
      parameters: [
        parameter(:id, :path, :integer, "User ID", example: 123, minimum: 1)
      ],
      responses: %{
        200 => response("User", "application/json", Schemas.UserResponse)
      }
    }
  end
  def show(conn, %{id: id}) do
    json(conn, %Schemas.UserResponse{
      data: %Schemas.User{
        id: id,
        name: "joe user",
        email: "joe@gmail.com"
      }
    })
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
      description: "Create a user",
      operationId: "UserController.create",
      parameters: [],
      requestBody: request_body("The user attributes", "application/json", Schemas.UserRequest),
      responses: %{
        201 => response("User", "application/json", Schemas.UserResponse)
      }
    }
  end
  def create(conn, %Schemas.UserRequest{user: user = %Schemas.User{}}) do
    json(conn, %Schemas.UserResponse{
      data: %{user | id: 1234}
    })
  end
end