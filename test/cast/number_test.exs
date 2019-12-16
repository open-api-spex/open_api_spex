defmodule OpenApiSpex.CastNumberTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, Schema}
  alias OpenApiSpex.Cast.{Error, Number}

  defp cast(ctx), do: Number.cast(struct(Cast, ctx))

  describe "cast/1" do
    test "basics" do
      schema = %Schema{type: :number}
      assert cast(value: 1, schema: schema) === {:ok, 1}
      assert cast(value: 1.5, schema: schema) === {:ok, 1.5}
      assert cast(value: "1", schema: schema) === {:ok, 1.0}
      assert cast(value: "1.5", schema: schema) === {:ok, 1.5}
      assert {:error, [error]} = cast(value: "other", schema: schema)
      assert %Error{reason: :invalid_type} = error
      assert error.value == "other"
    end

    test "with minimum" do
      schema = %Schema{type: :number, minimum: 2}
      assert cast(value: 3, schema: schema) === {:ok, 3}
      assert cast(value: 2, schema: schema) === {:ok, 2}
      assert {:error, [error]} = cast(value: 1, schema: schema)
      assert error.reason == :minimum
      assert error.value === 1
      # error.length is the minimum
      assert error.length === 2
      assert Error.message(error) =~ "smaller than inclusive minimum"
    end

    test "with maximum" do
      schema = %Schema{type: :number, maximum: 2}
      assert cast(value: 1, schema: schema) === {:ok, 1}
      assert cast(value: 2, schema: schema) === {:ok, 2}
      assert {:error, [error]} = cast(value: 3, schema: schema)
      assert error.reason === :maximum
      assert error.value === 3
      # error.length is the maximum
      assert error.length === 2
      assert Error.message(error) =~ "larger than inclusive maximum"
    end

    test "with minimum w/ exclusiveMinimum" do
      schema = %Schema{type: :number, minimum: 2, exclusiveMinimum: true}
      assert cast(value: 3, schema: schema) == {:ok, 3}
      assert {:error, [error]} = cast(value: 2, schema: schema)
      assert error.reason == :exclusive_min
      assert error.value == 2
      # error.length is the minimum
      assert error.length == 2
      assert Error.message(error) =~ "smaller than exclusive minimum"
    end

    test "with maximum w/ exclusiveMaximum" do
      schema = %Schema{type: :number, maximum: 2, exclusiveMaximum: true}
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
