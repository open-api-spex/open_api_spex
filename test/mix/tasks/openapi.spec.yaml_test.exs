defmodule Mix.Tasks.Openapi.Spec.YamlTest do
  use ExUnit.Case

  test "generates openapi.yaml" do
    actual_schema_path = "tmp/openapi.yaml"

    Mix.Tasks.Openapi.Spec.Yaml.run(~w(
      --spec OpenApiSpexTest.Tasks.SpecModule
      --vendor-extensions=false
      #{actual_schema_path}
    ))

    expected_schema_path = "test/support/tasks/openapi.yaml"

    assert_received {:mix_shell, :info, ["* creating tmp"]}
    assert_received {:mix_shell, :info, ["* creating tmp/openapi.yaml"]}

    assert File.read!(actual_schema_path) == File.read!(expected_schema_path)
  end
end
