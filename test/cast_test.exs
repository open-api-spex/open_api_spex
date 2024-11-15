defmodule OpenApiSpec.CastTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, Schema, Reference}
  alias OpenApiSpex.Cast.Error
  doctest OpenApiSpex.Cast

  def cast(ctx), do: Cast.cast(ctx)

  describe "cast/1" do
    test "unknown schema type" do
      assert {:error, [error]} = cast(value: "string", schema: %Schema{type: :nope})
      assert error.reason == :invalid_schema_type
      assert error.type == :nope

      assert {:ok, "string"} = cast(value: "string", schema: %Schema{type: nil})
    end

    # Note: full tests for primitives are covered in Cast.PrimitiveTest
    test "primitives" do
      tests = [
        {:string, "1", :ok},
        {:string, "", :ok},
        {:string, true, :invalid},
        {:string, nil, :invalid},
        {:integer, 1, :ok},
        {:integer, "1", :ok},
        {:integer, %{}, :invalid},
        {:integer, nil, :invalid},
        {:array, nil, :invalid},
        {:object, nil, :invalid}
      ]

      for {type, input, expected} <- tests do
        case expected do
          :ok -> assert {:ok, _} = cast(value: input, schema: %Schema{type: type})
          :invalid -> assert {:error, _} = cast(value: input, schema: %Schema{type: type})
        end
      end
    end

    test "array type, nullable, given nil" do
      schema = %Schema{type: :array, nullable: true}
      assert {:ok, nil} = cast(value: nil, schema: schema)
    end

    test "array type, given nil" do
      schema = %Schema{type: :array}
      assert {:error, [error]} = cast(value: nil, schema: schema)
      assert error.reason == :null_value
      assert Error.message_with_path(error) == "#: null value where array expected"
    end

    test "array" do
      schema = %Schema{type: :array}
      assert cast(value: [], schema: schema) == {:ok, []}
      assert cast(value: [1, 2, 3], schema: schema) == {:ok, [1, 2, 3]}
      assert cast(value: ["1", "2", "3"], schema: schema) == {:ok, ["1", "2", "3"]}

      assert {:error, [error]} = cast(value: %{}, schema: schema)
      assert %Error{} = error
      assert error.reason == :invalid_type
      assert error.value == %{}
    end

    test "array with items schema" do
      items_schema = %Schema{type: :integer}
      schema = %Schema{type: :array, items: items_schema}
      assert cast(value: [], schema: schema) == {:ok, []}
      assert cast(value: [1, 2, 3], schema: schema) == {:ok, [1, 2, 3]}
      assert cast(value: ["1", "2", "3"], schema: schema) == {:ok, [1, 2, 3]}

      assert {:error, errors} = cast(value: [1, "two"], schema: schema)
      assert [%Error{} = error] = errors
      assert error.reason == :invalid_type
      assert error.value == "two"
      assert error.path == [1]
    end

    # Additional object tests found in Cast.ObjectTest
    test "object with schema properties set, given known input property" do
      schema = %Schema{
        type: :object,
        properties: %{age: nil}
      }

      assert cast(value: %{}, schema: schema) == {:ok, %{}}
      assert cast(value: %{"age" => "hello"}, schema: schema) == {:ok, %{age: "hello"}}
    end

    test "reference" do
      age_schema = %Schema{type: :integer}

      assert cast(
               value: "20",
               schema: %Reference{"$ref": "#/components/schemas/Age"},
               schemas: %{"Age" => age_schema}
             ) == {:ok, 20}
    end

    test "reference nested in object" do
      age_schema = %Schema{type: :integer}

      schema = %Schema{
        type: :object,
        properties: %{
          age: %Reference{"$ref": "#/components/schemas/Age"}
        }
      }

      assert cast(
               value: %{"age" => "20"},
               schema: schema,
               schemas: %{"Age" => age_schema}
             ) == {:ok, %{age: 20}}
    end

    test "paths" do
      schema = %Schema{
        type: :object,
        properties: %{
          age: %Schema{type: :integer}
        }
      }

      assert {:error, errors} = cast(value: %{"age" => "twenty"}, schema: schema)
      assert [error] = errors
      assert %Error{} = error
      assert error.path == [:age]
    end

    test "nested paths" do
      schema = %Schema{
        type: :object,
        properties: %{
          data: %Schema{
            type: :object,
            properties: %{
              age: %Schema{type: :integer}
            }
          }
        }
      }

      assert {:error, errors} = cast(value: %{"data" => %{"age" => "twenty"}}, schema: schema)
      assert [error] = errors
      assert %Error{} = error
      assert error.path == [:data, :age]
      assert Error.message_with_path(error) == "#/data/age: Invalid integer. Got: string"
    end

    test "paths involving arrays" do
      schema = %Schema{
        type: :object,
        properties: %{
          data: %Schema{
            type: :array,
            items: %Schema{
              type: :object,
              properties: %{
                age: %Schema{type: :integer}
              }
            }
          }
        }
      }

      assert {:error, errors} =
               cast(value: %{"data" => [%{"age" => "20"}, %{"age" => "twenty"}]}, schema: schema)

      assert [error] = errors
      assert %Error{} = error
      assert error.path == [:data, 1, :age]
      assert Error.message_with_path(error) == "#/data/1/age: Invalid integer. Got: string"
    end

    test "multiple errors" do
      schema = %Schema{
        type: :array,
        items: %Schema{type: :integer}
      }

      value = [1, "two", 3, "four"]
      assert {:error, errors} = cast(value: value, schema: schema)
      assert [error, error2] = errors
      assert %Error{} = error
      assert error.reason == :invalid_type
      assert error.path == [1]
      assert Error.message_with_path(error) == "#/1: Invalid integer. Got: string"

      assert Error.message_with_path(error2) == "#/3: Invalid integer. Got: string"
    end

    test "cast schema error with custom validator" do
      defmodule StrictInt do
        require OpenApiSpex

        alias OpenApiSpex.Cast

        OpenApiSpex.schema(%{
          description: "Strictly an integer",
          type: :integer,
          "x-validate": __MODULE__
        })

        def cast(context = %Cast{value: value}) when is_integer(value),
          do: Cast.ok(context)

        def cast(context),
          do: Cast.error(context, {:invalid_type, :strict_integer})
      end

      schema = %Schema{
        type: :object,
        properties: %{age: StrictInt.schema()}
      }

      assert {:error, errors} = cast(value: %{"age" => "83"}, schema: schema)
      assert [error] = errors
      assert %Error{} = error
      assert error.reason == :invalid_type
      assert error.path == [:age]
      assert Error.message_with_path(error) == "#/age: Invalid strict_integer. Got: string"
    end

    test "cast custom error with custom validator" do
      defmodule EvenInt do
        require OpenApiSpex

        alias OpenApiSpex.Cast

        OpenApiSpex.schema(%{
          description: "An even integer",
          type: :integer,
          "x-validate": __MODULE__
        })

        def cast(context = %Cast{value: value}) when is_integer(value) and rem(value, 2) == 0,
          do: Cast.ok(context)

        def cast(context), do: Cast.error(context, {:custom, "Must be an even integer"})
      end

      schema = %Schema{type: :object, properties: %{even_number: EvenInt.schema()}}

      assert {:error, errors} = cast(value: %{"even_number" => 1}, schema: schema)
      assert [error] = errors
      assert %Error{} = error
      assert error.reason == :custom
      assert error.path == [:even_number]
      assert Error.message_with_path(error) == "#/even_number: Must be an even integer"
    end

    test "nil value with xxxOf" do
      schema = %Schema{anyOf: [%Schema{nullable: true, type: :string}]}
      assert {:ok, nil} = cast(value: nil, schema: schema)

      schema = %Schema{allOf: [%Schema{nullable: true, type: :string}]}
      assert {:ok, nil} = cast(value: nil, schema: schema)

      schema = %Schema{oneOf: [%Schema{nullable: true, type: :string}]}
      assert {:ok, nil} = cast(value: nil, schema: schema)
    end

    test "apply defaults configuration" do
      schema = %Schema{
        type: :object,
        properties: %{
          data: %Schema{
            type: :string,
            default: "default"
          }
        }
      }

      assert {:ok, %{}} == cast(value: %{}, schema: schema, opts: [apply_defaults: false])

      assert {:ok, %{data: "default"}} ==
               cast(value: %{}, schema: schema, opts: [apply_defaults: true])

      assert {:ok, %{data: "default"}} == cast(value: %{}, schema: schema)
    end
  end

  describe "opts" do
    test "read_write_scope" do
      schema = %Schema{
        type: :object,
        properties: %{
          id: %Schema{type: :string, readOnly: true},
          name: %Reference{"$ref": "#/components/schemas/Name"},
          age: %Schema{type: :integer}
        },
        required: [:id, :name, :age]
      }

      schemas = %{"Name" => %Schema{type: :string, readOnly: true}}

      value = %{"age" => 30}
      assert {:error, _} = Cast.cast(schema, value, schemas, [])
      assert {:ok, %{age: 30}} == Cast.cast(schema, value, schemas, read_write_scope: :write)
    end
  end

  describe "ok/1" do
    test "basics" do
      assert {:ok, 1} = Cast.ok(%Cast{value: 1})
    end
  end

  describe "success/2" do
    test "nils out property" do
      schema = %Schema{minimum: 1}
      ctx = %Cast{schema: schema}
      expected = {:cast, %Cast{schema: %Schema{minimum: nil}}}

      assert expected == Cast.success(ctx, :minimum)
    end

    test "nils out properties" do
      schema = %Schema{minimum: %Schema.MinMax{value: 1, exclusive?: true}}
      ctx = %Cast{schema: schema}
      expected = {:cast, %Cast{schema: %Schema{minimum: nil}}}

      assert expected == Cast.success(ctx, [:minimum])
    end
  end
end
