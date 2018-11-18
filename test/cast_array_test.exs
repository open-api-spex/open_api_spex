defmodule OpenApiSpec.CastArrayTest do
  use ExUnit.Case
  alias OpenApiSpex.{CastArray, CastContext, CastError, Schema}

  defp cast(map), do: CastArray.cast(struct(CastContext, map))

  describe "cast/4" do
    test "array" do
      schema = %Schema{type: :array}
      assert cast(value: [], schema: schema) == {:ok, []}
      assert cast(value: [1, 2, 3], schema: schema) == {:ok, [1, 2, 3]}
      assert cast(value: ["1", "2", "3"], schema: schema) == {:ok, ["1", "2", "3"]}

      assert {:error, [error]} = cast(value: %{}, schema: schema)
      assert %CastError{} = error
      assert error.reason == :invalid_type
      assert error.value == %{}
    end

    test "array with items schema" do
      items_schema = %Schema{type: :integer}
      schema = %Schema{type: :array, items: items_schema}
      assert cast(value: [], schema: schema) == {:ok, []}
      assert cast(value: [1, 2, 3], schema: schema) == {:ok, [1, 2, 3]}
      assert cast(value: ["1", "2", "3"], schema: schema) == {:ok, [1, 2, 3]}

      assert {:error, [error]} = cast(value: [1, "two"], schema: schema)
      assert %CastError{} = error
      assert error.reason == :invalid_type
      assert error.value == "two"
      assert error.path == [1]
    end
  end
end
