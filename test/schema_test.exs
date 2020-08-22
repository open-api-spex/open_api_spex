defmodule OpenApiSpex.SchemaTest do
  use ExUnit.Case
  alias OpenApiSpex.Schema
  alias OpenApiSpexTest.{ApiSpec, Schemas}
  import OpenApiSpex.TestAssertions

  doctest Schema

  describe "schema/1" do
    test "EntityWithDict Schema example matches schema" do
      api_spec = ApiSpec.spec()
      assert_schema(Schemas.EntityWithDict.schema().example, "EntityWithDict", api_spec)
    end

    test "User Schema example matches schema" do
      spec = ApiSpec.spec()

      assert_schema(Schemas.User.schema().example, "User", spec)
      assert_schema(Schemas.UserRequest.schema().example, "UserRequest", spec)
      assert_schema(Schemas.UserResponse.schema().example, "UserResponse", spec)
      assert_schema(Schemas.UsersResponse.schema().example, "UsersResponse", spec)
    end

    test "Array Schema example matches schema" do
      api_spec = ApiSpec.spec()
      assert_schema(Schemas.Array.schema().example, "Array", api_spec)
    end

    test "Primitive Schema example matches schema" do
      api_spec = ApiSpec.spec()
      assert_schema(Schemas.Primitive.schema().example, "Primitive", api_spec)
    end
  end

  describe "schema/1 auto-populates title" do
    defmodule Name do
      require OpenApiSpex

      OpenApiSpex.schema(%{
        type: :string
      })
    end

    defmodule Age do
      require OpenApiSpex

      OpenApiSpex.schema(%{
        title: "CustomAge",
        type: :integer
      })
    end

    test "autopopulated title" do
      assert Name.schema().title == "Name"
    end

    test "custome title" do
      assert Age.schema().title == "CustomAge"
    end
  end

  describe "example/1" do
    test "uses value in `example` property when not nil" do
      assert Schema.example(%Schema{type: :string, example: "foo"}) == "foo"
    end

    test "defaults to type-appropriate value for :string" do
      assert Schema.example(%Schema{type: :string}) == ""
    end

    test "defaults to type-appropriate value for :integer, :number" do
      assert Schema.example(%Schema{type: :integer}) == 0
      assert Schema.example(%Schema{type: :number}) == 0
    end

    test "defaults to type-appropriate value for :number with :float or :double format" do
      assert Schema.example(%Schema{type: :number, format: :float}) == 0.0
      assert Schema.example(%Schema{type: :number, format: :double}) == 0.0
    end

    test "uses :minimum for :integer, :number" do
      assert Schema.example(%Schema{type: :integer, minimum: 10}) == 10
      assert Schema.example(%Schema{type: :number, minimum: 10}) == 10
    end

    test "obeys exclusiveMinimum for :integer, :number" do
      assert Schema.example(%Schema{type: :integer, minimum: 10, exclusiveMinimum: true}) == 11
      assert Schema.example(%Schema{type: :number, minimum: 10, exclusiveMinimum: true}) == 11
    end

    test "uses :maximum for :integer, :number" do
      assert Schema.example(%Schema{type: :integer, maximum: 10}) == 10
      assert Schema.example(%Schema{type: :number, maximum: 10}) == 10
    end

    test "obeys exclusiveMaximum for numbers" do
      assert Schema.example(%Schema{type: :integer, maximum: 10, exclusiveMaximum: true}) == 9
      assert Schema.example(%Schema{type: :number, maximum: 10, exclusiveMaximum: true}) == 9
    end

    test "defaults to type-appropriate value for :boolean" do
      assert Schema.example(%Schema{type: :boolean}) == false
    end

    test "reaches into object properties" do
      schema = %Schema{
        type: :object,
        properties: %{
          name: %Schema{type: :string, example: "Sample"}
        }
      }

      assert Schema.example(schema) == %{name: "Sample"}
    end

    test "reaches into nested object properties" do
      schema = %Schema{
        type: :object,
        properties: %{
          child: %Schema{
            type: :object,
            properties: %{
              name: %Schema{type: :string, example: "Sample"},
              other: %Schema{type: :string}
            }
          }
        }
      }

      assert Schema.example(schema) == %{
               child: %{
                 name: "Sample",
                 other: ""
               }
             }
    end

    test "example for array" do
      schema = %Schema{
        type: :array,
        items: %Schema{type: :string, example: "Sample"}
      }

      assert Schema.example(schema) == ["Sample"]
    end

    test "example of allOf schema" do
      schema = %Schema{
        allOf: [
          %Schema{type: :object, properties: %{name: %Schema{type: :string, example: "OAS"}}},
          %Schema{type: :object, properties: %{version: %Schema{type: :integer, example: 3}}}
        ]
      }

      assert Schema.example(schema) == %{name: "OAS", version: 3}
    end

    test "example for oneOf schema" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :string, example: "one"},
          %Schema{type: :string, example: "two"}
        ]
      }

      assert Schema.example(schema) == "one"
    end

    test "example for enum" do
      schema = %Schema{type: :string, enum: ["one", "two"]}
      assert Schema.example(schema) == "one"
    end

    test "string :date format" do
      schema = %Schema{type: :string, format: :date}
      assert Schema.example(schema) == "2020-04-20"
    end

    test "string :date-time format" do
      schema = %Schema{type: :string, format: :"date-time"}
      assert Schema.example(schema) == "2020-04-20T16:20:00Z"
    end
  end
end
