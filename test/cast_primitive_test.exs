defmodule OpenApiSpex.CastPrimitiveTest do
  use ExUnit.Case
  alias OpenApiSpex.{Error, Schema}
  import OpenApiSpex.CastPrimitive

  describe "cast/3" do
    test "boolean" do
      schema = %Schema{type: :boolean}
      assert cast(true, schema) == {:ok, true}
      assert cast(false, schema) == {:ok, false}
      assert cast("true", schema) == {:ok, true}
      assert cast("false", schema) == {:ok, false}
      assert {:error, error} = cast("other", schema)
      assert %Error{reason: :invalid_type} = error
      assert error.value == "other"
    end

    test "integer" do
      schema = %Schema{type: :integer}
      assert cast(1, schema) == {:ok, 1}
      assert cast(1.5, schema) == {:ok, 2}
      assert cast("1", schema) == {:ok, 1}
      assert cast("1.5", schema) == {:ok, 2}
      assert {:error, error} = cast("other", schema)
      assert %Error{reason: :invalid_type} = error
      assert error.value == "other"
    end

    test "number" do
      schema = %Schema{type: :number}
      assert cast(1, schema) == {:ok, 1.0}
      assert cast(1.5, schema) == {:ok, 1.5}
      assert cast("1", schema) == {:ok, 1.0}
      assert cast("1.5", schema) == {:ok, 1.5}
      assert {:error, error} = cast("other", schema)
      assert %Error{reason: :invalid_type} = error
      assert error.value == "other"
    end

    test "string" do
      schema = %Schema{type: :string}
      assert cast("hello", schema) == {:ok, "hello"}
      assert cast("", schema) == {:ok, ""}
      assert {:error, error} = cast(%{}, schema)
      assert %Error{reason: :invalid_type} = error
      assert error.value == %{}
    end
  end
end
