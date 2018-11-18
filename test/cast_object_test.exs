defmodule OpenApiSpex.CastObjectTest do
  use ExUnit.Case
  alias OpenApiSpex.{CastContext, CastObject, Error, Schema}

  defp cast(ctx), do: CastObject.cast(struct(CastContext, ctx))

  describe "cast/3" do
    test "properties:nil, given unknown input property" do
      schema = %Schema{type: :object}
      assert cast(value: %{}, schema: schema) == {:ok, %{}}

      assert cast(value: %{"unknown" => "hello"}, schema: schema) ==
               {:ok, %{"unknown" => "hello"}}
    end

    test "with empty schema properties, given unknown input property" do
      schema = %Schema{type: :object, properties: %{}}
      assert cast(value: %{}, schema: schema) == {:ok, %{}}
      assert {:error, error} = cast(value: %{"unknown" => "hello"}, schema: schema)
      assert %Error{} = error
    end

    test "with schema properties set, given known input property" do
      schema = %Schema{
        type: :object,
        properties: %{age: nil}
      }

      assert cast(value: %{}, schema: schema) == {:ok, %{}}
      assert cast(value: %{"age" => "hello"}, schema: schema) == {:ok, %{age: "hello"}}
    end

    test "required fields" do
      schema = %Schema{
        type: :object,
        properties: %{age: nil},
        required: [:age]
      }

      assert {:error, error} = cast(value: %{}, schema: schema)
      assert %Error{} = error
      assert error.reason == :missing_field
      assert error.name == :age
    end

    test "cast property against schema" do
      schema = %Schema{
        type: :object,
        properties: %{age: %Schema{type: :integer}}
      }

      assert cast(value: %{}, schema: schema) == {:ok, %{}}
      assert {:error, [error]} = cast(value: %{"age" => "hello"}, schema: schema)
      assert %Error{} = error
      assert error.reason == :invalid_type
      assert error.path == [:age]
    end
  end
end
