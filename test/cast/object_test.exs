defmodule OpenApiSpex.ObjectTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, Schema, Reference}
  alias OpenApiSpex.Cast.{Object, Error}

  defp cast(%Cast{} = ctx), do: Object.cast(ctx)
  defp cast(ctx), do: Object.cast(struct(Cast, ctx))

  describe "cast/3" do
    test "when input is not an object" do
      schema = %Schema{type: :object}
      assert {:error, [error]} = cast(value: ["hello"], schema: schema)
      assert %Error{} = error
      assert error.reason == :invalid_type
      assert error.value == ["hello"]
    end

    test "input map can have atom keys" do
      schema = %Schema{type: :object, properties: %{one: %Schema{type: :string}}}
      assert {:ok, map} = cast(value: %{one: "one"}, schema: schema)
      assert map == %{one: "one"}
    end

    defmodule User2 do
      defstruct [:name]
    end

    test "input map can be a struct" do
      schema = %Schema{type: :object, properties: %{name: %Schema{type: :string}}}
      assert {:ok, map} = cast(value: %User2{name: "bob"}, schema: schema)
      assert map == %User2{name: "bob"}
    end

    test "converting string keys to atom keys when properties are defined" do
      schema = %Schema{
        type: :object,
        properties: %{
          one: nil
        }
      }

      assert {:ok, map} = cast(value: %{"one" => "one"}, schema: schema)
      assert map == %{one: "one"}
    end

    test "properties:nil, given unknown input property" do
      schema = %Schema{type: :object}
      assert cast(value: %{}, schema: schema) == {:ok, %{}}

      assert cast(value: %{"unknown" => "hello"}, schema: schema) ==
               {:ok, %{"unknown" => "hello"}}
    end

    test "with empty schema properties, given unknown input property" do
      schema = %Schema{type: :object, properties: %{}, additionalProperties: false}
      assert cast(value: %{}, schema: schema) == {:ok, %{}}
      assert {:error, [error]} = cast(value: %{"unknown" => "hello"}, schema: schema)
      assert %Error{} = error
      assert error.reason == :unexpected_field
      assert error.name == "unknown"
      assert error.path == ["unknown"]
    end

    test "with schema properties set, given known input property" do
      schema = %Schema{
        type: :object,
        properties: %{age: nil}
      }

      assert cast(value: %{}, schema: schema) == {:ok, %{}}
      assert cast(value: %{"age" => "hello"}, schema: schema) == {:ok, %{age: "hello"}}
    end

    test "unexpected field" do
      schema = %Schema{
        type: :object,
        properties: %{},
        additionalProperties: false
      }

      assert {:error, [error]} = cast(value: %{foo: "foo"}, schema: schema)
      assert %Error{} = error
      assert error.reason == :unexpected_field
      assert error.path == ["foo"]
    end

    test "required fields" do
      schema = %Schema{
        type: :object,
        properties: %{age: %Schema{type: :integer}, name: %Schema{type: :string}},
        required: [:age, :name]
      }

      assert {:error, [error, error2]} = cast(value: %{}, schema: schema)
      assert %Error{} = error
      assert error.reason == :missing_field
      assert error.name == :age
      assert error.path == [:age]

      assert error2.reason == :missing_field
      assert error2.name == :name
      assert error2.path == [:name]
    end

    @test_cases [
      %{schema: [readOnly: true], read_write_scope: :write, result: :ok},
      %{schema: [writeOnly: true], read_write_scope: :read, result: :ok},
      %{schema: [readOnly: true], read_write_scope: nil, result: :error},
      %{schema: [writeOnly: true], read_write_scope: nil, result: :error}
    ]

    for test_case <- @test_cases do
      @schema_attrs test_case.schema
      @read_write_scope test_case.read_write_scope
      @expected_result test_case.result

      test "required, schema:#{inspect(@schema_attrs)}, read_write_scope:#{inspect(@read_write_scope)}" do
        object_schema = %Schema{
          type: :object,
          properties: %{name: struct!(Schema, @schema_attrs)},
          required: [:name]
        }

        cast_ctx = %Cast{
          value: %{},
          schema: object_schema,
          read_write_scope: @read_write_scope
        }

        assert {result, _} = cast(cast_ctx)

        assert result == @expected_result
      end
    end

    test "fields with default values" do
      schema = %Schema{
        type: :object,
        properties: %{name: %Schema{type: :string, default: "Rubi"}}
      }

      assert cast(value: %{}, schema: schema) == {:ok, %{name: "Rubi"}}
      assert cast(value: %{"name" => "Jane"}, schema: schema) == {:ok, %{name: "Jane"}}
      assert cast(value: %{name: "Robin"}, schema: schema) == {:ok, %{name: "Robin"}}
    end

    test "fields with default values and apply_defaults config" do
      schema = %Schema{
        type: :object,
        properties: %{name: %Schema{type: :string, default: "Rubi"}}
      }

      assert cast(value: %{}, schema: schema, opts: [apply_defaults: true]) ==
               {:ok, %{name: "Rubi"}}

      assert cast(value: %{}, schema: schema, opts: [apply_defaults: false]) == {:ok, %{}}
    end

    test "explicitly passing nil for fields with default values (not nullable)" do
      schema = %Schema{
        type: :object,
        properties: %{name: %Schema{type: :string, default: "Rubi"}}
      }

      assert {:error, [%{reason: :null_value}]} = cast(value: %{"name" => nil}, schema: schema)
      assert {:error, [%{reason: :null_value}]} = cast(value: %{name: nil}, schema: schema)
    end

    test "explicitly passing nil for fields with default values (nullable)" do
      schema = %Schema{
        type: :object,
        properties: %{name: %Schema{type: :string, default: "Rubi", nullable: true}}
      }

      assert cast(value: %{"name" => nil}, schema: schema) == {:ok, %{name: nil}}
      assert cast(value: %{name: nil}, schema: schema) == {:ok, %{name: nil}}
    end

    test "default values in nested schemas" do
      child_schema = %Schema{
        type: :object,
        properties: %{name: %Schema{type: :string, default: "Rubi"}}
      }

      parent_schema = %Schema{
        type: :object,
        properties: %{child: child_schema}
      }

      assert cast(value: %{child: %{}}, schema: parent_schema) == {:ok, %{child: %{name: "Rubi"}}}

      assert cast(value: %{child: %{"name" => "Jane"}}, schema: parent_schema) ==
               {:ok, %{child: %{name: "Jane"}}}
    end

    test "cast property against schema" do
      schema = %Schema{
        type: :object,
        properties: %{age: %Schema{type: :integer}}
      }

      assert cast(value: %{}, schema: schema) == {:ok, %{}}
      assert {:error, [error]} = cast(value: %{"age" => "hello"}, schema: schema)
      assert %Error{} = error
      assert error.reason == :invalid_type
      assert error.path == [:age]
    end

    test "allow unrecognized fields when additionalProperties is true" do
      schema = %Schema{
        type: :object,
        properties: %{},
        additionalProperties: true
      }

      assert cast(value: %{"foo" => "foo"}, schema: schema) == {:ok, %{"foo" => "foo"}}
    end

    test "allow unrecognized fields when additionalProperties is nil" do
      schema = %Schema{
        type: :object,
        properties: %{},
        additionalProperties: nil
      }

      assert cast(value: %{"foo" => "foo"}, schema: schema) == {:ok, %{"foo" => "foo"}}
    end

    test "casts additional properties according to the additionalProperty schema" do
      schema = %Schema{
        type: :object,
        properties: %{},
        additionalProperties: %Schema{
          type: :object,
          properties: %{
            age: %Schema{type: :integer}
          }
        }
      }

      input = %{"alex" => %{"age" => 42}, "brian" => %{"age" => 43}}

      assert cast(value: input, schema: schema) ==
               {:ok, %{"alex" => %{age: 42}, "brian" => %{age: 43}}}
    end

    test "when additionalProperty schema does not work out" do
      schema = %Schema{
        type: :object,
        properties: %{},
        additionalProperties: %Schema{
          type: :object,
          properties: %{},
          additionalProperties: %Schema{type: :integer}
        }
      }

      input = %{"alex" => %{"age" => 5, "size" => 5}, "brian" => %{"age" => 6, "size" => "tall"}}

      assert {:error, [%{path: ["brian", "size"], reason: :invalid_type}]} =
               cast(value: input, schema: schema)
    end

    test "additionalProperties are casted and validated when properties is nil" do
      schema = %Schema{
        type: :object,
        properties: nil,
        additionalProperties: %Schema{
          type: :object,
          properties: %{
            age: %Schema{type: :integer},
            name: %Schema{type: :string}
          },
          required: [:age, :name]
        }
      }

      input = %{"alex" => %{"name" => "Joe"}}

      assert {:error,
              [
                %{
                  name: :age,
                  path: ["alex", :age],
                  reason: :missing_field
                }
              ]} = cast(value: input, schema: schema)
    end

    test "when additionalProperties schema is a reference" do
      age_schema = %Schema{type: :integer}

      schema = %Schema{
        type: :object,
        properties: %{},
        additionalProperties: %Reference{"$ref": "#/components/schemas/Age"}
      }

      input = %{"age" => "20"}

      assert cast(
               value: input,
               schema: schema,
               schemas: %{"Age" => age_schema}
             ) == {:ok, %{"age" => 20}}
    end

    test "when additionalProperties schema is a object with nested reference" do
      nested_schema = %Schema{
        type: :object,
        properties: %{
          age: %Reference{"$ref": "#/components/schemas/Age"}
        }
      }

      age_schema = %Schema{type: :integer}

      schema = %Schema{
        type: :object,
        properties: %{},
        additionalProperties: %Reference{"$ref": "#/components/schemas/NestedSchema"}
      }

      input = %{"nested" => %{"age" => "20"}}

      assert cast(
               value: input,
               schema: schema,
               schemas: %{"Age" => age_schema, "NestedSchema" => nested_schema}
             ) == {:ok, %{"nested" => %{age: 20}}}
    end

    defmodule User do
      defstruct [:name]
    end

    test "optionally casts to struct" do
      schema = %Schema{
        type: :object,
        "x-struct": User,
        properties: %{
          name: %Schema{type: :string}
        }
      }

      assert {:ok, user} = cast(value: %{"name" => "Name"}, schema: schema)
      assert user == %User{name: "Name"}
    end

    test "casts to struct even if input was a different struct" do
      schema = %Schema{
        type: :object,
        "x-struct": User,
        properties: %{
          name: %Schema{type: :string}
        }
      }

      assert {:ok, user} = cast(value: %User2{name: "Name"}, schema: schema)
      assert user == %User{name: "Name"}
    end

    test "original struct is preserved if no x-struct is specified" do
      schema = %Schema{
        type: :object,
        properties: %{
          name: %Schema{type: :string}
        }
      }

      assert {:ok, user} = cast(value: %User{name: "Name"}, schema: schema)
      assert user == %User{name: "Name"}
    end

    test "validates maxProperties" do
      schema = %Schema{
        type: :object,
        properties: %{
          one: nil,
          two: nil
        },
        maxProperties: 1
      }

      assert {:error, [error]} = cast(value: %{one: "one", two: "two"}, schema: schema)
      assert %Error{} = error
      assert error.reason == :max_properties

      assert {:ok, _} = cast(value: %{one: "one"}, schema: schema)
    end

    test "validates minProperties" do
      schema = %Schema{
        type: :object,
        properties: %{
          one: nil,
          two: nil
        },
        minProperties: 1
      }

      assert {:error, [error]} = cast(value: %{}, schema: schema)
      assert %Error{} = error
      assert error.reason == :min_properties

      assert {:ok, _} = cast(value: %{one: "one"}, schema: schema)
    end

    test "return all cast properties errors" do
      schema = %Schema{
        type: :object,
        properties: %{
          name: %Schema{type: :string, minLength: 3},
          age: %Schema{type: :integer, minimum: 16}
        }
      }

      assert {:error, [_error1, _error2] = errors} =
               cast(value: %{"age" => 0, "name" => "N"}, schema: schema)

      error1 = Enum.find(errors, &(&1.path == [:age]))
      error2 = Enum.find(errors, &(&1.path == [:name]))

      assert %Error{} = error1
      assert error1.reason == :minimum
      assert error1.path == [:age]

      assert %Error{} = error2
      assert error2.reason == :min_length
      assert error2.path == [:name]
    end
  end
end
