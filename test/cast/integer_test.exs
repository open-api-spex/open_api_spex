defmodule OpenApiSpex.CastIntegerTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, Schema}
  alias OpenApiSpex.Cast.{Error, Integer}

  defp cast(ctx), do: Integer.cast(struct(Cast, ctx))

  describe "cast/1" do
    test "basics" do
      schema = %Schema{type: :integer}
      assert cast(value: 1, schema: schema) == {:ok, 1}
      assert cast(value: "1", schema: schema) == {:ok, 1}
      assert {:error, [error]} = cast(value: 1.5, schema: schema)
      assert %Error{reason: :invalid_type, value: 1.5} = error
      assert {:error, [error]} = cast(value: "1.5", schema: schema)
      assert %Error{reason: :invalid_type, value: "1.5"} = error
      assert {:error, [error]} = cast(value: "other", schema: schema)
      assert %Error{reason: :invalid_type, value: "other"} = error
    end

    test "with multiple of" do
      schema = %Schema{type: :integer, multipleOf: 2}
      assert cast(value: 2, schema: schema) == {:ok, 2}
      assert {:error, [error]} = cast(value: 3, schema: schema)
      assert error.reason == :multiple_of
      assert error.value == 3
      # error.length is the multiple
      assert error.length == 2
    end

    test "with minimum" do
      schema = %Schema{type: :integer, minimum: 2}
      assert cast(value: 3, schema: schema) == {:ok, 3}
      assert cast(value: 2, schema: schema) == {:ok, 2}
      assert {:error, [error]} = cast(value: 1, schema: schema)
      assert error.reason == :minimum
      assert error.value == 1
      # error.length is the minimum
      assert error.length == 2
      assert Error.message(error) =~ "smaller than inclusive minimum"
    end

    test "with maximum" do
      schema = %Schema{type: :integer, maximum: 2}
      assert cast(value: 1, schema: schema) == {:ok, 1}
      assert cast(value: 2, schema: schema) == {:ok, 2}
      assert {:error, [error]} = cast(value: 3, schema: schema)
      assert error.reason == :maximum
      assert error.value == 3
      # error.length is the maximum
      assert error.length == 2
      assert Error.message(error) =~ "larger than inclusive maximum"
    end

    test "with minimum w/ exclusiveMinimum" do
      schema = %Schema{type: :integer, minimum: 2, exclusiveMinimum: true}
      assert cast(value: 3, schema: schema) == {:ok, 3}
      assert {:error, [error]} = cast(value: 2, schema: schema)
      assert error.reason == :exclusive_min
      assert error.value == 2
      # error.length is the minimum
      assert error.length == 2
      assert Error.message(error) =~ "smaller than exclusive minimum"
    end

    test "with maximum w/ exclusiveMaximum" do
      schema = %Schema{type: :integer, maximum: 2, exclusiveMaximum: true}
      assert cast(value: 1, schema: schema) == {:ok, 1}
      assert {:error, [error]} = cast(value: 2, schema: schema)
      assert error.reason == :exclusive_max
      assert error.value == 2
      # error.length is the maximum
      assert error.length == 2
      assert Error.message(error) =~ "larger than exclusive maximum"
    end
  end
end
