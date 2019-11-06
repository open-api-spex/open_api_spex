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
      assert %OpenApiSpex.Operation{} = @controller.open_api_operation(:update)
    end

    test "summary matches 'Endpoint summary'" do
      op = @controller.open_api_operation(:update)
      assert op.summary == "Update a user"
      assert op.description == "Update a user\n\nFull description for this endpoint...\n"
    end

    test "has response for HTTP 200" do
      assert %{responses: %{200 => _}} = @controller.open_api_operation(:update)
    end

    test "has parameter `:id`" do
      assert %{parameters: [param]} = @controller.open_api_operation(:update)
      assert param.name == :id
      assert param.required
    end

    test "has a requestBody" do
      op = @controller.open_api_operation(:update)
      assert %OpenApiSpex.RequestBody{} = op.requestBody
      assert op.requestBody.description == "Request body to update a User"
      assert op.requestBody.required == true
      assert %OpenApiSpex.MediaType{schema: schema} = op.requestBody.content["application/json"]
      assert schema == OpenApiSpexTest.Schemas.User
    end
  end
end
