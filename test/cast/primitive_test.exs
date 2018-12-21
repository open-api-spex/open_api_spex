defmodule OpenApiSpex.PrimitiveTest do
  use ExUnit.Case
  alias OpenApiSpex.Cast
  alias OpenApiSpex.Cast.{Primitive, Error}
  import Primitive

  describe "cast/3" do
    test "boolean" do
      assert cast_boolean(%Cast{value: true}) == {:ok, true}
      assert cast_boolean(%Cast{value: false}) == {:ok, false}
      assert cast_boolean(%Cast{value: "true"}) == {:ok, true}
      assert cast_boolean(%Cast{value: "false"}) == {:ok, false}
      assert {:error, [error]} = cast_boolean(%Cast{value: "other"})
      assert %Error{reason: :invalid_type} = error
      assert error.value == "other"
    end

    test "number" do
      assert cast_number(%Cast{value: 1}) == {:ok, 1.0}
      assert cast_number(%Cast{value: 1.5}) == {:ok, 1.5}
      assert cast_number(%Cast{value: "1"}) == {:ok, 1.0}
      assert cast_number(%Cast{value: "1.5"}) == {:ok, 1.5}
      assert {:error, [error]} = cast_number(%Cast{value: "other"})
      assert %Error{reason: :invalid_type} = error
      assert error.value == "other"
    end
  end
end
