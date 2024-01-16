defmodule OpenApiSpex.CastAllOfTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, Schema}
  alias OpenApiSpex.Cast.{Error, AllOf}
  alias OpenApiSpex.TestAssertions
  alias OpenApiSpexTest.Schemas
  alias OpenApiSpex.Reference

  defp cast(ctx), do: AllOf.cast(struct(Cast, ctx))

  describe "cast/1" do
    test "allOf" do
      schema = %Schema{allOf: [%Schema{type: :integer}, %Schema{type: :string}]}
      assert {:ok, 1} = cast(value: "1", schema: schema)
      assert {:error, [error | _]} = cast(value: "one", schema: schema)

      assert Error.message(error) ==
               "Failed to cast value as integer. Value must be castable using `allOf` schemas listed."
    end

    test "allOf, uncastable schema" do
      schema = %Schema{allOf: [%Schema{type: :integer}, %Schema{type: :string}]}
      assert {:error, [error | _]} = cast(value: [:whoops], schema: schema)

      assert Error.message(error) ==
               "Failed to cast value as integer. Value must be castable using `allOf` schemas listed."

      schema_with_title = %Schema{allOf: [%Schema{title: "Age", type: :integer}]}

      assert {:error, [error_with_schema_title | _]} =
               cast(value: [:nopes], schema: schema_with_title)

      assert Error.message(error_with_schema_title) ==
               "Failed to cast value as Age. Value must be castable using `allOf` schemas listed."
    end

    test "a more sophisticated example" do
      dog = %{"bark" => "woof", "pet_type" => "Dog"}
      TestAssertions.assert_schema(dog, "Dog", OpenApiSpexTest.ApiSpec.spec())
    end

    test "allOf, for inheritance schema" do
      import ExUnit.CaptureIO

      defmodule NamedEntity do
        require OpenApiSpex
        alias OpenApiSpex.{Schema}

        OpenApiSpex.schema(%{
          title: "NamedEntity",
          description: "Anything with a name",
          type: :object,
          properties: %{
            name: %Schema{type: :string}
          },
          required: [:name]
        })
      end

      schema = %Schema{
        allOf: [
          NamedEntity,
          %Schema{
            type: :object,
            properties: %{
              id: %Schema{
                type: :string
              }
            }
          },
          %Schema{
            type: :object,
            properties: %{
              bar: %Schema{
                type: :string
              }
            }
          }
        ]
      }

      value = %{id: "e30aee0f-dbda-40bd-9198-6cf609b8b640", bar: "foo", name: "Elizabeth"}

      capture_io(:stderr, fn ->
        assert {:ok, %{id: "e30aee0f-dbda-40bd-9198-6cf609b8b640", bar: "foo"}} =
                 cast(value: value, schema: schema)
      end)
    end

    test "allOf, optional that does not pass validation" do
      schema = %Schema{
        allOf: [
          %Schema{
            type: :object,
            properties: %{
              last_name: %Schema{type: :string, minLength: 2}
            }
          }
        ]
      }

      assert {:error, [error_all_of, error_last_name]} =
               cast(value: %{last_name: "x"}, schema: schema)

      assert Error.message(error_all_of) ==
               "Failed to cast value as object. Value must be castable using `allOf` schemas listed."

      assert Error.message(error_last_name) ==
               "String length is smaller than minLength: 2"
    end

    test "allOf, when given required params only from inside the allOf schema, return an error" do
      schema = %Schema{
        allOf: [
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
               cast(value: value, schema: schema, schemas: %{"User" => Schemas.User.schema()})

      assert Error.message(error_age) ==
               "Missing field: age"
    end

    test "allOf, when given all required params inside and outside the allOf, return the schema" do
      schema = %Schema{
        allOf: [
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
              }} = cast(value: value, schema: schema, schemas: %{"User" => Schemas.User.schema()})
    end

    test "allOf with required fields" do
      schema = %Schema{
        allOf: [
          %Schema{
            type: :object,
            properties: %{
              last_name: %Schema{type: :string}
            }
          }
        ],
        required: [:last_name]
      }

      assert {:error, [error_last_name]} = cast(value: %{}, schema: schema)

      assert Error.message(error_last_name) == "Missing field: last_name"
    end

    test "allOf, required fields nested with references" do
      address_schema = %Schema{
        type: :object,
        properties: %{
          street: %Schema{type: :string}
        }
      }

      nested_schema = %Schema{
        title: "Nested",
        allOf: [
          %Reference{
            "$ref": "#/components/schemas/User"
          },
          %Reference{
            "$ref": "#/components/schemas/Address"
          }
        ]
      }

      schema = %Schema{
        title: "Parent",
        allOf: [%Reference{"$ref": "#/components/schemas/Nested"}],
        required: [:age]
      }

      value = %{
        "name" => "Joe User",
        "email" => "joe@gmail.com",
        "password" => "12345678"
      }

      assert {:error, [error]} =
               cast(
                 value: value,
                 schema: schema,
                 schemas: %{
                   "User" => Schemas.User.schema(),
                   "Address" => address_schema,
                   "Nested" => nested_schema
                 }
               )

      assert Error.message(error) ==
               "Missing field: age"
    end

    test "allOf should match all schemas" do
      schema = %Schema{
        allOf: [
          %Schema{
            type: :object,
            additionalProperties: false,
            properties: %{
              last_name: %Schema{type: :string, minLength: 2}
            }
          },
          %Schema{
            type: :object,
            properties: %{
              name: %Schema{type: :string, minLength: 2}
            }
          }
        ]
      }

      assert {:ok, %{last_name: "aa"}} = cast(value: %{last_name: "aa"}, schema: schema)
    end

    test "allOf with additionalProperties" do
      schema = %Schema{
        allOf: [
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

    test "allOf with readOnly required fields" do
      schema = %Schema{
        allOf: [
          %Schema{
            type: :object,
            properties: %{
              last_name: %Schema{type: :string, readOnly: true}
            },
            required: [:last_name]
          }
        ]
      }

      assert {:error, [error_all_of, error_last_name]} =
               cast(value: %{}, schema: schema, read_write_scope: :read)

      assert Error.message(error_all_of) ==
               "Failed to cast value as object. Value must be castable using `allOf` schemas listed."

      assert Error.message(error_last_name) == "Missing field: last_name"

      assert {:ok, _} = cast(value: %{}, schema: schema, read_write_scope: :write)
    end

    test "allOf with nullable option" do
      schema = %Schema{
        allOf: [
          %Schema{type: :string, nullable: true}
        ]
      }

      assert {:ok, nil} = cast(value: nil, schema: schema)
    end
  end

  test "allOf, for multi-type array" do
    schema = %Schema{
      allOf: [
        %Schema{type: :array, items: %Schema{type: :integer}},
        %Schema{type: :array, items: %Schema{type: :boolean}},
        %Schema{type: :array, items: %Schema{type: :string}}
      ]
    }

    value = ["Test #1", "2", "3", "4", "true", "Five!"]

    assert {:error,
            [
              %OpenApiSpex.Cast.Error{
                reason: :all_of,
                value: ["Test #1", "2", "3", "4", "true", "Five!"]
              },
              %OpenApiSpex.Cast.Error{
                reason: :invalid_type,
                value: "Test #1",
                type: :integer
              },
              %OpenApiSpex.Cast.Error{
                reason: :invalid_type,
                value: "true",
                type: :integer
              },
              %OpenApiSpex.Cast.Error{
                reason: :invalid_type,
                value: "Five!",
                type: :integer
              }
            ]} = cast(value: value, schema: schema)
  end

  defmodule CatSchema do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Cat",
      allOf: [
        %Schema{
          type: :object,
          properties: %{
            fur: %Schema{type: :boolean}
          }
        },
        %Schema{
          type: :object,
          properties: %{
            meow: %Schema{type: :boolean}
          }
        }
      ]
    })
  end

  test "with schema having x-type" do
    value = %{fur: true, meow: true}

    assert {:ok, %CatSchema{fur: true, meow: true}} = cast(value: value, schema: CatSchema.schema())
  end
end
