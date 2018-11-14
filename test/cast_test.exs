defmodule OpenApiSpex.CastTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, Schema}
  alias OpenApiSpexTest.{ApiSpec, Schemas}

  describe "Cast nil" do
    test "to nullable type" do
      assert {:ok, nil} = Cast.cast(%Schema{nullable: true}, nil, %{})
      assert {:ok, nil} = Cast.cast(%Schema{type: :integer, nullable: true}, nil, %{})
      assert {:ok, nil} = Cast.cast(%Schema{type: :string, nullable: true}, nil, %{})
    end

    test "to non-nullable type" do
      assert {:error, "Invalid string: nil"} = Cast.cast(%Schema{type: :string}, nil, %{})
      assert {:error, "Invalid integer: nil"} = Cast.cast(%Schema{type: :integer}, nil, %{})
      assert {:error, "Invalid object: nil"} = Cast.cast(%Schema{type: :object}, nil, %{})
    end
  end

  describe "Cast boolean" do
    test "from boolean" do
      assert {:ok, true} = Cast.cast(%Schema{type: :boolean}, true, %{})
      assert {:ok, false} = Cast.cast(%Schema{type: :boolean}, false, %{})
    end

    test "from string" do
      assert {:ok, true} = Cast.cast(%Schema{type: :boolean}, "true", %{})
      assert {:ok, false} = Cast.cast(%Schema{type: :boolean}, "false", %{})
    end

    test "from invalid data type" do
      assert {:error, "Invalid boolean: \"not a bool\""} =
               Cast.cast(%Schema{type: :boolean}, "not a bool", %{})

      assert {:error, "Invalid boolean: 1"} = Cast.cast(%Schema{type: :boolean}, 1, %{})
      assert {:error, "Invalid boolean: nil"} = Cast.cast(%Schema{type: :boolean}, nil, %{})
      assert {:error, "Invalid boolean: [true]"} = Cast.cast(%Schema{type: :boolean}, [true], %{})
    end
  end

  describe "Cast integer" do
    test "from integer" do
      assert {:ok, -1} = Cast.cast(%Schema{type: :integer}, -1, %{})
      assert {:ok, 0} = Cast.cast(%Schema{type: :integer}, 0, %{})
      assert {:ok, 1} = Cast.cast(%Schema{type: :integer}, 1, %{})
      assert {:ok, 12345} = Cast.cast(%Schema{type: :integer}, 12345, %{})
    end

    test "from string" do
      assert {:ok, -1} = Cast.cast(%Schema{type: :integer}, "-1", %{})
      assert {:ok, 0} = Cast.cast(%Schema{type: :integer}, "0", %{})
      assert {:ok, 1} = Cast.cast(%Schema{type: :integer}, "1", %{})
      assert {:ok, 12345} = Cast.cast(%Schema{type: :integer}, "12345", %{})

      assert {:error, "Invalid integer: \"not an int\""} =
               Cast.cast(%Schema{type: :integer}, "not an int", %{})

      assert {:error, "Invalid integer: \"3.14159\""} =
               Cast.cast(%Schema{type: :integer}, "3.14159", %{})

      assert {:error, "Invalid integer: \"\""} = Cast.cast(%Schema{type: :integer}, "", %{})
    end

    test "from invalid data type" do
      assert {:error, "Invalid integer: true"} = Cast.cast(%Schema{type: :integer}, true, %{})

      assert {:error, "Invalid integer: 3.14159"} =
               Cast.cast(%Schema{type: :integer}, 3.14159, %{})

      assert {:error, "Invalid integer: nil"} = Cast.cast(%Schema{type: :integer}, nil, %{})
      assert {:error, "Invalid integer: [1, 2]"} = Cast.cast(%Schema{type: :integer}, [1, 2], %{})
    end
  end

  describe "Cast number" do
    test "from number" do
      assert {:ok, -1.0} = Cast.cast(%Schema{type: :number, format: :float}, -1, %{})
      assert {:ok, -1.0} = Cast.cast(%Schema{type: :number, format: :double}, -1, %{})
      assert {:ok, -1} = Cast.cast(%Schema{type: :number}, -1, %{})
      assert {:ok, 0.0} = Cast.cast(%Schema{type: :number}, 0.0, %{})
      assert {:ok, 1.0} = Cast.cast(%Schema{type: :number}, 1.0, %{})
      assert {:ok, 123.45} = Cast.cast(%Schema{type: :number}, 123.45, %{})
    end

    test "from string" do
      assert {:ok, -1.0} = Cast.cast(%Schema{type: :number}, "-1", %{})
      assert {:ok, 0.0} = Cast.cast(%Schema{type: :number}, "0.0", %{})
      assert {:ok, 1.0} = Cast.cast(%Schema{type: :number}, "1.0", %{})
      assert {:ok, 123.45} = Cast.cast(%Schema{type: :number}, "123.45", %{})
    end

    test "from invalid data type" do
      assert {:error, "Invalid number: nil"} = Cast.cast(%Schema{type: :number}, nil, %{})
      assert {:error, "Invalid number: false"} = Cast.cast(%Schema{type: :number}, false, %{})
      assert {:error, "Invalid number: \"\""} = Cast.cast(%Schema{type: :number}, "", %{})

      assert {:error, "Invalid number: \"not a number\""} =
               Cast.cast(%Schema{type: :number}, "not a number", %{})

      assert {:error, "Invalid number: []"} = Cast.cast(%Schema{type: :number}, [], %{})

      assert {:error, "Invalid number: [1.0, 2.0]"} =
               Cast.cast(%Schema{type: :number}, [1.0, 2.0], %{})
    end
  end

  describe "cast string" do
    test "from string" do
      assert {:ok, ""} = Cast.cast(%Schema{type: :string}, "", %{})
      assert {:ok, "  "} = Cast.cast(%Schema{type: :string}, "  ", %{})
      assert {:ok, "hello"} = Cast.cast(%Schema{type: :string}, "hello", %{})
    end

    test "from invalid data type" do
      assert {:error, "Invalid string: nil"} = Cast.cast(%Schema{type: :string}, nil, %{})
      assert {:error, "Invalid string: []"} = Cast.cast(%Schema{type: :string}, [], %{})

      assert {:error, "Invalid string: :an_atom"} =
               Cast.cast(%Schema{type: :string}, :an_atom, %{})

      assert {:error, "Invalid string: 0"} = Cast.cast(%Schema{type: :string}, 0, %{})
    end
  end

  describe "cast array" do
    test "from list" do
      assert {:ok, []} = Cast.cast(%Schema{type: :array}, [], %{})
      assert {:ok, [1, 2, 3]} = Cast.cast(%Schema{type: :array}, [1, 2, 3], %{})
      assert {:ok, [1, "a", true]} = Cast.cast(%Schema{type: :array}, [1, "a", true], %{})

      int_array = %Schema{type: :array, items: %Schema{type: :integer}}
      assert {:ok, [1, 2, 3]} = Cast.cast(int_array, [1, 2, 3], %{})
      assert {:ok, [1, 2, 3]} = Cast.cast(int_array, ["1", "2", "3"], %{})
    end

    test "from invalid data type" do
      assert {:error, "Invalid array: nil"} = Cast.cast(%Schema{type: :array}, nil, %{})
      assert {:error, "Invalid array: 0"} = Cast.cast(%Schema{type: :array}, 0, %{})
      assert {:error, "Invalid array: \"\""} = Cast.cast(%Schema{type: :array}, "", %{})
      assert {:error, "Invalid array: \"1,2,3\""} = Cast.cast(%Schema{type: :array}, "1,2,3", %{})
    end

    test "from list with invalid item type" do
      string_array = %Schema{type: :array, items: %Schema{type: :string}}
      assert {:error, "Invalid string: 1"} = Cast.cast(string_array, [1, 2, 3], %{})
    end
  end

  describe "Cast object" do
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

      {:ok, output} = Cast.cast(user_request_schema, input, schemas)

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

      {:error, "Invalid object: []"} = Cast.cast(user_request_schema, input, schemas)
    end

    test "cast/3 with unexpected type for nested object" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      user_request_schema = schemas["UserRequest"]

      input = %{
        "user" => []
      }

      {:error, "Invalid object: []"} = Cast.cast(user_request_schema, input, schemas)
    end

    test "cast/3 with unexpected type for nested array" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      user_response_schema = schemas["UsersResponse"]

      input = %{
        "data" => %{}
      }

      {:error, "Invalid array: %{}"} = Cast.cast(user_response_schema, input, schemas)
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

      assert {:error, "Unexpected field with value \"unexpected value\""} =
               Cast.cast(user_request_schema, input, schemas)
    end
  end

  describe "Polymorphic cast" do
    test "Cast Cat from Pet schema" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      pet_schema = schemas["Pet"]

      input = %{
        "pet_type" => "Cat",
        "meow" => "meow"
      }

      assert {:ok, %Schemas.Cat{meow: "meow", pet_type: "Cat"}} =
               Cast.cast(pet_schema, input, schemas)
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
               Cast.cast(cat_or_dog, input, schemas)
    end

    test "Cast number to string or number" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :number},
          %Schema{type: :string}
        ]
      }

      result = Cast.cast(schema, "123", %{})

      assert {:ok, 123.0} = result
    end

    test "Cast string to oneOf number or datetime" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :number},
          %Schema{type: :string, format: :"date-time"}
        ]
      }

      assert {:ok, %DateTime{}} = Cast.cast(schema, "2018-04-01T12:34:56Z", %{})
    end

    test "Cast string to anyOf number or datetime" do
      schema = %Schema{
        anyOf: [
          %Schema{type: :number},
          %Schema{type: :string, format: :"date-time"}
        ]
      }

      assert {:ok, %DateTime{}} = Cast.cast(schema, "2018-04-01T12:34:56Z", %{})
    end
  end
end
