defmodule OpenApiSpex.ObjectTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, Schema}
  alias OpenApiSpex.Cast.{Object, Error}

  defp cast(ctx), do: Object.cast(struct(Cast, ctx))

  describe "cast/3" do
    test "not an object" do
      schema = %Schema{type: :object}
      assert {:error, [error]} = cast(value: ["hello"], schema: schema)
      assert %Error{} = error
      assert error.reason == :invalid_type
      assert error.value == ["hello"]
    end

    test "properties:nil, given unknown input property" do
      schema = %Schema{type: :object}
      assert cast(value: %{}, schema: schema) == {:ok, %{}}

      assert cast(value: %{"unknown" => "hello"}, schema: schema) ==
               {:ok, %{"unknown" => "hello"}}
    end

    test "with empty schema properties, given unknown input property" do
      schema = %Schema{type: :object, properties: %{}}
      assert cast(value: %{}, schema: schema) == {:ok, %{}}
      assert {:error, [error]} = cast(value: %{"unknown" => "hello"}, schema: schema)
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
        properties: %{age: nil, name: nil},
        required: [:age, :name]
      }

      assert {:error, [error, error2]} = cast(value: %{}, schema: schema)
      assert %Error{} = error
      assert error.reason == :missing_field
      assert error.name == :age
      assert error.path == [:age]

      assert error2.reason == :missing_field
      assert error2.name == :name
      assert error2.path == [:name]
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

    defmodule User do
      defstruct [:name]
    end

    test "optionally casts to struct" do
      schema = %Schema{
        type: :object,
        "x-struct": User,
        properties: %{
          name: %Schema{type: :string}
        }
      }

      assert {:ok, user} = cast(value: %{"name" => "Name"}, schema: schema)
      assert user == %User{name: "Name"}
    end
  end
end
