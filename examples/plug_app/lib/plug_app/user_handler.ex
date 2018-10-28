defmodule PlugApp.UserHandler do
  alias OpenApiSpex.Operation
  alias PlugApp.{Accounts, Accounts.User}
  alias PlugApp.Schemas
  import OpenApiSpex.Operation, only: [parameter: 5, request_body: 4, response: 3]

  defmodule Index do
    use Plug.Builder

    plug OpenApiSpex.Plug.Cast, operation_id: "UserHandler.Index"
    plug OpenApiSpex.Plug.Validate
    plug :index

    def open_api_operation(_) do
      %Operation{
        tags: ["users"],
        summary: "List users",
        description: "List all useres",
        operationId: "UserHandler.Index",
        responses: %{
          200 => response("User List Response", "application/json", Schemas.UsersResponse)
        }
      }
    end

    def index(conn, _opts) do
      users = Accounts.list_users()
      conn
      |> Plug.Conn.put_resp_header("Content-Type", "application/json")
      |> Plug.Conn.send_resp(200, render(users))
    end

    def render(users) do
      %{
        data: Enum.map(users, &Map.take(&1, [:id, :name, :email]))
      }
      |> Poison.encode!(pretty: true)
    end
  end

  defmodule Show do
    use Plug.Builder

    plug OpenApiSpex.Plug.Cast, operation_id: "UserHandler.Show"
    plug OpenApiSpex.Plug.Validate
    plug :load
    plug :show

    def open_api_operation(_) do
      %Operation{
        tags: ["users"],
        summary: "Show user",
        description: "Show a user by ID",
        operationId: "UserHandler.Show",
        parameters: [
          parameter(:id, :path, :integer, "User ID", example: 123, minimum: 1)
        ],
        responses: %{
          200 => response("User", "application/json", Schemas.UserResponse)
        }
      }
    end

    def load(conn = %Plug.Conn{params: %{id: id}}, _opts) do
      case Accounts.get_user!(id) do
        nil ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(404, ~s({"error": "User not found"}))
          |> halt()

        user -> assign(conn, :user, user)
      end
    end

    def show(conn = %Plug.Conn{assigns: %{user: user}}, _opts) do
      conn
      |> put_resp_header("Content-Type", "application/json")
      |> send_resp(200, render(user))
    end

    def render(user) do
      %{
        data: Map.take(user, [:id, :name, :email])
      }
      |> Poison.encode!(pretty: true)
    end
  end

  defmodule Create do
    use Plug.Builder

    plug OpenApiSpex.Plug.Cast, operation_id: "UserHandler.Create"
    plug OpenApiSpex.Plug.Validate
    plug :create

    def open_api_operation(_) do
      %Operation{
        tags: ["users"],
        summary: "Create user",
        description: "Create a user",
        operationId: "UserHandler.Create",
        requestBody: request_body("The user attributes", "application/json", Schemas.UserRequest, required: true),
        responses: %{
          201 => response("User", "application/json", Schemas.UserResponse)
        }
      }
    end

    def create(conn = %Plug.Conn{body_params: %Schemas.UserRequest{user: user_params}}, _opts) do
      with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(201, Show.render(user))
      end
    end
  end
end
