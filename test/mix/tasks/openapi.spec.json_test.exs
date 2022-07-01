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

    assert parse_file(actual_schema_path) == parse_file(expected_schema_path)
  end

  defp parse_file(filename), do: filename |> File.read!() |> String.split("\n")
end
