defmodule OpenApiSpex.OperationTest do
  use ExUnit.Case
  alias OpenApiSpex.Operation
  alias OpenApiSpexTest.UserController

  describe "Operation" do
    test "from_route" do
      route = %{plug: UserController, opts: :show}
      assert Operation.from_route(route) == UserController.show_operation()
    end

    test "from_plug" do
      assert Operation.from_plug(UserController, :show) == UserController.show_operation()
    end
  end
end