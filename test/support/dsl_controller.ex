defmodule OpenApiSpexTest.DslController do
  use Phoenix.Controller
  use OpenApiSpex.ControllerSpecs

  defmodule UserParams do
    alias OpenApiSpex.Schema
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :object,
      properties: %{
        email: %Schema{type: :string},
        name: %Schema{type: :string}
      }
    })
  end

  defmodule UserResponse do
    alias OpenApiSpex.Schema
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :object,
      properties: %{
        id: %Schema{type: :string},
        email: %Schema{type: :string},
        name: %Schema{type: :string}
      }
    })
  end

  defmodule UsersIndexResponse do
    alias OpenApiSpex.Schema
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :array,
      items: %Schema{
        type: :object,
        properties: %{
          id: %Schema{type: :string},
          email: %Schema{type: :string},
          name: %Schema{type: :string}
        }
      }
    })
  end

  defmodule UsersDestroyResponse do
    alias OpenApiSpex.Schema
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :string
    })
  end

  tags ["users"]

  security [%{"api_key" => ["mySecurityScheme"]}]

  operation :update,
    summary: "Update user",
    parameters: [
      id: [
        in: :path,
        description: "User ID",
        type: :integer,
        example: 1001
      ]
    ],
    request_body: {"User params", "application/json", UserParams},
    responses: [
      ok: {"User response", "application/json", UserResponse}
    ],
    tags: ["custom"],
    security: [%{"two" => ["another"]}]

  def update(conn, %{"id" => id}) do
    json(conn, %{
      data: %{
        id: id,
        name: "joe user",
        email: "joe@gmail.com"
      }
    })
  end

  operation :index,
    summary: "Users index",
    parameters: [
      username: [
        in: :query,
        description: "Filter by username",
        type: :string
      ]
    ],
    responses: [
      ok: {"Users index response", "application/json", UsersIndexResponse}
    ]

  def index(conn, _) do
    json(conn, [])
  end

  operation :destroy,
    deprecated: true,
    summary: "User destroy",
    parameters: [
      username: [
        in: :query,
        description: "Username to destroy",
        type: :string
      ]
    ],
    responses: [
      no_content: {"Users destroy response", "application/json", UsersDestroyResponse}
    ]

  def index(conn, _) do
    json(conn, [])
  end
end
