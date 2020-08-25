defmodule OpenApiSpex.OperationDslTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias OpenApiSpexTest.DslController

  describe "operation/1" do
    test "defines open_api_operation/1 for :show action" do
      assert %OpenApiSpex.Operation{
               responses: [],
               summary: "Show user",
               parameters: show_parameters,
               tags: show_tags
             } = DslController.open_api_operation(:show)

      assert show_tags == ["users"]

      assert [
               %OpenApiSpex.Parameter{
                 description: "User ID",
                 example: 1001,
                 in: :path,
                 name: :id,
                 required: true,
                 schema: %OpenApiSpex.Schema{type: :integer}
               }
             ] = show_parameters
    end

    test "defines open_api_operation/1 for :index action" do
      assert %OpenApiSpex.Operation{
               responses: [],
               summary: "User index",
               parameters: index_parameters
             } = DslController.open_api_operation(:index)

      assert [
               %OpenApiSpex.Parameter{
                 description: "Free-form query string",
                 example: "jane",
                 in: :query,
                 name: :query,
                 schema: %OpenApiSpex.Schema{type: :string}
               }
             ] = index_parameters
    end

    test "outputs warning when action not defined for called open_api_operation" do
      output = capture_io(:stderr, fn -> DslController.open_api_operation(:undefined) end)

      assert output =~
               ~r/warning:.*No operation spec defined for controller action OpenApiSpexTest.DslController.undefined/
    end
  end
end
