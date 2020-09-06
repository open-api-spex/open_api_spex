defmodule OpenApiSpex.Cast.EnumTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, Schema}
  alias OpenApiSpex.Cast.Error

  defp cast(ctx), do: Cast.cast(ctx)

  defmodule User do
    require OpenApiSpex
    alias __MODULE__

    defstruct [:age]

    def schema() do
      %OpenApiSpex.Schema{
        type: :object,
        required: [:age],
        properties: %{
          age: %Schema{type: :integer}
        },
        enum: [%User{age: 32}, %User{age: 45}],
        "x-struct": __MODULE__
      }
    end
  end

  describe "Enum of strings" do
    setup do
      {:ok, %{schema: %Schema{type: :string, enum: ["one"]}}}
    end

    test "error on invalid string", %{schema: schema} do
      assert {:error, [error]} = cast(schema: schema, value: "two")
      assert %Error{} = error
      assert error.reason == :invalid_enum
    end

    test "OK on valid string", %{schema: schema} do
      assert {:ok, "one"} = cast(schema: schema, value: "one")
    end
  end

  describe "Enum of atoms" do
    setup do
      {:ok, %{schema: %Schema{type: :string, enum: [:one, :two, :three]}}}
    end

    test "string will be converted to atom", %{schema: schema} do
      assert {:ok, :three} = cast(schema: schema, value: "three")
    end

    test "error on invalid string", %{schema: schema} do
      assert {:error, [error]} = cast(schema: schema, value: "four")
      assert %Error{} = error
      assert error.reason == :invalid_enum
    end
  end

  describe "Enum with explicit schema" do
    test "converts string keyed map to struct" do
      assert {:ok, %User{age: 32}} = cast(schema: User.schema(), value: %{"age" => 32})
    end

    test "Must be a valid enum value" do
      assert {:error, [error]} = cast(schema: User.schema(), value: %{"age" => 33})
      assert %Error{} = error
      assert error.reason == :invalid_enum
    end
  end

  describe "Enum without explicit schema" do
    setup do
      schema = %Schema{
        type: :object,
        enum: [%{age: 55}, %{age: 66}, %{age: 77}]
      }

      {:ok, %{schema: schema}}
    end

    test "casts from string keyed map", %{schema: schema} do
      assert {:ok, %{age: 55}} = cast(value: %{"age" => 55}, schema: schema)
    end

    test "value must be a valid enum value", %{schema: schema} do
      assert {:error, [error]} = cast(value: %{"age" => 56}, schema: schema)
      assert %Error{} = error
      assert error.reason == :invalid_enum
    end
  end
end
