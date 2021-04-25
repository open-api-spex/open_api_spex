defmodule OpenApiSpex.ControllerTest do
  use ExUnit.Case, async: true

  alias OpenApiSpex.Reference
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
      assert op.description == "Full description for this endpoint...\n"
    end

    test "security matches 'foo'" do
      op = @controller.open_api_operation(:update)
      assert op.security == [%{"authorization" => []}]
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

    test "has default response" do
      assert %{responses: %{:default => _}} = @controller.open_api_operation(:update)
    end

    test "has parameter `:id`" do
      assert %{parameters: [param]} = @controller.open_api_operation(:update)
      assert param.name == :id
      assert param.required
    end

    test "has parameter `%Reference{}`" do
      assert %{parameters: [%Reference{}]} = @controller.open_api_operation(:show)
    end

    test "has a requestBody" do
      op = @controller.open_api_operation(:update)
      assert %OpenApiSpex.RequestBody{} = op.requestBody
      assert op.requestBody.description == "Request body to update a User"
      assert op.requestBody.required == true
      assert %OpenApiSpex.MediaType{schema: schema} = op.requestBody.content["application/json"]
      assert schema == OpenApiSpexTest.Schemas.User
    end

    test "has externalDocs" do
      %{externalDocs: external_docs} = @controller.open_api_operation(:update)

      assert %OpenApiSpex.ExternalDocumentation{description: description, url: url} =
               external_docs

      assert description == "Check out these docs"
      assert url == "https://example.com/"
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

  describe "spec parameters" do
    test "pass when only schema specified" do
      op = @controller.open_api_operation(:only_schema_parameter_present_docs)
      assert [parameter] = op.parameters
      assert %OpenApiSpex.Schema{type: :string} = parameter.schema
      assert op.description == ""
      assert op.summary == ""
      assert %{200 => %{description: "Empty"}} = op.responses
    end

    test "pass when only type shortcut specified" do
      op = @controller.open_api_operation(:only_type_parameter_present_docs)
      assert [parameter] = op.parameters
      assert %OpenApiSpex.Schema{type: :string} = parameter.schema
      assert op.description == ""
      assert op.summary == ""
      assert %{200 => %{description: "Empty"}} = op.responses
    end

    test "fails on both type and schema specified" do
      assert_raise ArgumentError, ~r/Both :type and :schema options were specified/, fn ->
        @controller.open_api_operation(:non_exlusive_paramter_type_schema_docs)
      end
    end
  end
end
