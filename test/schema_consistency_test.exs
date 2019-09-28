defmodule OpenApiSpex.SchemaConsistencyTest do
  use ExUnit.Case
  alias OpenApiSpex.{Schema, SchemaConsistency}

  @valid_schema %Schema{
    title: "Size",
    description: "A size of a pet",
    type: :object,
    properties: %{
      unit: %Schema{type: :string, description: "SI unit name", default: "cm"}
    },
    required: [:unit]
  }

  describe "warnings/1" do
    test "valid schema -> []" do
      assert SchemaConsistency.warnings(@valid_schema) == []
    end

    test "missing :type -> [error]" do
      %{@valid_schema | type: nil}
      |> assert_validation_error(~r/:type is missing or nil/)
    end

    test "invalid :type -> [error]" do
      %{@valid_schema | type: :integer}
      |> assert_validation_error(~r/:type is :integer/)
    end
  end

  defp assert_validation_error(body, pattern) do
    assert [reason] = SchemaConsistency.warnings(body)
    assert reason =~ pattern
  end
end
