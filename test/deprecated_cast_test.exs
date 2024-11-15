defmodule OpenApiSpex.DeprecatedCastTest do
  use ExUnit.Case, async: true

  alias OpenApiSpex.Schema
  alias OpenApiSpexTest.{ApiSpec, Schemas}

  describe "cast/3" do
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
        "pet_type" => "Dog",
        "bark" => "bowow"
      }

      assert {:ok, %Schemas.Dog{bark: "bowow", pet_type: "Dog"}} =
               Schema.cast(cat_or_dog, input, schemas)
    end

    test "Cast Cat from oneOf [cat, dog] schema" do
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

    test "Cast number to string or number" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :number},
          %Schema{type: :string}
        ]
      }

      # The following object is valid against both schemas, so it will result in an error
      # – it should be valid against only one of the schemas, since we are using the oneOf keyword.
      # @see https://swagger.io/docs/specification/data-models/oneof-anyof-allof-not/#oneof
      result = Schema.cast(schema, "123", %{})

      assert {:error, _} = result
    end

    test "Cast integer to float" do
      schema = %Schema{type: :number}

      assert Schema.cast(schema, 123, %{}) === {:ok, 123.0}
    end

    test "Cast string to oneOf number or date-time" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :number},
          %Schema{type: :string, format: :"date-time"}
        ]
      }

      assert {:ok, %DateTime{}} = Schema.cast(schema, "2018-04-01T12:34:56Z", %{})
    end

    test "Cast string to anyOf number or date-time" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :number},
          %Schema{type: :string, format: :"date-time"}
        ]
      }

      assert {:ok, %DateTime{}} = Schema.cast(schema, "2018-04-01T12:34:56Z", %{})
    end
  end

  describe "Integer validation" do
    test "Validate schema type integer when value is object" do
      schema = %Schema{
        type: :integer
      }

      assert {:error, _} = Schema.validate(schema, %{}, %{})
    end
  end

  describe "Number validation" do
    test "Validate schema type number when value is object" do
      schema = %Schema{
        type: :integer
      }

      assert {:error, _} = Schema.validate(schema, %{}, %{})
    end

    test "Validate schema type number when value is exclusive" do
      schema = %Schema{
        type: :integer,
        minimum: %Schema.MinMax{value: -1, exclusive?: true},
        maximum: %Schema.MinMax{value: 1, exclusive?: true}
      }

      assert {:error, _} = Schema.validate(schema, 1, %{})
      assert {:error, _} = Schema.validate(schema, -1, %{})
    end
  end

  describe "String validation" do
    test "Validate schema type string when value is object" do
      schema = %Schema{
        type: :string
      }

      assert {:error, _} = Schema.validate(schema, %{}, %{})
    end

    test "Validate schema type string when value is DateTime" do
      schema = %Schema{
        type: :string
      }

      assert {:error, _} = Schema.validate(schema, DateTime.utc_now(), %{})
    end

    test "Validate non-empty string with expected value" do
      schema = %Schema{type: :string, minLength: 1}
      assert :ok = Schema.validate(schema, "BLIP", %{})
    end
  end

  describe "DateTime validation" do
    test "Validate schema type string with format date-time when value is DateTime" do
      schema = %Schema{
        type: :string,
        format: :"date-time"
      }

      assert :ok = Schema.validate(schema, DateTime.utc_now(), %{})
    end
  end

  describe "Date Validation" do
    test "Validate schema type string with format date when value is Date" do
      schema = %Schema{
        type: :string,
        format: :date
      }

      assert :ok = Schema.validate(schema, Date.utc_today(), %{})
    end
  end

  describe "Enum validation" do
    test "Validate string enum with unexpected value" do
      schema = %Schema{
        type: :string,
        enum: ["foo", "bar"]
      }

      assert {:error, _} = Schema.validate(schema, "baz", %{})
    end

    test "Validate string enum with expected value" do
      schema = %Schema{
        type: :string,
        enum: ["foo", "bar"]
      }

      assert :ok = Schema.validate(schema, "bar", %{})
    end
  end

  describe "Object validation" do
    test "Validate schema type object when value is array" do
      schema = %Schema{
        type: :object
      }

      assert {:error, _} = Schema.validate(schema, [], %{})
    end

    test "Validate schema type object when value is DateTime" do
      schema = %Schema{
        type: :object
      }

      assert {:error, _} = Schema.validate(schema, DateTime.utc_now(), %{})
    end
  end

  describe "Array validation" do
    test "Validate schema type array when value is object" do
      schema = %Schema{
        type: :array
      }

      assert {:error, _} = Schema.validate(schema, %{}, %{})
    end
  end

  describe "Boolean validation" do
    test "Validate schema type boolean when value is object" do
      schema = %Schema{
        type: :boolean
      }

      assert {:error, _} = Schema.validate(schema, %{}, %{})
    end
  end

  describe "AnyOf validation" do
    test "Validate anyOf schema with valid value" do
      schema = %Schema{
        anyOf: [
          %Schema{type: :array},
          %Schema{type: :string}
        ]
      }

      assert :ok = Schema.validate(schema, "a string", %{})
    end

    test "Validate anyOf with value matching more than one schema" do
      schema = %Schema{
        anyOf: [
          %Schema{type: :number},
          %Schema{type: :integer}
        ]
      }

      assert :ok = Schema.validate(schema, 42, %{})
    end

    test "Validate anyOf schema with invalid value" do
      schema = %Schema{
        anyOf: [
          %Schema{type: :string},
          %Schema{type: :array}
        ]
      }

      assert {:error, _} = Schema.validate(schema, 3.14159, %{})
    end
  end

  describe "OneOf validation" do
    test "Validate oneOf schema with valid value" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :string},
          %Schema{type: :array}
        ]
      }

      assert :ok = Schema.validate(schema, [1, 2, 3], %{})
    end

    test "Validate oneOf schema with invalid value" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :string},
          %Schema{type: :array}
        ]
      }

      assert {:error, _} = Schema.validate(schema, 3.14159, %{})
    end

    test "Validate oneOf schema when matching multiple schemas" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :object, properties: %{a: %Schema{type: :string}}},
          %Schema{type: :object, properties: %{b: %Schema{type: :string}}}
        ]
      }

      assert {:error, _} = Schema.validate(schema, %{a: "a", b: "b"}, %{})
    end
  end

  describe "AllOf validation" do
    test "Validate allOf schema with valid value" do
      schema = %Schema{
        allOf: [
          %Schema{type: :object, properties: %{a: %Schema{type: :string}}},
          %Schema{type: :object, properties: %{b: %Schema{type: :string}}}
        ]
      }

      assert :ok = Schema.validate(schema, %{a: "a", b: "b"}, %{})
    end

    test "Validate allOf schema with invalid value" do
      schema = %Schema{
        allOf: [
          %Schema{type: :object, properties: %{a: %Schema{type: :string}}},
          %Schema{type: :object, properties: %{b: %Schema{type: :string}}}
        ]
      }

      assert {:error, msg} = Schema.validate(schema, %{a: 1, b: 2}, %{})
      assert msg =~ "#/a"
      assert msg =~ "#/b"
    end

    test "Validate allOf with value matching not all schemas" do
      schema = %Schema{
        allOf: [
          %Schema{
            type: :integer,
            minimum: 5
          },
          %Schema{
            type: :integer,
            maximum: 40
          }
        ]
      }

      assert {:error, _} = Schema.validate(schema, 42, %{})
    end
  end

  describe "Not validation" do
    test "Validate not schema with valid value" do
      schema = %Schema{
        not: %Schema{type: :object}
      }

      assert :ok = Schema.validate(schema, 1, %{})
    end

    test "Validate not schema with invalid value" do
      schema = %Schema{
        not: %Schema{type: :object}
      }

      assert {:error, _} = Schema.validate(schema, %{a: 1}, %{})
    end

    test "Verify 'not' validation" do
      schema = %Schema{not: %Schema{type: :boolean}}
      assert :ok = Schema.validate(schema, 42, %{})
      assert :ok = Schema.validate(schema, "42", %{})
      assert :ok = Schema.validate(schema, nil, %{})
      assert :ok = Schema.validate(schema, 4.2, %{})
      assert :ok = Schema.validate(schema, [4], %{})
      assert :ok = Schema.validate(schema, %{}, %{})
      assert {:error, _} = Schema.validate(schema, true, %{})
      assert {:error, _} = Schema.validate(schema, false, %{})
    end
  end

  describe "Nullable validation" do
    test "Validate nullable-ified with expected value" do
      schema = %Schema{
        nullable: true,
        type: :string,
        minLength: 1
      }

      assert :ok = Schema.validate(schema, "BLIP", %{})
    end

    test "Validate nullable with expected value" do
      schema = %Schema{type: :string, nullable: true}
      assert :ok = Schema.validate(schema, nil, %{})
    end

    test "Validate nullable with unexpected value" do
      schema = %Schema{type: :string, nullable: true}
      assert :ok = Schema.validate(schema, "bla", %{})
    end
  end

  describe "Default property value" do
    test "Available in structure" do
      size = %Schemas.Size{}
      assert "cm" == size.unit
      assert 100 == size.value
    end

    test "Available after cast" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      size = Map.fetch!(schemas, "Size")

      assert {:ok, %Schemas.Size{value: 100, unit: "cm"}} ==
               Schema.cast(size, %{}, schemas)

      assert {:ok, %Schemas.Size{value: 110, unit: "cm"}} ==
               Schema.cast(size, %{value: 110}, schemas)
    end
  end
end
