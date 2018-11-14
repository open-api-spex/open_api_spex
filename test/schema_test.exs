defmodule OpenApiSpex.SchemaTest do
  use ExUnit.Case
  alias OpenApiSpex.Schema
  alias OpenApiSpexTest.{ApiSpec, Schemas}
  import OpenApiSpex.Test.Assertions

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
  end
end
