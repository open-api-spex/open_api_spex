defmodule Mix.Tasks.Openapi.Spec.JsonTest do
  use ExUnit.Case

  test "generates openapi.json" do
    actual_schema_path = "tmp/openapi.json"

    Mix.Tasks.Openapi.Spec.Json.run(~w(
      --pretty=true
      --spec OpenApiSpexTest.Tasks.SpecModule
      --vendor-extensions=false
      #{actual_schema_path}
    ))

    expected_schema_path = "test/support/tasks/openapi.json"

    assert_received {:mix_shell, :info, ["* creating tmp"]}
    assert_received {:mix_shell, :info, ["* creating tmp/openapi.json"]}

    assert File.read!(actual_schema_path) == File.read!(expected_schema_path)
  end
end
