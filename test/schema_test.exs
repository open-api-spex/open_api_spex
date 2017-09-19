defmodule OpenApiSpex.SchemaTest do
  use ExUnit.Case
  alias OpenApiSpex.Schema
  alias OpenApiSpexTest.ApiSpec

  test "cast request schema" do
    api_spec = ApiSpec.spec()
    schemas = api_spec.components.schemas
    user_request_schema = schemas["UserRequest"]

    input = %{
      "user" => %{
        "id" => 123,
        "name" => "asdf",
        "email" => "foo@bar.com",
        "updated_at" => "2017-09-12T14:44:55Z"
      }
    }

    {:ok, output} = Schema.cast(user_request_schema, input, schemas)

    assert output == %OpenApiSpexTest.Schemas.UserRequest{
      user: %OpenApiSpexTest.Schemas.User{
        id: 123,
        name: "asdf",
        email: "foo@bar.com",
        updated_at: DateTime.from_naive!(~N[2017-09-12T14:44:55], "Etc/UTC")
      }
    }
  end

  def assert_example_matches_schema(schema_module) do
    alias OpenApiSpex.{Schema, SchemaResolver}
    {reference, schemas} = SchemaResolver.resolve_schema_modules_from_schema(schema_module, %{})
    schema = Schema.resolve_schema(reference, schemas)
    assert {:ok, data} = Schema.cast(schema, schema.example, schemas)
    assert :ok = Schema.validate(schema, data, schemas)
  end

  test "User Schema example matches schema" do
    assert_example_matches_schema(OpenApiSpexTest.Schemas.User)
    assert_example_matches_schema(OpenApiSpexTest.Schemas.UserRequest)
    assert_example_matches_schema(OpenApiSpexTest.Schemas.UserResponse)
    assert_example_matches_schema(OpenApiSpexTest.Schemas.UsersResponse)
  end
end