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

    test "defaults to type-appropriate value for :integer" do
      assert Schema.example(%Schema{type: :integer}) == 0
    end

    test "defaults to type-appropriate value for :number" do
      assert Schema.example(%Schema{type: :number}) == 0
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
  end
end
