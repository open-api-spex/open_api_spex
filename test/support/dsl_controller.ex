defmodule OpenApiSpexTest.DslController do
  use Phoenix.Controller

  import OpenApiSpex.OperationDsl

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

  tags ["users"]

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
    ]

  def update(conn, %{"id" => id}) do
    json(conn, %{
      data: %{
        id: id,
        name: "joe user",
        email: "joe@gmail.com"
      }
    })
  end
end
