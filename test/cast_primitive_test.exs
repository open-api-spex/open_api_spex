defmodule OpenApiSpex.CastPrimitiveTest do
  use ExUnit.Case
  alias OpenApiSpex.{CastContext, CastPrimitive, CastError, Schema}

  defp cast(ctx), do: CastPrimitive.cast(struct(CastContext, ctx))

  describe "cast/3" do
    test "boolean" do
      schema = %Schema{type: :boolean}
      assert cast(value: true, schema: schema) == {:ok, true}
      assert cast(value: false, schema: schema) == {:ok, false}
      assert cast(value: "true", schema: schema) == {:ok, true}
      assert cast(value: "false", schema: schema) == {:ok, false}
      assert {:error, [error]} = cast(value: "other", schema: schema)
      assert %CastError{reason: :invalid_type} = error
      assert error.value == "other"
    end

    test "integer" do
      schema = %Schema{type: :integer}
      assert cast(value: 1, schema: schema) == {:ok, 1}
      assert cast(value: 1.5, schema: schema) == {:ok, 2}
      assert cast(value: "1", schema: schema) == {:ok, 1}
      assert cast(value: "1.5", schema: schema) == {:ok, 2}
      assert {:error, [error]} = cast(value: "other", schema: schema)
      assert %CastError{reason: :invalid_type} = error
      assert error.value == "other"
    end

    test "number" do
      schema = %Schema{type: :number}
      assert cast(value: 1, schema: schema) == {:ok, 1.0}
      assert cast(value: 1.5, schema: schema) == {:ok, 1.5}
      assert cast(value: "1", schema: schema) == {:ok, 1.0}
      assert cast(value: "1.5", schema: schema) == {:ok, 1.5}
      assert {:error, [error]} = cast(value: "other", schema: schema)
      assert %CastError{reason: :invalid_type} = error
      assert error.value == "other"
    end

    # Additional string tests are covered in CastStringTest
    test "string" do
      schema = %Schema{type: :string}
      assert cast(value: "hello", schema: schema) == {:ok, "hello"}
      assert cast(value: "", schema: schema) == {:ok, ""}
      assert {:error, [error]} = cast(value: %{}, schema: schema)
      assert %CastError{reason: :invalid_type} = error
      assert error.value == %{}
    end
  end
end
