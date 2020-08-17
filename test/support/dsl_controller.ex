defmodule OpenApiSpexTest.DslController do
  use Phoenix.Controller

  import OpenApiSpex.OperationDsl

  alias OpenApiSpex.Schema
  alias OpenApiSpexTest.Schemas

  operation(:index, summary: "User index", responses: [])

  def index(conn, _params) do
    json(conn, %Schemas.UserResponse{
      data: [
        %Schemas.User{
          id: "abc123",
          name: "joe user",
          email: "joe@gmail.com"
        }
      ]
    })
  end

  operation(:show,
    summary: "Show user",
    parameters: [
      %OpenApiSpex.Parameter{
        in: :path,
        name: :id,
        description: "User ID",
        schema: %Schema{type: :integer},
        required: true,
        example: 1001
      }
    ],
    responses: []
  )

  def show(conn, %{id: id}) do
    json(conn, %Schemas.UserResponse{
      data: %Schemas.User{
        id: id,
        name: "joe user",
        email: "joe@gmail.com"
      }
    })
  end
end
