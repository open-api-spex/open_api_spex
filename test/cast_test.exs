defmodule OpenApiSpec.CastTest do
  use ExUnit.Case
  import OpenApiSpex.Cast
  alias OpenApiSpex.{Error, Schema}

  describe "cast/3" do
    # Note: full tests for primitives are covered in CastPrimitiveTest
    test "primitives" do
      tests = [
        {:string, "1", :ok},
        {:string, "", :ok},
        {:string, true, :invalid},
        {:string, nil, :invalid},
        {:integer, 1, :ok},
        {:integer, "1", :ok},
        {:integer, %{}, :invalid},
        {:integer, nil, :invalid}
      ]

      for {type, input, expected} <- tests do
        case expected do
          :ok -> assert {:ok, _} = cast(input, %Schema{type: type})
          :invalid -> assert {:error, _} = cast(input, %Schema{type: type})
        end
      end
    end

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

    test "object with nil schema properties, and unknown input property" do
      schema = %Schema{type: :object}
      assert cast(%{}, schema) == {:ok, %{}}
      assert cast(%{"unknown" => "hello"}, schema) == {:ok, %{"unknown" => "hello"}}
    end

    test "object with schema properties set, given unknown input property" do
      schema = %Schema{type: :object, properties: %{}}
      assert cast(%{}, schema) == {:ok, %{}}
      assert {:error, error} = cast(%{"unknown" => "hello"}, schema)
      assert %Error{} = error
    end

    test "object with schema properties set, given known input property" do
      schema = %Schema{
        type: :object,
        properties: %{age: nil}
      }

      assert cast(%{}, schema) == {:ok, %{}}
      assert cast(%{"age" => "hello"}, schema) == {:ok, %{age: "hello"}}
    end
  end
end
