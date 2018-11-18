defmodule OpenApiSpec.CastArrayTest do
  use ExUnit.Case
  import OpenApiSpex.CastArray
  alias OpenApiSpex.{Error, Schema}

  describe "cast/4" do
    test "array" do
      schema = %Schema{type: :array}
      assert cast([], schema) == {:ok, []}
      assert cast([1, 2, 3], schema) == {:ok, [1, 2, 3]}
      assert cast(["1", "2", "3"], schema) == {:ok, ["1", "2", "3"]}

      assert {:error, error} = cast(%{}, schema)
      assert %Error{} = error
      assert error.reason == :invalid_type
      assert error.value == %{}
    end

    test "array with items schema" do
      items_schema = %Schema{type: :integer}
      schema = %Schema{type: :array, items: items_schema}
      assert cast([], schema) == {:ok, []}
      assert cast([1, 2, 3], schema) == {:ok, [1, 2, 3]}
      assert cast(["1", "2", "3"], schema) == {:ok, [1, 2, 3]}

      assert {:error, error} = cast([1, "two"], schema)
      assert %Error{} = error
      assert error.reason == :invalid_type
      assert error.value == "two"
      assert error.path == [1]
    end
  end
end
