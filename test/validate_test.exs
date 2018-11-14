defmodule OpenApiSpex.ValidatTeest do
  use ExUnit.Case
  alias OpenApiSpex.Schema

  describe "Integer validation" do
    test "Validate schema type integer when value is object" do
      schema = %Schema{
        type: :integer
      }

      assert {:error, "#: invalid type object where integer expected"} =
               Schema.validate(schema, %{}, %{})
    end
  end

  describe "Number validation" do
    test "Validate schema type number when value is object" do
      schema = %Schema{
        type: :integer
      }

      assert {:error, "#: invalid type object where integer expected"} =
               Schema.validate(schema, %{}, %{})
    end
  end

  describe "String validation" do
    test "Validate schema type string when value is object" do
      schema = %Schema{
        type: :string
      }

      assert {:error, "#: invalid type object where string expected"} =
               Schema.validate(schema, %{}, %{})
    end

    test "Validate schema type string when value is DateTime" do
      schema = %Schema{
        type: :string
      }

      assert {:error, "#: invalid type DateTime where string expected"} =
               Schema.validate(schema, DateTime.utc_now(), %{})
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

      assert {:error, "#: Value not in enum: \"baz\""} = Schema.validate(schema, "baz", %{})
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

      assert {:error, "#: invalid type array where object expected"} =
               Schema.validate(schema, [], %{})
    end

    test "Validate schema type object when value is DateTime" do
      schema = %Schema{
        type: :object
      }

      assert {:error, "#: invalid type DateTime where object expected"} =
               Schema.validate(schema, DateTime.utc_now(), %{})
    end
  end

  describe "Array validation" do
    test "Validate schema type array when value is object" do
      schema = %Schema{
        type: :array
      }

      assert {:error, "#: invalid type object where array expected"} =
               Schema.validate(schema, %{}, %{})
    end
  end

  describe "Boolean validation" do
    test "Validate schema type boolean when value is object" do
      schema = %Schema{
        type: :boolean
      }

      assert {:error, "#: invalid type object where boolean expected"} =
               Schema.validate(schema, %{}, %{})
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

      assert {:error, "#: Failed to validate against any schema"} =
               Schema.validate(schema, 3.14159, %{})
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

      assert {:error, "#: Failed to validate against any schema"} =
               Schema.validate(schema, 3.14159, %{})
    end

    test "Validate oneOf schema when matching multiple schemas" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :object, properties: %{a: %Schema{type: :string}}},
          %Schema{type: :object, properties: %{b: %Schema{type: :string}}}
        ]
      }

      assert {:error, "#: Validated against 2 schemas when only one expected"} =
               Schema.validate(schema, %{a: "a", b: "b"}, %{})
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

      assert msg ==
               "#/a: invalid type integer where string expected\n#/b: invalid type integer where string expected"
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

      assert {:error, "#: 42 is larger than maximum 40"} = Schema.validate(schema, 42, %{})
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

      assert {:error, "#: Value is valid for schema given in `not`"} =
               Schema.validate(schema, %{a: 1}, %{})
    end

    test "Verify 'not' validation" do
      schema = %Schema{not: %Schema{type: :boolean}}
      assert :ok = Schema.validate(schema, 42, %{})
      assert :ok = Schema.validate(schema, "42", %{})
      assert :ok = Schema.validate(schema, nil, %{})
      assert :ok = Schema.validate(schema, 4.2, %{})
      assert :ok = Schema.validate(schema, [4], %{})
      assert :ok = Schema.validate(schema, %{}, %{})

      assert {:error, "#: Value is valid for schema given in `not`"} =
               Schema.validate(schema, true, %{})

      assert {:error, "#: Value is valid for schema given in `not`"} =
               Schema.validate(schema, false, %{})
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
