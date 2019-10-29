defmodule OpenApiSpex.ControllerTest do
  use ExUnit.Case, async: true

  alias OpenApiSpex.Controller, as: Subject

  doctest Subject

  @controller OpenApiSpexTest.UserControllerAnnotated

  describe "Example module" do
    test "exports open_api_operation/1" do
      assert function_exported?(@controller, :open_api_operation, 1)
    end

    test "has defined OpenApiSpex.Operation for show action" do
      assert %OpenApiSpex.Operation{} = @controller.open_api_operation(:show)
    end

    test "summary matches 'Endpoint summary'" do
      assert %{summary: "Endpoint summary"} = @controller.open_api_operation(:show)
    end

    test "has response for HTTP 200" do
      assert %{responses: %{200 => _}} = @controller.open_api_operation(:show)
    end

    test "has parameter `:id`" do
      assert %{parameters: [param]} = @controller.open_api_operation(:show)
      assert param.name == :id
      assert param.required
    end
  end
end
