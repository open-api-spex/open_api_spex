defmodule OpenApiSpec.Cast.ArrayTest do
  use ExUnit.Case
  alias OpenApiSpex.Cast.{Array, Error}
  alias OpenApiSpex.{Cast, Schema}

  defp cast(map), do: Array.cast(struct(Cast, map))

  describe "cast/4" do
    test "array" do
      schema = %Schema{type: :array}
      assert cast(value: [], schema: schema) == {:ok, []}
      assert cast(value: [1, 2, 3], schema: schema) == {:ok, [1, 2, 3]}
      assert cast(value: ["1", "2", "3"], schema: schema) == {:ok, ["1", "2", "3"]}

      assert {:error, [error]} = cast(value: %{}, schema: schema)
      assert %Error{} = error
      assert error.reason == :invalid_type
      assert error.value == %{}
    end

    test "with maxItems" do
      schema = %Schema{type: :array, maxItems: 2}
      assert cast(value: [1, 2], schema: schema) == {:ok, [1, 2]}
      assert {:error, [error]} = cast(value: [1, 2, 3], schema: schema)

      assert %Error{} = error
      assert error.reason == :max_items
      assert error.value == [1, 2, 3]
    end

    test "with minItems" do
      schema = %Schema{type: :array, minItems: 2}
      assert cast(value: [1, 2], schema: schema) == {:ok, [1, 2]}
      assert {:error, [error]} = cast(value: [1], schema: schema)

      assert %Error{} = error
      assert error.reason == :min_items
      assert error.value == [1]

      # Test for #179, "minLength validation ignores empty array"
      assert {:error, [%Error{reason: :min_items, value: []}]} = cast(value: [], schema: schema)
      # Negative test, check that minItems: 0 allows an empty array
      assert cast(value: [], schema: %Schema{type: :array, minItems: 0}) == {:ok, []}
    end

    test "with uniqueItems" do
      schema = %Schema{type: :array, uniqueItems: true}
      assert cast(value: [1, 2], schema: schema) == {:ok, [1, 2]}
      assert {:error, [error]} = cast(value: [1, 1], schema: schema)

      assert %Error{} = error
      assert error.reason == :unique_items
      assert error.value == [1, 1]
    end

    test "array with items schema" do
      items_schema = %Schema{type: :integer}
      schema = %Schema{type: :array, items: items_schema}
      assert cast(value: [], schema: schema) == {:ok, []}
      assert cast(value: [1, 2, 3], schema: schema) == {:ok, [1, 2, 3]}
      assert cast(value: ["1", "2", "3"], schema: schema) == {:ok, [1, 2, 3]}

      assert {:error, [error]} = cast(value: [1, "two"], schema: schema)
      assert %Error{} = error
      assert error.reason == :invalid_type
      assert error.value == "two"
      assert error.path == [1]
    end
  end
end
