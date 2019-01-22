defmodule OpenApiSpex.CastOneOfTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, Schema}
  alias OpenApiSpex.Cast.{Error, OneOf}

  defp cast(ctx), do: OneOf.cast(struct(Cast, ctx))

  describe "cast/1" do
    test "oneOf" do
      schema = %Schema{oneOf: [%Schema{type: :integer}, %Schema{type: :string}]}
      assert {:ok, "hello"} = cast(value: "hello", schema: schema)
    end

    test "oneOf, more than one matching schema" do
      schema = %Schema{oneOf: [%Schema{type: :integer}, %Schema{type: :string}]}
      assert {:error, [error]} = cast(value: "1", schema: schema)
      assert error.reason == :one_of

      assert Error.message(error) ==
               "Failed to cast value to one of: Schema(type: :string), Schema(type: :integer)"
    end

    test "oneOf, no castable schema" do
      schema = %Schema{oneOf: [%Schema{type: :string}]}
      assert {:error, [error]} = cast(value: 1, schema: schema)
      assert error.reason == :one_of

      assert Error.message(error) == "Failed to cast value to one of: [] (no schemas provided)"
    end
  end
end
