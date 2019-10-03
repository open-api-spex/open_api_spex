defmodule OpenApiSpex.CastAllOfTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, Schema}
  alias OpenApiSpex.Cast.{Error, AllOf}
  alias OpenApiSpex.Test.Assertions2

  defp cast(ctx), do: AllOf.cast(struct(Cast, ctx))

  describe "cast/1" do
    test "allOf" do
      schema = %Schema{allOf: [%Schema{type: :integer}, %Schema{type: :string}]}
      assert {:ok, 1} = cast(value: "1", schema: schema)
    end

    test "allOf, uncastable schema" do
      schema = %Schema{allOf: [%Schema{type: :integer}, %Schema{type: :string}]}
      assert {:error, [error]} = cast(value: [:whoops], schema: schema)

      assert Error.message(error) ==
               "Failed to cast value as integer. Value must be castable using `allOf` schemas listed."

      schema_with_title = %Schema{allOf: [%Schema{title: "Age", type: :integer}]}

      assert {:error, [error_with_schema_title]} =
               cast(value: [:nopes], schema: schema_with_title)

      assert Error.message(error_with_schema_title) ==
               "Failed to cast value as Age. Value must be castable using `allOf` schemas listed."
    end

    test "a more sophisticated example" do
      dog = %{"bark" => "woof", "pet_type" => "Dog"}
      Assertions2.assert_schema(dog, "Dog", OpenApiSpexTest.ApiSpec.spec())
    end
  end
end
