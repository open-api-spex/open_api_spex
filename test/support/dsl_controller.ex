defmodule OpenApiSpexTest.DslController do
  use Phoenix.Controller

  import OpenApiSpex.OperationDsl

  alias OpenApiSpexTest.Schemas

  # operation(:show, summary: "Show user")
  operation(:show, :foo)

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
