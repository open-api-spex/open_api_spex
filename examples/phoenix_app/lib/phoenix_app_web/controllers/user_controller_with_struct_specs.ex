defmodule PhoenixAppWeb.UserControllerWithStructSpecs do
  @moduledoc """
  Demonstration of using `%Operation{}` struct and related structs directly instead
  of using the ExDoc-based operation specs.
  """
  use PhoenixAppWeb, :controller
  import OpenApiSpex.Operation, only: [parameter: 5, request_body: 4, response: 3]
  alias OpenApiSpex.{Operation, Reference}
  alias PhoenixApp.{Accounts, Accounts.User}
  alias PhoenixAppWeb.Schemas

  plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true

  @doc """
  The controller will need to define a callback function `open_api_operation/1`

  This function takes an `action` atom that is the MVC controller action's function
  name, and returns the `%Operation{}` struct for that action.

  For improved code organization, it is recommended to decompose `open_api_operation/1`
  into child functions, and delegate to those.
  """
  def open_api_operation(action) do
    apply(__MODULE__, :"#{action}_operation", [])
  end

  @doc """
  The `*_operation` functions are called by `open_api_operation/1`. They return the `%Operation{}`
  for the given `action`.
  """
  def index_operation() do
    %Operation{
      tags: ["users"],
      summary: "List users",
      description: "List all useres",
      operationId: "UserController.index",
      responses: %{
        200 => response("User List Response", "application/json", Schemas.UsersResponse),
        422 => %Reference{"$ref": "#/components/responses/unprocessable_entity"}
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
      |> put_resp_header("location", Routes.user_path(conn, :show, user))
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
        parameter(:id, :path, :integer, "User ID", example: 123, required: true)
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
