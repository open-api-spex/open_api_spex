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

    test "with a Decimal" do
      schema = %Schema{type: :integer}

      assert {:ok, 1} = cast(value: Decimal.new(1), schema: schema)

      number = Decimal.new("1.2")

      assert {:error, [%{reason: :invalid_type, value: ^number}]} =
               cast(value: number, schema: schema)
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

    test "with minimum struct" do
      schema = %Schema{type: :integer, minimum: %Schema.MinMax{value: 2}}
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

    test "with maximum struct" do
      schema = %Schema{type: :integer, maximum: %Schema.MinMax{value: 2}}
      assert cast(value: 1, schema: schema) == {:ok, 1}
      assert cast(value: 2, schema: schema) == {:ok, 2}
      assert {:error, [error]} = cast(value: 3, schema: schema)
      assert error.reason == :maximum
      assert error.value == 3
      # error.length is the maximum
      assert error.length == 2
      assert Error.message(error) =~ "larger than inclusive maximum"
    end

    test "with exclusive minimum" do
      schema = %Schema{type: :integer, minimum: %Schema.MinMax{value: 2, exclusive?: true}}
      assert cast(value: 3, schema: schema) == {:ok, 3}
      assert {:error, [error]} = cast(value: 2, schema: schema)
      assert error.reason == :exclusive_min
      assert error.value == 2
      # error.length is the minimum
      assert error.length == 2
      assert Error.message(error) =~ "smaller than exclusive minimum"
    end

    test "with exclusive maximum" do
      schema = %Schema{type: :integer, maximum: %Schema.MinMax{value: 2, exclusive?: true}}
      assert cast(value: 1, schema: schema) == {:ok, 1}
      assert {:error, [error]} = cast(value: 2, schema: schema)
      assert error.reason == :exclusive_max
      assert error.value == 2
      # error.length is the maximum
      assert error.length == 2
      assert Error.message(error) =~ "larger than exclusive maximum"
    end

    test "format int32" do
      schema = %Schema{type: :integer, format: :int32}
      # less than max int32
      assert {:error, [error]} = cast(value: -2_147_483_648, schema: schema)
      assert error.reason == :invalid_format
      assert error.format == :int32
      # over max int32
      assert {:error, [error]} = cast(value: 2_147_483_648, schema: schema)
      assert error.reason == :invalid_format
      assert error.format == :int32
    end

    test "format int64" do
      schema = %Schema{type: :integer, format: :int64}
      # less than max int64
      assert {:error, [error]} = cast(value: -9_223_372_036_854_775_808, schema: schema)
      assert error.reason == :invalid_format
      assert error.format == :int64
      # over max int64
      assert {:error, [error]} = cast(value: 9_223_372_036_854_775_808, schema: schema)
      assert error.reason == :invalid_format
      assert error.format == :int64
    end
  end
end
