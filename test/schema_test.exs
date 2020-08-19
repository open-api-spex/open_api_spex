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
end
