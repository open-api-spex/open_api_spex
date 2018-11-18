defmodule OpenApiSpex.CastObjectTest do
  use ExUnit.Case
  import OpenApiSpex.CastObject
  alias OpenApiSpex.{Error, Schema}

  describe "cast/3" do
    test "properties:nil, given unknown input property" do
      schema = %Schema{type: :object}
      assert cast(%{}, schema) == {:ok, %{}}
      assert cast(%{"unknown" => "hello"}, schema) == {:ok, %{"unknown" => "hello"}}
    end

    test "with empty schema properties, given unknown input property" do
      schema = %Schema{type: :object, properties: %{}}
      assert cast(%{}, schema) == {:ok, %{}}
      assert {:error, error} = cast(%{"unknown" => "hello"}, schema)
      assert %Error{} = error
    end

    test "with schema properties set, given known input property" do
      schema = %Schema{
        type: :object,
        properties: %{age: nil}
      }

      assert cast(%{}, schema) == {:ok, %{}}
      assert cast(%{"age" => "hello"}, schema) == {:ok, %{age: "hello"}}
    end

    test "required fields" do
      schema = %Schema{
        type: :object,
        properties: %{age: nil},
        required: [:age]
      }

      assert {:error, error} = cast(%{}, schema)
      assert %Error{} = error
      assert error.reason == :missing_field
      assert error.name == :age
    end
  end
end
