defmodule OpenApiSpex.OperationDslTest do
  use ExUnit.Case, async: true

  alias OpenApiSpexTest.DslController

  test "operation/1" do
    assert [
             show: %OpenApiSpex.Operation{
               responses: [],
               summary: "Show user",
               parameters: show_parameters,
               tags: show_tags
             },
             index: %OpenApiSpex.Operation{
               responses: [],
               summary: "User index"
             }
           ] = DslController.spec_attributes()

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
end
