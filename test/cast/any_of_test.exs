defmodule OpenApiSpex.CastAnyOfTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, Reference, Schema}
  alias OpenApiSpexTest.Schemas
  alias OpenApiSpex.Cast.{Error, AnyOf}

  defp cast(ctx), do: AnyOf.cast(struct(Cast, ctx))

  describe "cast/1" do
    test "basics" do
      schema = %Schema{anyOf: [%Schema{type: :array}, %Schema{type: :string}]}
      assert {:ok, "jello"} = cast(value: "jello", schema: schema)
    end

    test "object" do
      dog_schema = %Schema{
        title: "Dog",
        type: :object,
        properties: %{
          breed: %Schema{type: :string},
          age: %Schema{type: :integer}
        }
      }

      cat_schema = %Schema{
        title: "Cat",
        type: :object,
        properties: %{
          breed: %Schema{type: :string},
          lives: %Schema{type: :integer}
        }
      }

      schema = %Schema{anyOf: [dog_schema, cat_schema], title: "MyCoolSchema"}
      value = %{"breed" => "Corgi", "age" => 3}
      assert {:ok, %{breed: "Corgi", age: 3}} = cast(value: value, schema: schema)
    end

    test "should cast multiple schemas" do
      dog_schema = %Schema{
        title: "Dog",
        type: :object,
        properties: %{
          breed: %Schema{type: :string},
          age: %Schema{type: :integer}
        }
      }

      food_schema = %Schema{
        title: "Food",
        type: :object,
        properties: %{
          food: %Schema{type: :string},
          amount: %Schema{type: :integer}
        }
      }

      schema = %Schema{anyOf: [dog_schema, food_schema], title: "MyCoolSchema"}
      value = %{"breed" => "Corgi", "age" => 3, "food" => "meat"}
      assert {:ok, %{breed: "Corgi", age: 3, food: "meat"}} = cast(value: value, schema: schema)
    end

    test "should cast multiple schemas with conflicting properties" do
      dog_schema = %Schema{
        title: "Dog",
        type: :object,
        properties: %{
          breed: %Schema{type: :string},
          age: %Schema{type: :integer}
        }
      }

      food_schema = %Schema{
        title: "Food",
        type: :object,
        properties: %{
          food: %Schema{type: :string},
          amount: %Schema{type: :integer},
          age: %Schema{type: :integer}
        }
      }

      schema = %Schema{anyOf: [dog_schema, food_schema], title: "MyCoolSchema"}
      value = %{"breed" => "Corgi", "age" => 3, "food" => "meat"}
      assert {:ok, %{breed: "Corgi", age: 3, food: "meat"}} = cast(value: value, schema: schema)
    end

    test "returns the errors of all the schemas when none match" do
      schema_1 = %Schema{
        type: :object,
        additionalProperties: false,
        properties: %{
          breed: %Schema{type: :string}
        }
      }

      schema_2 = %Schema{
        type: :object,
        additionalProperties: false,
        properties: %{
          food: %Schema{type: :string, minLength: 5}
        }
      }

      schema = %Schema{anyOf: [schema_1, schema_2], title: "MyCoolSchema", type: :object}
      value = %{"food" => "meat"}

      assert {:error, [error_any_of, error_unexpected_field, error_food]} =
               cast(value: value, schema: schema)

      assert Error.message(error_any_of) ==
               "Failed to cast value using any of: Schema(type: :object), Schema(type: :object)"

      assert Error.message(error_unexpected_field) ==
               "Unexpected field: food"

      assert Error.message(error_food) ==
               "String length is smaller than minLength: 5"
    end

    test "no castable schema" do
      schema = %Schema{anyOf: [%Schema{type: :integer}, %Schema{type: :string}]}
      assert {:error, [error, _, _]} = cast(value: [:whoops], schema: schema)

      assert Error.message(error) ==
               "Failed to cast value using any of: Schema(type: :string), Schema(type: :integer)"

      schema_with_title = %Schema{anyOf: [%Schema{title: "Age", type: :integer}]}
      assert {:error, [error_with_schema_title, _]} = cast(value: [], schema: schema_with_title)

      assert Error.message(error_with_schema_title) ==
               "Failed to cast value using any of: Schema(title: \"Age\", type: :integer)"
    end

    test "empty list" do
      schema = %Schema{anyOf: [], title: "MyCoolSchema"}
      assert {:error, [error]} = cast(value: "jello", schema: schema)
      assert error.reason == :any_of

      assert Error.message(error) == "Failed to cast value using any of: [] (no schemas provided)"
    end

    test "anyOf, when given required params only from inside the anyOf schema, return an error" do
      schema = %Schema{
        anyOf: [
          %Reference{
            "$ref": "#/components/schemas/User"
          }
        ],
        required: [:age]
      }

      value = %{
        "name" => "Joe User",
        "email" => "joe@gmail.com",
        "password" => "12345678"
      }

      assert {:error, [error_age]} =
               OpenApiSpex.Cast.AnyOf.cast(
                 struct(OpenApiSpex.Cast,
                   value: value,
                   schema: schema,
                   schemas: %{"User" => Schemas.User.schema()}
                 )
               )

      assert Error.message(error_age) ==
               "Missing field: age"
    end

    test "anyOf, when given all required params inside and outside the anyOf, return the schema" do
      schema = %Schema{
        anyOf: [
          %Reference{
            "$ref": "#/components/schemas/User"
          }
        ],
        required: [:age]
      }

      value = %{
        "name" => "Joe User",
        "email" => "joe@gmail.com",
        "password" => "12345678",
        "age" => "123"
      }

      assert {:ok,
              %{
                age: 123,
                email: "joe@gmail.com",
                name: "Joe User",
                password: "12345678"
              }} =
               OpenApiSpex.Cast.AnyOf.cast(
                 struct(OpenApiSpex.Cast,
                   value: value,
                   schema: schema,
                   schemas: %{"User" => Schemas.User.schema()}
                 )
               )
    end

    test "anyOf with required fields" do
      schema = %Schema{
        anyOf: [
          %Schema{
            type: :object,
            properties: %{
              last_name: %Schema{type: :string}
            },
            required: [:last_name]
          }
        ]
      }

      assert {:error, [error_any_of, error_last_name]} =
               OpenApiSpex.Cast.AnyOf.cast(struct(OpenApiSpex.Cast, value: %{}, schema: schema))

      assert Error.message(error_any_of) ==
               "Failed to cast value using any of: Schema(type: :object)"

      assert Error.message(error_last_name) ==
               "Missing field: last_name"
    end

    test "anyOf with additionalProperties" do
      schema = %Schema{
        anyOf: [
          %Schema{
            type: :object,
            properties: %{
              last_name: %Schema{type: :string}
            }
          },
          %Schema{type: :object, additionalProperties: true}
        ]
      }

      assert {:ok, %{last_name: "Smith"}} == cast(value: %{"last_name" => "Smith"}, schema: schema)
    end

    test "anyOf with readOnly required fields" do
      schema = %Schema{
        anyOf: [
          %Schema{
            type: :object,
            properties: %{
              last_name: %Schema{type: :string, readOnly: true}
            },
            required: [:last_name]
          }
        ]
      }

      assert {:error, [error_any_of, error_last_name]} =
               cast(value: %{}, schema: schema, read_write_scope: :read)

      assert Error.message(error_any_of) ==
               "Failed to cast value using any of: Schema(type: :object)"

      assert Error.message(error_last_name) == "Missing field: last_name"

      assert {:ok, _} = cast(value: %{}, schema: schema, read_write_scope: :write)
    end

    test "anyOf with nullable option" do
      schema = %Schema{
        anyOf: [
          %Schema{
            type: :object,
            properties: %{
              last_name: %Schema{type: :string}
            }
          },
          %Schema{type: :string, nullable: true}
        ]
      }

      assert {:ok, nil} = cast(value: nil, schema: schema)
    end

    test "cast date and date-time" do
      schema = %Schema{
        anyOf: [
          %Schema{type: :string, format: :"date-time"},
          %Schema{type: :string, format: :date}
        ]
      }

      assert {:ok, ~D[2021-01-01]} = cast(value: "2021-01-01", schema: schema)

      assert {:ok, ~U[2022-04-05 16:28:53.168653Z]} =
               cast(value: "2022-04-05T16:28:53.168653Z", schema: schema)
    end
  end
end
