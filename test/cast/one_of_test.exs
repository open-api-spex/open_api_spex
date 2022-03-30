defmodule OpenApiSpex.CastOneOfTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, Reference, Schema}
  alias OpenApiSpex.Cast.{Error, OneOf}
  alias OpenApiSpex.TestAssertions
  alias OpenApiSpexTest.Schemas

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
               "Failed to cast value to one of: more than one schemas validate"
    end

    test "oneOf, more than one matching schema with failing schema" do
      schema = %Schema{
        oneOf: [%Schema{type: :integer}, %Schema{type: :string}, %Schema{type: :bool}]
      }

      assert {:error, [error]} = cast(value: "1", schema: schema)
      assert error.reason == :one_of

      assert Error.message(error) ==
               "Failed to cast value to one of: more than one schemas validate"
    end

    test "oneOf, no castable schema" do
      schema = %Schema{oneOf: [%Schema{type: :string}]}
      assert {:error, [error]} = cast(value: 1, schema: schema)
      assert error.reason == :one_of

      assert Error.message(error) ==
               "Failed to cast value to one of: no schemas validate"
    end

    test "objects, using discriminator" do
      dog = %{"bark" => "woof", "pet_type" => "Dog"}
      TestAssertions.assert_schema(dog, "Pet", OpenApiSpexTest.ApiSpec.spec())
    end

    test "error when value invalid against all schemas, using discriminator" do
      dog = %{"fur" => "grey", "pet_type" => "Wolf"}
      api_spec = OpenApiSpexTest.ApiSpec.spec()
      pet_schema = api_spec.components.schemas["Pet"]
      assert {:error, [error]} = OpenApiSpex.cast_value(dog, pet_schema, api_spec)

      assert error == %OpenApiSpex.Cast.Error{
               format: nil,
               length: 0,
               meta: %{
                 failed_schemas: [
                   "Schema(title: \"Dog\", type: :object)",
                   "Schema(title: \"Cat\", type: :object)"
                 ],
                 message: "no schemas validate",
                 valid_schemas: []
               },
               name: nil,
               path: ["pet_type"],
               reason: :one_of,
               type: nil,
               value: %{"fur" => "grey", "pet_type" => "Wolf"}
             }
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

    test "invalid when value is valid against more than one child schemas" do
      input = %{"bark" => true, "meow" => true}
      assert {:error, [error]} = OpenApiSpex.cast_value(input, @cat_or_dog_schema, @api_spec)

      assert error == %OpenApiSpex.Cast.Error{
               format: nil,
               length: 0,
               meta: %{
                 failed_schemas: [],
                 message: "more than one schemas validate",
                 valid_schemas: [
                   "Schema(title: \"Dog\", type: :object)",
                   "Schema(title: \"Cat\", type: :object)"
                 ]
               },
               name: nil,
               path: [],
               reason: :one_of,
               type: nil,
               value: %{"bark" => true, "meow" => true}
             }

      assert to_string(error) == "Failed to cast value to one of: more than one schemas validate"
    end
  end

  test "oneOf, when given required params only from inside the oneOf schema, return an error" do
    schema = %Schema{
      oneOf: [
        %Reference{
          "$ref": "#/components/schemas/User"
        }
      ],
      required: [:age]
    }

    value = %{
      "name" => "Joe User",
      "email" => "joe@gmail.com",
      "password" => "12345678"
    }

    assert {:error, [oneOf]} =
             OpenApiSpex.Cast.OneOf.cast(
               struct(OpenApiSpex.Cast,
                 value: value,
                 schema: schema,
                 schemas: %{"User" => Schemas.User.schema()}
               )
             )

    assert Error.message(oneOf) ==
             "Failed to cast value to one of: no schemas validate"
  end

  test "allOf, when given all required params inside and outside the allOf, return the schema" do
    schema = %Schema{
      allOf: [
        %Reference{
          "$ref": "#/components/schemas/User"
        }
      ],
      required: [:age]
    }

    value = %{
      "name" => "Joe User",
      "email" => "joe@gmail.com",
      "password" => "12345678",
      "age" => "123"
    }

    assert {:ok,
            %{
              age: 123,
              email: "joe@gmail.com",
              name: "Joe User",
              password: "12345678"
            }} =
             OpenApiSpex.Cast.AllOf.cast(
               struct(OpenApiSpex.Cast,
                 value: value,
                 schema: schema,
                 schemas: %{"User" => Schemas.User.schema()}
               )
             )
  end

  test "oneOf with required fields" do
    schema = %Schema{
      oneOf: [
        %Schema{
          type: :object,
          properties: %{
            last_name: %Schema{type: :string}
          },
          required: [:last_name]
        }
      ]
    }

    assert {:error, [error_one_of]} =
             OpenApiSpex.Cast.OneOf.cast(struct(OpenApiSpex.Cast, value: %{}, schema: schema))

    assert Error.message(error_one_of) ==
             "Failed to cast value to one of: no schemas validate"
  end
end
