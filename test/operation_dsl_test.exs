defmodule OpenApiSpex.OperationDslTest do
  use ExUnit.Case, async: true

  alias OpenApiSpexTest.DslController
  # alias OpenApiSpex.OperationDsl

  test "operation/1" do
    assert DslController.spec_attributes() == [
             {:show, [summary: "Show user"]},
             {:index, [summary: "User index"]}
           ]
  end
end
