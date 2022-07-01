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

    assert parse_file(actual_schema_path) == parse_file(expected_schema_path)
  end

  defp parse_file(filename), do: filename |> File.read!() |> String.split("\n")
end
