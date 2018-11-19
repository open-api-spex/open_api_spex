defmodule OpenApiSpex.CastStringTest do
  use ExUnit.Case
  alias OpenApiSpex.Cast.{Context, Error, String}
  alias OpenApiSpex.Schema

  defp cast(ctx), do: String.cast(struct(Context, ctx))

  describe "cast/1" do
    test "basics" do
      schema = %Schema{type: :string}
      assert cast(value: "hello", schema: schema) == {:ok, "hello"}
      assert cast(value: "", schema: schema) == {:ok, ""}
      assert {:error, [error]} = cast(value: %{}, schema: schema)
      assert %Error{reason: :invalid_type} = error
      assert error.value == %{}
    end

    test "string with pattern" do
      schema = %Schema{type: :string, pattern: ~r/\d-\d/}
      assert cast(value: "1-2", schema: schema) == {:ok, "1-2"}
      assert {:error, [error]} = cast(value: "hello", schema: schema)
      assert error.reason == :invalid_format
      assert error.value == "hello"
      assert error.format == ~r/\d-\d/
    end

    # Note: we measure length of string after trimming leading and trailing whitespace
    test "minLength" do
      schema = %Schema{type: :string, minLength: 1}
      assert {:error, [error]} = cast(value: "   ", schema: schema)
      assert %Error{} = error
      assert error.reason == :min_length
    end
  end
end
