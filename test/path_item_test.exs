defmodule OpenApiSpex.PathItemTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias OpenApiSpex.PathItem
  alias OpenApiSpexTest.{DslController, Router, UserController}

  describe "PathItem" do
    test "from_routes" do
      routes =
        for route <- Router.__routes__(),
            route.path == "/api/users",
            do: route

      path_item = PathItem.from_routes(routes)

      assert path_item == %PathItem{
               get: UserController.open_api_operation(:index),
               post: UserController.open_api_operation(:create)
             }
    end

    test "from_routes skips an action without an operation spec" do
      routes = [%{verb: :get, path: "/undefined", plug: DslController, plug_opts: :undefined}]

      capture_io(:stderr, fn -> assert nil == PathItem.from_routes(routes) end)
    end
  end
end
