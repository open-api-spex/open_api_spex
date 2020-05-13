defmodule OpenApiSpex.CastOneOfTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, Schema}
  alias OpenApiSpex.Cast.{Error, OneOf}
  alias OpenApiSpex.TestAssertions

  defp cast(ctx), do: OneOf.cast(struct(Cast, ctx))

  describe "cast/1" do
    test "oneOf" do
      schema = %Schema{oneOf: [%Schema{type: :integer}, %Schema{type: :string}]}
      assert {:ok, "hello"} = cast(value: "hello", schema: schema)
    end

    test "oneOf, more than one matching schema" do
      schema = %Schema{oneOf: [%Schema{type: :integer}, %Schema{type: :string}]}
      assert {:error, [error]} = cast(value: "1", schema: schema)
      assert error.reason == :one_of

      assert Error.message(error) ==
               "Failed to cast value to one of: Schema(type: :string), Schema(type: :integer)"
    end

    test "oneOf, no castable schema" do
      schema = %Schema{oneOf: [%Schema{type: :string}]}
      assert {:error, [error]} = cast(value: 1, schema: schema)
      assert error.reason == :one_of

      assert Error.message(error) == "Failed to cast value to one of: [] (no schemas provided)"
    end

    test "objects, using discriminator" do
      dog = %{"bark" => "woof", "pet_type" => "Dog"}
      TestAssertions.assert_schema(dog, "CatOrDog", OpenApiSpexTest.ApiSpec.spec())
    end
  end

  describe "oneOf multiple objects" do
    alias OpenApiSpexTest.{OneOfSchemas, OneOfSchemas.Dog}
    @api_spec OneOfSchemas.spec()
    @cat_or_dog_schema @api_spec.components.schemas["CatOrDog"]

    test "matches perfectly with one schema" do
      input = %{"bark" => true, "breed" => "Dingo"}

      assert {:ok, %Dog{bark: true, breed: "Dingo"}} =
               OpenApiSpex.cast_value(input, @cat_or_dog_schema, @api_spec)
    end

    test "ignores additional properties" do
      input = %{"bark" => true, "breed" => "Dingo", "age" => 12}

      assert {:ok, %Dog{bark: true, breed: "Dingo"}} =
               OpenApiSpex.cast_value(input, @cat_or_dog_schema, @api_spec)
    end

    test "should be invalid (not valid against any)" do
      input = %{"bark" => true, "meow" => true}
      assert {:error, _} = OpenApiSpex.cast_value(input, @cat_or_dog_schema, @api_spec)
    end

    test "should be invalid (valid against both)" do
      input = %{"bark" => true, "meow" => true, "breed" => "Husky", "age" => 3}
      assert {:error, _} = OpenApiSpex.cast_value(input, @cat_or_dog_schema, @api_spec)
    end
  end
end
