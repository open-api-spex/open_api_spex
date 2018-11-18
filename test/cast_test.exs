defmodule OpenApiSpec.CastTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, CastContext, Error, Reference, Schema}

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

    test "reference" do
      age_schema = %Schema{type: :integer}

      assert cast(
               value: "20",
               schema: %Reference{"$ref": "#/components/schemas/Age"},
               schemas: %{"Age" => age_schema}
             ) == {:ok, 20}
    end

    test "reference nested in object" do
      age_schema = %Schema{type: :integer}

      schema = %Schema{
        type: :object,
        properties: %{
          age: %Reference{"$ref": "#/components/schemas/Age"}
        }
      }

      assert cast(
               value: %{"age" => "20"},
               schema: schema,
               schemas: %{"Age" => age_schema}
             ) == {:ok, %{age: 20}}
    end

    test "paths" do
      schema = %Schema{
        type: :object,
        properties: %{
          age: %Schema{type: :integer}
        }
      }

      assert {:error, error} = cast(value: %{"age" => "twenty"}, schema: schema)
      assert %Error{} = error
      assert error.path == [:age]
    end

    test "nested paths" do
      schema = %Schema{
        type: :object,
        properties: %{
          data: %Schema{
            type: :object,
            properties: %{
              age: %Schema{type: :integer}
            }
          }
        }
      }

      assert {:error, error} = cast(value: %{"data" => %{"age" => "twenty"}}, schema: schema)
      assert %Error{} = error
      assert error.path == [:data, :age]
    end

    test "paths involving arrays" do
      schema = %Schema{
        type: :object,
        properties: %{
          data: %Schema{
            type: :array,
            items: %Schema{
              type: :object,
              properties: %{
                age: %Schema{type: :integer}
              }
            }
          }
        }
      }

      assert {:error, error} =
               cast(value: %{"data" => [%{"age" => "20"}, %{"age" => "twenty"}]}, schema: schema)

      assert %Error{} = error
      assert error.path == [:data, 1, :age]
    end
  end
end
