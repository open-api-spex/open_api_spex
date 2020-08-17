defmodule OpenApiSpex.OperationDslTest do
  use ExUnit.Case, async: true

  alias OpenApiSpexTest.DslController
  # alias OpenApiSpex.OperationDsl

  test "operation/1" do
    assert DslController.spec_attributes() == [summary: "Show user"]
  end

  # test "operation_def/2" do
  #   ast = OperationDsl.operation_def(:index, :foo)
  #   # IO.inspect(ast, label: "ast")

  #   code = Macro.to_string(ast)
  #   IO.puts(code)
  # end
end
