defmodule OpenApiSpex.PathItemTest do
  use ExUnit.Case
  alias OpenApiSpex.PathItem
  alias OpenApiSpexTest.{Router, UserController}

  describe "PathItem" do
    @tag :focus
    test "from_routes" do
      routes =
        for route <- Router.__routes__(),
            route.path == "/api/users",
            do: route

      path_item = PathItem.from_routes(routes)
      assert path_item == %PathItem{
        get: UserController.index_operation(),
        post: UserController.create_operation()
      }
    end
  end
end