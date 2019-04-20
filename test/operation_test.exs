defmodule OpenApiSpex.OperationTest do
  use ExUnit.Case
  alias OpenApiSpex.Operation
  alias OpenApiSpexTest.UserController

  describe "Operation.from_route" do
    test "succeeds when all path params present" do
      route = %{plug: UserController, opts: :show, path: "/users/:id"}
      assert Operation.from_route(route) == {:ok, UserController.show_operation()}
    end

    test "Fails on missing path params" do
      path = "/teams/:missing_team_id_param/users/:id"
      route = %{plug: UserController, opts: :show, path: path}
      assert {:error, message} = Operation.from_route(route)
      assert message =~ "missing_team_id_param"
    end

    test "Allows additional path params not known to phoenix" do
      path = "/no/path/params"
      route = %{plug: UserController, opts: :show, path: path}
      assert {:ok, _operation} = Operation.from_route(route)
    end
  end

  describe "Operation.from_plug" do
    test "invokes the plug to get the Operation" do
      assert Operation.from_plug(UserController, :show) == UserController.show_operation()
    end
  end
end
