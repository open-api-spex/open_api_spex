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

    assert output == %{
      user: %{
        id: 123,
        name: "asdf",
        email: "foo@bar.com",
        updated_at: DateTime.from_naive!(~N[2017-09-12T14:44:55], "Etc/UTC")
      }
    }
  end
end