defmodule OpenApiSpex.OperationDslTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias OpenApiSpex.{MediaType, RequestBody, Response}
  alias OpenApiSpexTest.DslController

  describe "operation/1" do
    test "supports :parameters" do
      assert %OpenApiSpex.Operation{
               responses: %{},
               summary: "Update user",
               parameters: update_parameters,
               tags: update_tags
             } = DslController.open_api_operation(:update)

      assert update_tags == ["users"]

      assert [
               %OpenApiSpex.Parameter{
                 description: "User ID",
                 example: 1001,
                 in: :path,
                 name: :id,
                 required: true,
                 schema: %OpenApiSpex.Schema{type: :integer}
               }
             ] = update_parameters
    end

    test ":request_body" do
      assert %OpenApiSpex.Operation{
               summary: "Update user",
               requestBody: request_body
             } = DslController.open_api_operation(:update)

      assert %RequestBody{
               content: %{"application/json" => media_type},
               description: "User params"
             } = request_body

      assert %MediaType{schema: OpenApiSpexTest.DslController.UserParams} = media_type
    end

    test ":responses" do
      assert %OpenApiSpex.Operation{
               summary: "Update user",
               responses: responses
             } = DslController.open_api_operation(:update)

      assert %{200 => response} = responses

      assert %Response{
               content: %{"application/json" => media_type},
               description: "User response"
             } = response

      assert %MediaType{schema: OpenApiSpexTest.DslController.UserResponse} = media_type
    end

    test "outputs warning when action not defined for called open_api_operation" do
      output = capture_io(:stderr, fn -> DslController.open_api_operation(:undefined) end)

      assert output =~
               ~r/warning:.*No operation spec defined for controller action OpenApiSpexTest.DslController.undefined/
    end
  end
end
