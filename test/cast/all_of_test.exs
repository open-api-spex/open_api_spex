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
      assert {:error, [error]} = cast(value: "one", schema: schema)

      assert Error.message(error) ==
               "Failed to cast value as integer. Value must be castable using `allOf` schemas listed."
    end

    test "allOf, uncastable schema" do
      schema = %Schema{allOf: [%Schema{type: :integer}, %Schema{type: :string}]}
      assert {:error, [error]} = cast(value: [:whoops], schema: schema)

      assert Error.message(error) ==
               "Failed to cast value as integer. Value must be castable using `allOf` schemas listed."

      schema_with_title = %Schema{allOf: [%Schema{title: "Age", type: :integer}]}

      assert {:error, [error_with_schema_title]} = cast(value: [:nopes], schema: schema_with_title)

      assert Error.message(error_with_schema_title) ==
               "Failed to cast value as Age. Value must be castable using `allOf` schemas listed."
    end

    test "a more sophisticated example" do
      dog = %{"bark" => "woof", "pet_type" => "Dog"}
      TestAssertions.assert_schema(dog, "Dog", OpenApiSpexTest.ApiSpec.spec())
    end

    test "allOf, for inheritance schema" do
      schema = %Schema{
        allOf: [
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

      value = %{id: "e30aee0f-dbda-40bd-9198-6cf609b8b640", bar: "foo"}

      assert {:ok, %{id: "e30aee0f-dbda-40bd-9198-6cf609b8b640", bar: "foo"}} =
               cast(value: value, schema: schema)
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
    assert {:ok, [2, 3, 4, true, "Test #1", "Five!"]} = cast(value: value, schema: schema)
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

    assert {:error, [error_all_of, error_age]} =
             OpenApiSpex.Cast.AllOf.cast(
               struct(OpenApiSpex.Cast,
                 value: value,
                 schema: schema,
                 schemas: %{"User" => Schemas.User.schema()}
               )
             )

    assert Error.message(error_all_of) ==
             "Failed to cast value as User. Value must be castable using `allOf` schemas listed."

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
            }} =
             OpenApiSpex.Cast.AllOf.cast(
               struct(OpenApiSpex.Cast,
                 value: value,
                 schema: schema,
                 schemas: %{"User" => Schemas.User.schema()}
               )
             )
  end

  test "allOf with required fields" do
    schema = %Schema{
      allOf: [
        %Schema{
          type: :object,
          properties: %{
            last_name: %Schema{type: :string}
          },
          required: [:last_name]
        }
      ]
    }

    assert {:error, [error_all_of, error_last_name]} =
             OpenApiSpex.Cast.AllOf.cast(struct(OpenApiSpex.Cast, value: %{}, schema: schema))

    assert Error.message(error_all_of) ==
             "Failed to cast value as object. Value must be castable using `allOf` schemas listed."

    assert Error.message(error_last_name) ==
             "Missing field: last_name"
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
             OpenApiSpex.Cast.AllOf.cast(
               struct(OpenApiSpex.Cast, value: %{last_name: "x"}, schema: schema)
             )

    assert Error.message(error_all_of) ==
             "Failed to cast value as object. Value must be castable using `allOf` schemas listed."

    assert Error.message(error_last_name) ==
             "String length is smaller than minLength: 2"
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

    assert {:ok, %{last_name: "aa"}} =
             OpenApiSpex.Cast.AllOf.cast(
               struct(OpenApiSpex.Cast, value: %{last_name: "aa"}, schema: schema)
             )
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
    assert {:ok, _} = cast(value: value, schema: CatSchema.schema())
  end
end
