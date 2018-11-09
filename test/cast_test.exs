defmodule OpenApiSpex.CastTest do
  use ExUnit.Case
  alias OpenApiSpex.Schema
  alias OpenApiSpexTest.{ApiSpec, Schemas}

  describe "cast/3 from nil" do
    test "to nullable type" do
      assert {:ok, nil} = Schema.cast(%Schema{nullable: true}, nil, %{})
      assert {:ok, nil} = Schema.cast(%Schema{type: :integer, nullable: true}, nil, %{})
      assert {:ok, nil} = Schema.cast(%Schema{type: :string, nullable: true}, nil, %{})
    end

    test "to non-nullable type" do
      assert {:error, _} = Schema.cast(%Schema {type: :string}, nil, %{})
      assert {:error, _} = Schema.cast(%Schema {type: :integer}, nil, %{})
      assert {:error, _} = Schema.cast(%Schema {type: :object}, nil, %{})
    end
  end

  describe "cast/3 for type: :boolean" do
    test "from boolean" do
      assert {:ok, true} = Schema.cast(%Schema{type: :boolean}, true, %{})
      assert {:ok, false} = Schema.cast(%Schema{type: :boolean}, false, %{})
    end

    test "from string" do
      assert {:ok, true} = Schema.cast(%Schema{type: :boolean}, "true", %{})
      assert {:ok, false} = Schema.cast(%Schema{type: :boolean}, "false", %{})
    end

    test "from invalid data type" do
      assert {:error, _} = Schema.cast(%Schema{type: :boolean}, "not a bool", %{})
      assert {:error, _} = Schema.cast(%Schema{type: :boolean}, 1, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :boolean}, nil, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :boolean}, [true], %{})
    end
  end

  describe "cast/3 for type :integer" do
    test "from integer" do
      assert {:ok, -1} = Schema.cast(%Schema{type: :integer}, -1, %{})
      assert {:ok, 0} = Schema.cast(%Schema{type: :integer}, 0, %{})
      assert {:ok, 1} = Schema.cast(%Schema{type: :integer}, 1, %{})
      assert {:ok, 12345} = Schema.cast(%Schema{type: :integer}, 12345, %{})
    end

    test "from string" do
      assert {:ok, -1} = Schema.cast(%Schema{type: :integer}, "-1", %{})
      assert {:ok, 0} = Schema.cast(%Schema{type: :integer}, "0", %{})
      assert {:ok, 1} = Schema.cast(%Schema{type: :integer}, "1", %{})
      assert {:ok, 12345} = Schema.cast(%Schema{type: :integer}, "12345", %{})
      assert {:error, _} = Schema.cast(%Schema{type: :integer}, "not an int", %{})
      assert {:error, _} = Schema.cast(%Schema{type: :integer}, "3.14159", %{})
      assert {:error, _} = Schema.cast(%Schema{type: :integer}, "", %{})
    end

    test "from invalid data type" do
      assert {:error, _} = Schema.cast(%Schema{type: :integer}, true, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :integer}, 3.14159, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :integer}, nil, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :integer}, [1, 2], %{})
    end
  end

  describe "cast/3 for type: :number" do
    test "from number" do
      assert {:ok, -1.0} = Schema.cast(%Schema{type: :number, format: :float}, -1, %{})
      assert {:ok, -1.0} = Schema.cast(%Schema{type: :number, format: :double}, -1, %{})
      assert {:ok, -1} = Schema.cast(%Schema{type: :number}, -1, %{})
      assert {:ok, 0.0} = Schema.cast(%Schema{type: :number}, 0.0, %{})
      assert {:ok, 1.0} = Schema.cast(%Schema{type: :number}, 1.0, %{})
      assert {:ok, 123.45} = Schema.cast(%Schema{type: :number}, 123.45, %{})
    end
    test "from string" do
      assert {:ok, -1.0} = Schema.cast(%Schema{type: :number}, "-1", %{})
      assert {:ok, 0.0} = Schema.cast(%Schema{type: :number}, "0.0", %{})
      assert {:ok, 1.0} = Schema.cast(%Schema{type: :number}, "1.0", %{})
      assert {:ok, 123.45} = Schema.cast(%Schema{type: :number}, "123.45", %{})
    end
    test "from invalid data type" do
      assert {:error, _} = Schema.cast(%Schema{type: :number}, nil, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :number}, false, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :number}, "", %{})
      assert {:error, _} = Schema.cast(%Schema{type: :number}, "not a number", %{})
      assert {:error, _} = Schema.cast(%Schema{type: :number}, [], %{})
      assert {:error, _} = Schema.cast(%Schema{type: :number}, [1.0, 2.0], %{})
    end
  end

  describe "cast/3 for type: :string" do
    test "from string" do
      assert {:ok, ""} = Schema.cast(%Schema{type: :string}, "", %{})
      assert {:ok, "  "} = Schema.cast(%Schema{type: :string}, "  ", %{})
      assert {:ok, "hello"} = Schema.cast(%Schema{type: :string}, "hello", %{})
    end
    test "from invalid data type" do
      assert {:error, _} = Schema.cast(%Schema{type: :string}, nil, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :string}, [], %{})
      assert {:error, _} = Schema.cast(%Schema{type: :string}, :an_atom, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :string}, 0, %{})
    end
    test "format: :date" do
      assert {:error, _} = Schema.cast(%Schema{type: :string, format: :date}, "2018-01-1", %{})
      assert {:ok, _} = Schema.cast(%Schema{type: :string, format: :date}, "2018-01-01", %{})
    end
    test "format: :date-time" do
      assert {:error, _} = Schema.cast(%Schema{type: :string, format: :"date-time"}, "2018-01-01T00:00:0Z", %{})
      assert {:ok, _} = Schema.cast(%Schema{type: :string, format: :"date-time"}, "2018-01-01T00:00:00Z", %{})
    end
  end

  describe "cast/3 for type: :array" do
    test "from list" do
      assert {:ok, []} = Schema.cast(%Schema{type: :array}, [], %{})
      assert {:ok, [1, 2, 3]} = Schema.cast(%Schema{type: :array}, [1,2,3], %{})
      assert {:ok, [1, "a", true]} = Schema.cast(%Schema{type: :array}, [1, "a", true], %{})

      int_array = %Schema{type: :array, items: %Schema{type: :integer}}
      assert {:ok, [1, 2, 3]} = Schema.cast(int_array, [1, 2, 3], %{})
      assert {:ok, [1, 2, 3]} = Schema.cast(int_array, ["1", "2", "3"], %{})
    end
    test "from invalid data type" do
      assert {:error, _} = Schema.cast(%Schema{type: :array}, nil, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :array}, 0, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :array}, "", %{})
      assert {:error, _} = Schema.cast(%Schema{type: :array}, "1,2,3", %{})
    end
    test "from list with invalid item type" do
      string_array = %Schema{type: :array, items: %Schema{type: :string}}
      assert {:error, _} = Schema.cast(string_array, [1, 2, 3], %{})
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

    test "cast/3 with unexpected type for object" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      user_request_schema = schemas["UserRequest"]

      input = []

      {:error, _output} = Schema.cast(user_request_schema, input, schemas)
    end

    test "cast/3 with unexpected type for nested object" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      user_request_schema = schemas["UserRequest"]

      input = %{
        "user" => []
      }

      {:error, _output} = Schema.cast(user_request_schema, input, schemas)
    end

    test "cast/3 with unexpected type for nested array" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      user_response_schema = schemas["UsersResponse"]

      input = %{
        "data" => %{}
      }

      {:error, _output} = Schema.cast(user_response_schema, input, schemas)
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
               Schema.cast(pet_schema, input, schemas)
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
               Schema.cast(cat_or_dog, input, schemas)
    end

    test "`oneOf` - Cast number to string or number" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :number},
          %Schema{type: :string}
        ]
      }

      result = Schema.cast(schema, "123", %{})

      assert {:ok, 123.0} = result
    end

    test "`oneOf` - Cast string to oneOf number or datetime" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :number},
          %Schema{type: :string, format: :"date-time"}
        ]
      }

      assert {:ok, %DateTime{}} = Schema.cast(schema, "2018-04-01T12:34:56Z", %{})
    end

    test "`anyOf` - Cast string to anyOf number or datetime" do
      schema = %Schema{
        anyOf: [
          %Schema{type: :number},
          %Schema{type: :string, format: :"date-time"}
        ]
      }

      assert {:ok, %DateTime{}} = Schema.cast(schema, "2018-04-01T12:34:56Z", %{})
    end
  end
end
