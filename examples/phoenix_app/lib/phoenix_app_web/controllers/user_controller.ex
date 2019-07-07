defmodule PhoenixAppWeb.UserController do
  use PhoenixAppWeb, :controller
  import OpenApiSpex.Operation, only: [parameter: 5, request_body: 4, response: 3]
  alias OpenApiSpex.Operation
  alias PhoenixApp.{Accounts, Accounts.User}
  alias PhoenixAppWeb.Schemas

  plug(OpenApiSpex.Plug.Cast)
  plug(OpenApiSpex.Plug.Validate)

  def open_api_operation(action) do
    apply(__MODULE__, :"#{action}_operation", [])
  end

  def index_operation() do
    %Operation{
      tags: ["users"],
      summary: "List users",
      description: "List all useres",
      operationId: "UserController.index",
      responses: %{
        200 => response("User List Response", "application/json", Schemas.UsersResponse)
      }
    }
  end

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

  def create_operation() do
    %Operation{
      tags: ["users"],
      summary: "Create user",
      description: "Create a user",
      operationId: "UserController.create",
      parameters: [
        Operation.parameter(:group_id, :path, :integer, "Group ID", example: 1)
      ],
      requestBody:
        request_body("The user attributes", "application/json", Schemas.UserRequest,
          required: true
        ),
      responses: %{
        201 => response("User", "application/json", Schemas.UserResponse)
      }
    }
  end

  def create(conn = %{body_params: %Schemas.UserRequest{user: user_params}}, %{
        group_id: _group_id
      }) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", user_path(conn, :show, user))
      |> render("show.json", user: user)
    end
  end

  @doc """
  API Spec for :show action
  """
  def show_operation() do
    %Operation{
      tags: ["users"],
      summary: "Show user",
      description: "Show a user by ID",
      operationId: "UserController.show",
      parameters: [
        parameter(:id, :path, :integer, "User ID", example: 123, minimum: 1, required: true)
      ],
      responses: %{
        200 => response("User", "application/json", Schemas.UserResponse)
      }
    }
  end

  def show(conn, %{id: id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.json", user: user)
  end
end
