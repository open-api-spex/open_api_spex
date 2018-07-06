defmodule OpenApiSpex.SchemaTest do
  use ExUnit.Case
  alias OpenApiSpex.Schema
  alias OpenApiSpexTest.{ApiSpec, Schemas}
  import OpenApiSpex.Test.Assertions

  doctest Schema

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

  test "cast request schema with unexpected fields returns error" do
    api_spec = ApiSpec.spec()
    schemas = api_spec.components.schemas
    user_request_schema = schemas["UserRequest"]

    input = %{
      "user" => %{
        "id" => 123,
        "name" => "asdf",
        "email" => "foo@bar.com",
        "updated_at" => "2017-09-12T14:44:55Z",
        "unexpected_field" => "unexpected value"
      }
    }

    assert {:error, _} = Schema.cast(user_request_schema, input, schemas)
  end

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

  test "Cast Cat from Pet schema" do
    api_spec = ApiSpec.spec()
    schemas = api_spec.components.schemas
    pet_schema = schemas["Pet"]

    input = %{
      "pet_type" => "Cat",
      "meow" => "meow"
    }

    assert {:ok, %Schemas.Cat{meow: "meow", pet_type: "Cat"}} = Schema.cast(pet_schema, input, schemas)
  end

  test "Cast Dog from oneOf [cat, dog] schema" do
    api_spec = ApiSpec.spec()
    schemas = api_spec.components.schemas
    cat_or_dog = Map.fetch!(schemas, "CatOrDog")

    input = %{
      "pet_type" => "Cat",
      "meow" => "meow"
    }

    assert {:ok, %Schemas.Cat{meow: "meow", pet_type: "Cat"}} = Schema.cast(cat_or_dog, input, schemas)
  end

  test "Cast number to string or number" do
    schema = %Schema{
      oneOf: [
        %Schema{type: :number},
        %Schema{type: :string}
      ]
    }

    result = Schema.cast(schema, "123", %{})

    assert {:ok, 123.0} = result
  end

  test "Cast string to oneOf number or datetime" do
    schema = %Schema{
      oneOf: [
        %Schema{type: :number},
        %Schema{type: :string, format: :"date-time"}
      ]
    }
    assert {:ok, %DateTime{}} = Schema.cast(schema, "2018-04-01T12:34:56Z", %{})
  end

  test "Cast string to anyOf number or datetime" do
    schema = %Schema{
      oneOf: [
        %Schema{type: :number},
        %Schema{type: :string, format: :"date-time"}
      ]
    }
    assert {:ok, %DateTime{}} = Schema.cast(schema, "2018-04-01T12:34:56Z", %{})
  end
end
