defmodule OpenApiSpex.CastTest do
  use ExUnit.Case
  alias OpenApiSpex.{Schema, Cast}
  alias OpenApiSpexTest.{ApiSpec, Schemas}

  describe "cast/3 from nil" do
    test "to nullable type" do
      assert {:ok, nil} = Cast.cast(nil, %Schema{nullable: true})
      assert {:ok, nil} = Cast.cast(nil, %Schema{type: :integer, nullable: true})
      assert {:ok, nil} = Cast.cast(nil, %Schema{type: :string, nullable: true})
    end

    test "to non-nullable type" do
      assert {:error, _} = Cast.cast(nil, %Schema {type: :string})
      assert {:error, _} = Cast.cast(nil, %Schema {type: :integer})
      assert {:error, _} = Cast.cast(nil, %Schema {type: :object})
    end
  end

  describe "cast/3 for type: :boolean" do
    test "from boolean" do
      assert {:ok, true} = Cast.cast(true, %Schema{type: :boolean})
      assert {:ok, false} = Cast.cast(false, %Schema{type: :boolean})
    end

    test "from string" do
      assert {:ok, true} = Cast.cast("true", %Schema{type: :boolean})
      assert {:ok, false} = Cast.cast("false", %Schema{type: :boolean})
    end

    test "from invalid data type" do
      assert {:error, _} = Cast.cast("not a bool", %Schema{type: :boolean})
      assert {:error, _} = Cast.cast(1, %Schema{type: :boolean})
      assert {:error, _} = Cast.cast(nil, %Schema{type: :boolean})
      assert {:error, _} = Cast.cast([true], %Schema{type: :boolean})
    end
  end

  describe "cast/3 for type :integer" do
    test "from integer" do
      assert {:ok, -1} = Cast.cast(-1, %Schema{type: :integer})
      assert {:ok, 0} = Cast.cast(0, %Schema{type: :integer})
      assert {:ok, 1} = Cast.cast(1, %Schema{type: :integer})
      assert {:ok, 12345} = Cast.cast(12345, %Schema{type: :integer})
    end

    test "from string" do
      assert {:ok, -1} = Cast.cast("-1", %Schema{type: :integer})
      assert {:ok, 0} = Cast.cast("0", %Schema{type: :integer})
      assert {:ok, 1} = Cast.cast("1", %Schema{type: :integer})
      assert {:ok, 12345} = Cast.cast("12345", %Schema{type: :integer})
      assert {:error, _} = Cast.cast("not an int", %Schema{type: :integer})
      assert {:error, _} = Cast.cast("3.14159", %Schema{type: :integer})
      assert {:error, _} = Cast.cast("", %Schema{type: :integer})
    end

    test "from invalid data type" do
      assert {:error, _} = Cast.cast(true, %Schema{type: :integer})
      assert {:error, _} = Cast.cast(3.14159, %Schema{type: :integer})
      assert {:error, _} = Cast.cast(nil, %Schema{type: :integer})
      assert {:error, _} = Cast.cast([1, 2], %Schema{type: :integer})
    end
  end

  describe "cast/3 for type: :number" do
    test "from number" do
      assert {:ok, -1.0} = Cast.cast(-1, %Schema{type: :number, format: :float})
      assert {:ok, -1.0} = Cast.cast(-1, %Schema{type: :number, format: :double})
      assert {:ok, -1} = Cast.cast(-1, %Schema{type: :number})
      assert {:ok, 0.0} = Cast.cast(0.0, %Schema{type: :number})
      assert {:ok, 1.0} = Cast.cast(1.0, %Schema{type: :number})
      assert {:ok, 123.45} = Cast.cast(123.45, %Schema{type: :number})
    end
    test "from string" do
      assert {:ok, -1.0} = Cast.cast("-1", %Schema{type: :number})
      assert {:ok, 0.0} = Cast.cast("0.0", %Schema{type: :number})
      assert {:ok, 1.0} = Cast.cast("1.0", %Schema{type: :number})
      assert {:ok, 123.45} = Cast.cast("123.45", %Schema{type: :number})
    end
    test "from invalid data type" do
      assert {:error, _} = Cast.cast(nil, %Schema{type: :number})
      assert {:error, _} = Cast.cast(false, %Schema{type: :number})
      assert {:error, _} = Cast.cast("", %Schema{type: :number})
      assert {:error, _} = Cast.cast("not a number", %Schema{type: :number})
      assert {:error, _} = Cast.cast([], %Schema{type: :number})
      assert {:error, _} = Cast.cast([1.0, 2.0], %Schema{type: :number})
    end
  end

  describe "cast/3 for type: :string" do
    test "from string" do
      assert {:ok, ""} = Cast.cast("", %Schema{type: :string})
      assert {:ok, "  "} = Cast.cast("  ", %Schema{type: :string})
      assert {:ok, "hello"} = Cast.cast("hello", %Schema{type: :string})
    end
    test "from invalid data type" do
      assert {:error, _} = Cast.cast(nil, %Schema{type: :string})
      assert {:error, _} = Cast.cast([], %Schema{type: :string})
      assert {:error, _} = Cast.cast(:an_atom, %Schema{type: :string})
      assert {:error, _} = Cast.cast(0, %Schema{type: :string})
    end
    test "format: :date" do
      assert {:error, _} = Cast.cast("2018-01-1", %Schema{type: :string, format: :date})
      assert {:ok, _} = Cast.cast("2018-01-01", %Schema{type: :string, format: :date})
    end
    test "format: :date-time" do
      assert {:error, _} = Cast.cast("2018-01-01T00:00:0Z", %Schema{type: :string, format: :"date-time"})
      assert {:ok, _} = Cast.cast("2018-01-01T00:00:00Z", %Schema{type: :string, format: :"date-time"})
    end
  end

  describe "cast/3 for type: :array" do
    test "from list" do
      assert {:ok, []} = Cast.cast([], %Schema{type: :array})
      assert {:ok, [1, 2, 3]} = Cast.cast([1,2,3], %Schema{type: :array})
      assert {:ok, [1, "a", true]} = Cast.cast([1, "a", true], %Schema{type: :array})

      int_array = %Schema{type: :array, items: %Schema{type: :integer}}
      assert {:ok, [1, 2, 3]} = Cast.cast([1, 2, 3], int_array)
      assert {:ok, [1, 2, 3]} = Cast.cast(["1", "2", "3"], int_array)
    end
    test "from invalid data type" do
      assert {:error, _} = Cast.cast(nil, %Schema{type: :array})
      assert {:error, _} = Cast.cast(0, %Schema{type: :array})
      assert {:error, _} = Cast.cast("", %Schema{type: :array})
      assert {:error, _} = Cast.cast("1,2,3", %Schema{type: :array})
    end
    test "from list with invalid item type" do
      string_array = %Schema{type: :array, items: %Schema{type: :string}}
      assert {:error, _} = Cast.cast([1, 2, 3], string_array)
    end
  end

  describe "cast/3  for type: :object" do
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

      {:ok, output} = Cast.cast(input, user_request_schema, schemas)

      assert output == %OpenApiSpexTest.Schemas.UserRequest{
               user: %OpenApiSpexTest.Schemas.User{
                 id: 123,
                 name: "asdf",
                 email: "foo@bar.com",
                 updated_at: DateTime.from_naive!(~N[2017-09-12T14:44:55], "Etc/UTC")
               }
             }
    end

    test "cast/3 with unexpected type for object" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      user_request_schema = schemas["UserRequest"]

      input = []

      {:error, _output} = Cast.cast(input, user_request_schema, schemas)
    end

    test "cast/3 with unexpected type for nested object" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      user_request_schema = schemas["UserRequest"]

      input = %{
        "user" => []
      }

      {:error, _output} = Cast.cast(input, user_request_schema, schemas)
    end

    test "cast/3 with unexpected type for nested array" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      user_response_schema = schemas["UsersResponse"]

      input = %{
        "data" => %{}
      }

      {:error, _output} = Cast.cast(input, user_response_schema, schemas)
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

      assert {:error, _} = Cast.cast(input, user_request_schema, schemas)
    end
  end

  describe "cast/3 for Polymorphic schema" do
    test "Cast Cat from Pet schema" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      pet_schema = schemas["Pet"]

      input = %{
        "pet_type" => "Cat",
        "meow" => "meow"
      }

      assert {:ok, %Schemas.Cat{meow: "meow", pet_type: "Cat"}} =
               Cast.cast(input, pet_schema, schemas)
    end

    test "Cast Dog from oneOf [cat, dog] schema" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      cat_or_dog = Map.fetch!(schemas, "CatOrDog")

      input = %{
        "pet_type" => "Cat",
        "meow" => "meow"
      }

      assert {:ok, %Schemas.Cat{meow: "meow", pet_type: "Cat"}} =
               Cast.cast(input, cat_or_dog, schemas)
    end

    test "`oneOf` - Cast number to string or number" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :number},
          %Schema{type: :string}
        ]
      }

      result = Cast.cast("123", schema)

      assert {:ok, 123.0} = result
    end

    test "`oneOf` - Cast string to oneOf number or datetime" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :number},
          %Schema{type: :string, format: :"date-time"}
        ]
      }

      assert {:ok, %DateTime{}} = Cast.cast("2018-04-01T12:34:56Z", schema)
    end

    test "`anyOf` - Cast string to anyOf number or datetime" do
      schema = %Schema{
        anyOf: [
          %Schema{type: :number},
          %Schema{type: :string, format: :"date-time"}
        ]
      }

      assert {:ok, %DateTime{}} = Cast.cast("2018-04-01T12:34:56Z", schema)
    end
  end
end
