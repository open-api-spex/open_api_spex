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
end
