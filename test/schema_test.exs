defmodule OpenApiSpex.SchemaTest do
  use ExUnit.Case

  alias OpenApiSpex.{Schema, Reference}
  alias OpenApiSpexTest.{ApiSpec, Schemas}

  import OpenApiSpex.TestAssertions

  doctest Schema

  describe "schema/1" do
    test "EntityWithDict Schema example matches schema" do
      api_spec = ApiSpec.spec()
      assert_schema(Schemas.EntityWithDict.schema().example, "EntityWithDict", api_spec)
    end

    test "User Schema example matches schema" do
      spec = ApiSpec.spec()

      assert_schema(Schemas.User.schema().example, "User", spec)
      assert_schema(Schemas.UserRequest.schema().example, "UserRequest", spec, :write)
      assert_schema(Schemas.UserResponse.schema().example, "UserResponse", spec, :read)
      assert_schema(Schemas.UsersResponse.schema().example, "UsersResponse", spec, :read)
    end

    test "Array Schema example matches schema" do
      api_spec = ApiSpec.spec()
      assert_schema(Schemas.Array.schema().example, "Array", api_spec)
    end

    test "Primitive Schema example matches schema" do
      api_spec = ApiSpec.spec()
      assert_schema(Schemas.Primitive.schema().example, "Primitive", api_spec)
    end
  end

  describe "schema/1 doesn't generate warnings" do
    test "if property is duplicated in allOf" do
      module =
        quote do
          defmodule AllOfWarning do
            require OpenApiSpex

            OpenApiSpex.schema(%{
              type: :object,
              allOf: [
                %Schema{
                  type: :object,
                  properties: %{
                    state: %Schema{
                      type: :string
                    }
                  }
                }
              ],
              properties: %{
                state: %Schema{
                  type: :string
                }
              }
            })
          end
        end

      warnings_and_errors =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          Code.compile_quoted(module)
        end)

      assert warnings_and_errors == ""
    end
  end

  describe "schema/1 auto-populates title" do
    defmodule Name do
      require OpenApiSpex

      OpenApiSpex.schema(%{
        type: :string
      })
    end

    defmodule Age do
      require OpenApiSpex

      OpenApiSpex.schema(%{
        title: "CustomAge",
        type: :integer
      })
    end

    test "autopopulated title" do
      assert Name.schema().title == "Name"
    end

    test "custom title" do
      assert Age.schema().title == "CustomAge"
    end
  end

  describe "example/1" do
    test "uses value in `example` property when not nil" do
      assert Schema.example(%Schema{type: :string, example: "foo"}) == "foo"
    end

    test "defaults to type-appropriate value for :string" do
      assert Schema.example(%Schema{type: :string}) == ""
    end

    test "defaults to type-appropriate value for :string with a minLength" do
      assert Schema.example(%Schema{type: :string, minLength: 1}) == "a"
      assert Schema.example(%Schema{type: :string, minLength: 2}) == "ab"
      assert Schema.example(%Schema{type: :string, minLength: 3}) == "abc"
      assert Schema.example(%Schema{type: :string, minLength: 4}) == "abcd"
      assert Schema.example(%Schema{type: :string, minLength: 5}) == "abcde"
      assert Schema.example(%Schema{type: :string, minLength: 6}) == "abcdef"
      assert Schema.example(%Schema{type: :string, minLength: 7}) == "example"
      assert Schema.example(%Schema{type: :string, minLength: 9}) == "exampleex"
    end

    test "defaults to type-appropriate value for :integer, :number" do
      assert Schema.example(%Schema{type: :integer}) === 0
      assert Schema.example(%Schema{type: :number}) === 0
    end

    test "defaults to type-appropriate value for :number with :float or :double format" do
      assert Schema.example(%Schema{type: :number, format: :float}) === 0.0
      assert Schema.example(%Schema{type: :number, format: :double}) === 0.0
    end

    test "uses :minimum for :integer, :number" do
      assert Schema.example(%Schema{type: :integer, minimum: 10}) === 10
      assert Schema.example(%Schema{type: :number, minimum: 10}) === 10
    end

    test "uses :minimum for :integer, :number via struct" do
      assert Schema.example(%Schema{type: :integer, minimum: %Schema.MinMax{value: 10}}) === 10
      assert Schema.example(%Schema{type: :number, minimum: %Schema.MinMax{value: 10}}) === 10
    end

    test "obeys exclusive minimum for :integer, :number" do
      assert Schema.example(%Schema{
               type: :integer,
               minimum: %Schema.MinMax{value: 10, exclusive?: true}
             }) ===
               11

      assert Schema.example(%Schema{
               type: :number,
               minimum: %Schema.MinMax{value: 10, exclusive?: true}
             }) ===
               11
    end

    test "uses :maximum for :integer, :number" do
      assert Schema.example(%Schema{type: :integer, maximum: 10}) === 10
      assert Schema.example(%Schema{type: :number, maximum: 10}) === 10
    end

    test "uses :maximum for :integer, :number via struct" do
      assert Schema.example(%Schema{type: :integer, maximum: %Schema.MinMax{value: 10}}) === 10
      assert Schema.example(%Schema{type: :number, maximum: %Schema.MinMax{value: 10}}) === 10
    end

    test "obeys exclusive maximum for numbers" do
      assert Schema.example(%Schema{
               type: :integer,
               maximum: %Schema.MinMax{value: 10, exclusive?: true}
             }) ===
               9

      assert Schema.example(%Schema{
               type: :number,
               maximum: %Schema.MinMax{value: 10, exclusive?: true}
             }) ===
               9
    end

    test "defaults to type-appropriate value for :boolean" do
      assert Schema.example(%Schema{type: :boolean}) == false
    end

    test "reaches into object properties" do
      schema = %Schema{
        type: :object,
        properties: %{
          name: %Schema{type: :string, example: "Sample"}
        }
      }

      assert Schema.example(schema) == %{name: "Sample"}
    end

    test "reaches into nested object properties" do
      schema = %Schema{
        type: :object,
        properties: %{
          child: %Schema{
            type: :object,
            properties: %{
              name: %Schema{type: :string, example: "Sample"},
              other: %Schema{type: :string}
            }
          }
        }
      }

      assert Schema.example(schema) == %{
               child: %{
                 name: "Sample",
                 other: ""
               }
             }
    end

    test "example for array" do
      schema = %Schema{
        type: :array,
        items: %Schema{type: :string, example: "Sample"}
      }

      assert Schema.example(schema) == ["Sample"]
    end

    test "example of allOf schema" do
      schema = %Schema{
        allOf: [
          %Schema{type: :object, properties: %{name: %Schema{type: :string, example: "OAS"}}},
          %Schema{type: :object, properties: %{version: %Schema{type: :integer, example: 3}}}
        ]
      }

      assert Schema.example(schema) == %{name: "OAS", version: 3}
    end

    test "example for oneOf schema" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :string, example: "one"},
          %Schema{type: :string, example: "two"}
        ]
      }

      assert Schema.example(schema) == "one"
    end

    test "example for enum" do
      schema = %Schema{type: :string, enum: ["one", "two"]}
      assert Schema.example(schema) == "one"
    end

    test "string :date format" do
      schema = %Schema{type: :string, format: :date}
      assert Schema.example(schema) == "2020-04-20"
    end

    test "string :date-time format" do
      schema = %Schema{type: :string, format: :"date-time"}
      assert Schema.example(schema) == "2020-04-20T16:20:00Z"
    end

    test "string :uuid format" do
      schema = %Schema{type: :string, format: :uuid}
      assert Schema.example(schema) == "02ef9c5f-29e6-48fc-9ec3-7ed57ed351f6"
    end

    test "example for schema module" do
      defmodule Bar do
        require OpenApiSpex

        OpenApiSpex.schema(%{
          type: :object,
          properties: %{
            baz: %Schema{
              type: :int,
              example: 2
            }
          }
        })
      end

      defmodule Foo do
        require OpenApiSpex

        OpenApiSpex.schema(%{
          type: :object,
          properties: %{
            bar: Bar,
            foo: %Schema{
              type: :string,
              example: "1"
            }
          }
        })
      end

      assert Schema.example(Foo) == %{bar: %{baz: 2}, foo: "1"}
    end
  end

  describe "example/2" do
    setup do
      [spec: ApiSpec.spec()]
    end

    test "resolves references in allOf schemas", %{spec: spec} do
      schema = spec.components.schemas["TrainingAppointment"]

      assert %{appointment_type: "", level: 0} = Schema.example(schema, spec)
    end

    test "uses value in `example` property when not nil", %{spec: spec} do
      assert Schema.example(%Schema{type: :string, example: "foo"}, spec) == "foo"
    end

    test "defaults to type-appropriate value for :string", %{spec: spec} do
      assert Schema.example(%Schema{type: :string}, spec) == ""
    end

    test "defaults to type-appropriate value for :integer, :number", %{spec: spec} do
      assert Schema.example(%Schema{type: :integer}, spec) === 0
      assert Schema.example(%Schema{type: :number}, spec) === 0
    end

    test "defaults to type-appropriate value for :number with :float or :double format", %{
      spec: spec
    } do
      assert Schema.example(%Schema{type: :number, format: :float}, spec) === 0.0
      assert Schema.example(%Schema{type: :number, format: :double}, spec) === 0.0
    end

    test "uses :minimum for :integer, :number", %{spec: spec} do
      assert Schema.example(%Schema{type: :integer, minimum: 10}, spec) === 10
      assert Schema.example(%Schema{type: :number, minimum: 10}, spec) === 10
    end

    test "obeys exclusive minimum for :integer, :number", %{spec: spec} do
      assert Schema.example(
               %Schema{type: :integer, minimum: %Schema.MinMax{value: 10, exclusive?: true}},
               spec
             ) ===
               11

      assert Schema.example(
               %Schema{type: :number, minimum: %Schema.MinMax{value: 10, exclusive?: true}},
               spec
             ) ===
               11
    end

    test "uses :maximum for :integer, :number", %{spec: spec} do
      assert Schema.example(%Schema{type: :integer, maximum: 10}, spec) === 10
      assert Schema.example(%Schema{type: :number, maximum: 10}, spec) === 10
    end

    test "obeys exclusive maximum for numbers", %{spec: spec} do
      assert Schema.example(
               %Schema{type: :integer, maximum: %Schema.MinMax{value: 10, exclusive?: true}},
               spec
             ) ===
               9

      assert Schema.example(
               %Schema{type: :number, maximum: %Schema.MinMax{value: 10, exclusive?: true}},
               spec
             ) ===
               9
    end

    test "defaults to type-appropriate value for :boolean", %{spec: spec} do
      assert Schema.example(%Schema{type: :boolean}, spec) == false
    end

    test "reaches into object properties", %{spec: spec} do
      schema = %Schema{
        type: :object,
        properties: %{
          name: %Schema{type: :string, example: "Sample"}
        }
      }

      assert Schema.example(schema, spec) == %{name: "Sample"}
    end

    test "reaches into nested object properties", %{spec: spec} do
      schema = %Schema{
        type: :object,
        properties: %{
          child: %Schema{
            type: :object,
            properties: %{
              name: %Schema{type: :string, example: "Sample"},
              other: %Schema{type: :string}
            }
          }
        }
      }

      assert Schema.example(schema, spec) == %{
               child: %{
                 name: "Sample",
                 other: ""
               }
             }
    end

    test "example for array", %{spec: spec} do
      schema = %Schema{
        type: :array,
        items: %Schema{type: :string, example: "Sample"}
      }

      assert Schema.example(schema, spec) == ["Sample"]
    end

    test "example of allOf schema", %{spec: spec} do
      schema = %Schema{
        allOf: [
          %Schema{type: :object, properties: %{name: %Schema{type: :string, example: "OAS"}}},
          %Schema{type: :object, properties: %{version: %Schema{type: :integer, example: 3}}}
        ]
      }

      assert Schema.example(schema, spec) == %{name: "OAS", version: 3}
    end

    test "example for oneOf schema", %{spec: spec} do
      schema = %Schema{
        oneOf: [
          %Schema{type: :string, example: "one"},
          %Schema{type: :string, example: "two"}
        ]
      }

      assert Schema.example(schema, spec) == "one"
    end

    test "example for anyOf schema", %{spec: spec} do
      schema = %Schema{
        anyOf: [
          %Schema{type: :string, example: "one"},
          %Schema{type: :string, example: "two"}
        ]
      }

      assert Schema.example(schema, spec) == "one"
    end

    test "example for reference", %{spec: spec} do
      assert %{
               "email" => "joe@gmail.com",
               "id" => 123,
               "inserted_at" => "2017-09-12T12:34:55Z",
               "name" => "Joe User",
               "password" => "12345678",
               "updated_at" => "2017-09-13T10:11:12Z"
             } = Schema.example(%Reference{"$ref": "#/components/schemas/User"}, spec)
    end

    test "example for oneOf schema with reference", %{spec: spec} do
      schema = %Schema{
        oneOf: [
          %Reference{"$ref": "#/components/schemas/User"},
          %Schema{type: :string, example: "one"},
          %Schema{type: :string, example: "two"}
        ]
      }

      assert %{
               "email" => "joe@gmail.com",
               "id" => 123,
               "inserted_at" => "2017-09-12T12:34:55Z",
               "name" => "Joe User",
               "password" => "12345678",
               "updated_at" => "2017-09-13T10:11:12Z"
             } = Schema.example(schema, spec)
    end

    test "example for enum", %{spec: spec} do
      schema = %Schema{type: :string, enum: ["one", "two"]}

      assert Schema.example(schema, spec) == "one"
    end

    test "string :date format", %{spec: spec} do
      schema = %Schema{type: :string, format: :date}

      assert Schema.example(schema, spec) == "2020-04-20"
    end

    test "string :date-time format", %{spec: spec} do
      schema = %Schema{type: :string, format: :"date-time"}

      assert Schema.example(schema, spec) == "2020-04-20T16:20:00Z"
    end

    test "string :uuid format", %{spec: spec} do
      schema = %Schema{type: :string, format: :uuid}

      assert Schema.example(schema, spec) == "02ef9c5f-29e6-48fc-9ec3-7ed57ed351f6"
    end

    test "example for schema module", %{spec: spec} do
      defmodule OtherBar do
        require OpenApiSpex

        OpenApiSpex.schema(%{
          type: :object,
          properties: %{
            baz: %Schema{
              type: :int,
              example: 2
            }
          }
        })
      end

      defmodule OtherFoo do
        require OpenApiSpex

        OpenApiSpex.schema(%{
          type: :object,
          properties: %{
            bar: OtherBar,
            foo: %Schema{
              type: :string,
              example: "1"
            }
          }
        })
      end

      assert Schema.example(OtherFoo, spec) == %{bar: %{baz: 2}, foo: "1"}
    end
  end

  describe "properties/1" do
    test "informative error raised for invalid :properties" do
      schema = %Schema{
        type: :object,
        properties: %{errors: []}
      }

      assert_raise RuntimeError,
                   "Expected %Schema{}, schema module, or %Reference{}. Got: []",
                   fn ->
                     Schema.properties(schema)
                   end
    end

    test "returns unique values for schemas with allOf defined" do
      schema = %Schema{
        type: :object,
        allOf: [
          %Schema{
            type: :object,
            properties: %{
              state: %Schema{
                type: :string
              }
            }
          }
        ],
        properties: %{
          state: %Schema{
            type: :string
          }
        }
      }

      assert [state: nil] = Schema.properties(schema)
    end
  end
end
