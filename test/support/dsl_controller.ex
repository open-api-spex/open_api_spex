defmodule OpenApiSpexTest.DslController do
  use Phoenix.Controller

  import OpenApiSpex.OperationDsl

  tags ["users"]

  operation :index,
    summary: "User index",
    parameters: [
      query: [in: :query, type: :string, description: "Free-form query string", example: "jane"]
    ]

  def index(conn, _params) do
    json(conn, %{
      data: [
        %{
          id: "abc123",
          name: "joe user",
          email: "joe@gmail.com"
        }
      ]
    })
  end

  operation :show,
    summary: "Show user",
    parameters: [
      id: [
        in: :path,
        description: "User ID",
        type: :integer,
        example: 1001
      ]
    ]

  def show(conn, %{id: id}) do
    json(conn, %{
      data: %{
        id: id,
        name: "joe user",
        email: "joe@gmail.com"
      }
    })
  end
end
