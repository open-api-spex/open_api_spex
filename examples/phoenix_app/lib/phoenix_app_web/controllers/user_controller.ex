defmodule PhoenixAppWeb.UserController do
  @moduledoc """
  Demonstration of defining OpenApi operations from the controller module
  using the ExDoc-based operation specs.

  At the module level, define a `@moduledoc` to define the tags for the controller's operations.
  """

  use PhoenixAppWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.{Schema, Reference}
  alias PhoenixApp.{Accounts, Accounts.User}
  alias PhoenixAppWeb.Schemas

  plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true

  tags ["users"]
  security [%{}, %{"oauth" => ["user:email"]}]

  operation :index,
    summary: "List users",
    description: "List all users",
    responses: [
      ok: {"User List Response", "application/json", Schemas.UsersResponse},
      unprocessable_entity: %Reference{"$ref": "#/components/responses/unprocessable_entity"}
    ]

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

  operation :create,
    summary: "Create user (this line becomes the operation's `summary`)",
    description: "Create a user (this block of text becomes the operation's `description`)",
    parameters: [
      group_id: [in: :path, type: :integer, description: "Group ID", example: 1]
    ],
    request_body:
      {"The user attributes", "application/json", Schemas.UserRequest, required: true},
    responses: [
      created: {"User", "application/json", Schemas.UserResponse}
    ]

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

  operation :show,
    summary: "Show user.",
    description: "Show a user by ID.",
    parameters: [
      id: [
        in: :path,
        # `:type` can be an atom, %Schema{}, or %Reference{}
        type: %Schema{type: :integer, minimum: 1},
        description: "User ID",
        example: 123,
        required: true
      ]
    ],
    responses: [
      ok: {"User", "application/json", Schemas.UserResponse}
    ]

  def show(conn, %{id: id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.json", user: user)
  end

  operation :update,
    summary: "Update user.",
    description: "Update a user by ID.",
    parameters: [
      id: [
        in: :path,
        type: %Schema{type: :integer, minimum: 1},
        description: "User ID",
        example: 123,
        required: true
      ]
    ],
    request_body:
      {"The user attributes", "application/json", Schemas.UserRequest, required: true},
    responses: [
      ok: {"User", "application/json", Schemas.UserResponse}
    ]

  def update(conn = %{body_params: %Schemas.UserRequest{user: user}}, %{id: id}) do
    updated = Accounts.update_user(id, Map.take(user, [:name, :email]))
    render(conn, "show.json", user: updated)
  end
end
