defmodule OpenApiSpex.CastAnyOfTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, Schema}
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

    test "no castable schema" do
      schema = %Schema{anyOf: [%Schema{type: :integer}, %Schema{type: :string}]}
      assert {:error, [error]} = cast(value: [:whoops], schema: schema)

      assert Error.message(error) ==
               "Failed to cast value using any of: Schema(type: :string), Schema(type: :integer)"

      schema_with_title = %Schema{anyOf: [%Schema{title: "Age", type: :integer}]}
      assert {:error, [error_with_schema_title]} = cast(value: [], schema: schema_with_title)

      assert Error.message(error_with_schema_title) ==
               "Failed to cast value using any of: Schema(title: \"Age\", type: :integer)"
    end

    test "empty list" do
      schema = %Schema{anyOf: [], title: "MyCoolSchema"}
      assert {:error, [error]} = cast(value: "jello", schema: schema)
      assert error.reason == :any_of

      assert Error.message(error) == "Failed to cast value using any of: [] (no schemas provided)"
    end
  end
end
