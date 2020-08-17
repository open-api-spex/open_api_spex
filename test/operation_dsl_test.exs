defmodule OpenApiSpex.OperationDslTest do
  use ExUnit.Case, async: true

  alias OpenApiSpexTest.DslController

  test "operation/1" do
    assert [
             show: %OpenApiSpex.Operation{
               responses: [],
               summary: "Show user"
             },
             index: %OpenApiSpex.Operation{
               responses: [],
               summary: "User index"
             }
           ] = DslController.spec_attributes()
  end
end
