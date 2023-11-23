defmodule PlugApp.UserHandler do
  alias OpenApiSpex.{Operation, Schema}
  alias PlugApp.{Accounts, Accounts.User}
  alias PlugApp.Schemas
  import OpenApiSpex.Operation, only: [parameter: 5, request_body: 4, response: 3]

  defmodule Index do
    use Plug.Builder

    plug OpenApiSpex.Plug.CastAndValidate,
      json_render_error_v2: true,
      operation_id: "UserHandler.Index"

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
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, render(users))
    end

    def render(users) do
      %{
        data: Enum.map(users, &Map.take(&1, [:id, :name, :email]))
      }
      |> Jason.encode!(pretty: true)
    end
  end

  defmodule Show do
    use Plug.Builder

    plug OpenApiSpex.Plug.CastAndValidate,
      json_render_error_v2: true,
      operation_id: "UserHandler.Show"

    plug :load
    plug :show

    def open_api_operation(_) do
      %Operation{
        tags: ["users"],
        summary: "Show user",
        description: "Show a user by ID",
        operationId: "UserHandler.Show",
        parameters: [
          parameter(:id, :path, %Schema{type: :integer, minimum: 1}, "User ID", example: 123),
          parameter(:qux, :query, %Schema{type: :string}, "qux param", required: false),
          parameter(
            :some,
            :query,
            %Schema{
              type: :object,
              oneOf: [
                %Schema{
                  type: :object,
                  properties: %{foo: %Schema{type: :string}, bar: %Schema{type: :string}},
                  required: [:foo]
                },
                %Schema{
                  type: :object,
                  properties: %{foo: %Schema{type: :string}, baz: %Schema{type: :string}},
                  required: [:baz]
                }
              ]
            },
            "Some query parameter ",
            explode: true,
            style: :form,
            required: true
          )
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

        user ->
          assign(conn, :user, user)
      end
    end

    # def show(conn = %Plug.Conn{assigns: %{user: user}}, _opts) do
    def show(conn, _opts) do
      IO.inspect(conn.params)

      user = Accounts.get_user!(conn.params.id)

      conn
      |> put_resp_header("content-type", "application/json")
      |> send_resp(200, render(user))
    end

    def render(user) do
      %{
        data: Map.take(user, [:id, :name, :email])
      }
      |> Jason.encode!(pretty: true)
    end
  end

  defmodule Create do
    use Plug.Builder

    plug OpenApiSpex.Plug.CastAndValidate,
      json_render_error_v2: true,
      operation_id: "UserHandler.Create"

    plug :create

    def open_api_operation(_) do
      %Operation{
        tags: ["users"],
        summary: "Create user",
        description: "Create a user",
        operationId: "UserHandler.Create",
        requestBody:
          request_body(
            "The user attributes",
            "application/json",
            Schemas.UserRequest,
            required: true
          ),
        responses: %{
          201 => response("User", "application/json", Schemas.UserResponse),
          422 => OpenApiSpex.JsonErrorResponse.response()
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
