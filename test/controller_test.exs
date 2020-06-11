defmodule OpenApiSpex.ControllerTest do
  use ExUnit.Case, async: true

  alias OpenApiSpex.Controller, as: Subject

  import ExUnit.CaptureIO

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

    test "has response for HTTP 401" do
      assert %{responses: %{401 => _}} = @controller.open_api_operation(:update)
    end

    test "has response for HTTP 404" do
      assert %{responses: %{404 => _}} = @controller.open_api_operation(:update)
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

    test "sets the operation_id" do
      op = @controller.open_api_operation(:show)
      assert op.operationId == "show_user"
    end

    test "handles missing description docs" do
      op = @controller.open_api_operation(:minimal_docs)
      assert op.description == ""
      assert op.summary == ""
      assert %{200 => %{description: "Empty"}} = op.responses
    end

    test "has no docs when false" do
      assert capture_io(:stderr, fn ->
        refute @controller.open_api_operation(:skip_this_doc)
      end) == ""
    end

    test "prints warn when no @doc specified" do
      assert capture_io(:stderr, fn ->
        refute @controller.open_api_operation(:no_doc_specified)
      end) =~ ~r/warning:/
    end
  end
end
