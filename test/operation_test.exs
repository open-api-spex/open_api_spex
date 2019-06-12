defmodule OpenApiSpex.OperationTest do
  use ExUnit.Case
  alias OpenApiSpex.Operation
  alias OpenApiSpexTest.UserController

  describe "Operation" do
    test "from_route %Phoenix.Router.Route{}" do
      plug = UserController
      plug_opts = :show

      route = Phoenix.Router.Route.build(
        _line = nil,
        _kind = :match,
        _verb = :atom,
        _path = nil,
        _host = nil,
        plug,
        plug_opts,
        _helper = nil,
        _pipe_through = [],
        _private = %{},
        _assigns = %{}
      )
      assert Operation.from_route(route) == UserController.show_operation()
    end

    test "from_route ~ phoenix v1.4.7+" do
      route = %{plug: UserController, plug_opts: :show}
      assert Operation.from_route(route) == UserController.show_operation()
    end

    test "from_plug" do
      assert Operation.from_plug(UserController, :show) == UserController.show_operation()
    end
  end
end
