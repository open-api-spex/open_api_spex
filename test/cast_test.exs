defmodule OpenApiSpec.CastTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, CastContext, Error, Schema}

  def cast(ctx), do: Cast.cast(struct(CastContext, ctx))

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
          :ok -> assert {:ok, _} = cast(value: input, schema: %Schema{type: type})
          :invalid -> assert {:error, _} = cast(value: input, schema: %Schema{type: type})
        end
      end
    end

    test "array" do
      schema = %Schema{type: :array}
      assert cast(value: [], schema: schema) == {:ok, []}
      assert cast(value: [1, 2, 3], schema: schema) == {:ok, [1, 2, 3]}
      assert cast(value: ["1", "2", "3"], schema: schema) == {:ok, ["1", "2", "3"]}

      assert {:error, error} = cast(value: %{}, schema: schema)
      assert %Error{} = error
      assert error.reason == :invalid_type
      assert error.value == %{}
    end

    test "array with items schema" do
      items_schema = %Schema{type: :integer}
      schema = %Schema{type: :array, items: items_schema}
      assert cast(value: [], schema: schema) == {:ok, []}
      assert cast(value: [1, 2, 3], schema: schema) == {:ok, [1, 2, 3]}
      assert cast(value: ["1", "2", "3"], schema: schema) == {:ok, [1, 2, 3]}

      assert {:error, error} = cast(value: [1, "two"], schema: schema)
      assert %Error{} = error
      assert error.reason == :invalid_type
      assert error.value == "two"
      assert error.path == [1]
    end

    # Additional object tests found in CastObjectTest
    test "object with schema properties set, given known input property" do
      schema = %Schema{
        type: :object,
        properties: %{age: nil}
      }

      assert cast(value: %{}, schema: schema) == {:ok, %{}}
      assert cast(value: %{"age" => "hello"}, schema: schema) == {:ok, %{age: "hello"}}
    end
  end
end
