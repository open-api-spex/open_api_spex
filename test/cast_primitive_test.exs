defmodule OpenApiSpex.CastPrimitiveTest do
  use ExUnit.Case
  alias OpenApiSpex.{CastContext, CastPrimitive, Error, Schema}

  defp cast(ctx), do: CastPrimitive.cast(struct(CastContext, ctx))

  describe "cast/3" do
    @types [:boolean, :integer, :number, :string]
    for type <- @types do
      @type_value type
      test "nil input for nullable:true, type:#{type}" do
        schema = %Schema{type: @type_value, nullable: true}
        assert cast(value: nil, schema: schema) == {:ok, nil}
      end

      test "nil input for nullable:false, type:#{type}" do
        schema = %Schema{type: @type_value, nullable: false}
        assert {:error, [error]} = cast(value: nil, schema: schema)
        assert %Error{} = error
        assert error.reason == :invalid_type
        assert error.value == nil
      end
    end

    test "boolean" do
      schema = %Schema{type: :boolean}
      assert cast(value: true, schema: schema) == {:ok, true}
      assert cast(value: false, schema: schema) == {:ok, false}
      assert cast(value: "true", schema: schema) == {:ok, true}
      assert cast(value: "false", schema: schema) == {:ok, false}
      assert {:error, [error]} = cast(value: "other", schema: schema)
      assert %Error{reason: :invalid_type} = error
      assert error.value == "other"
    end

    test "integer" do
      schema = %Schema{type: :integer}
      assert cast(value: 1, schema: schema) == {:ok, 1}
      assert cast(value: 1.5, schema: schema) == {:ok, 2}
      assert cast(value: "1", schema: schema) == {:ok, 1}
      assert cast(value: "1.5", schema: schema) == {:ok, 2}
      assert {:error, [error]} = cast(value: "other", schema: schema)
      assert %Error{reason: :invalid_type} = error
      assert error.value == "other"
    end

    test "number" do
      schema = %Schema{type: :number}
      assert cast(value: 1, schema: schema) == {:ok, 1.0}
      assert cast(value: 1.5, schema: schema) == {:ok, 1.5}
      assert cast(value: "1", schema: schema) == {:ok, 1.0}
      assert cast(value: "1.5", schema: schema) == {:ok, 1.5}
      assert {:error, [error]} = cast(value: "other", schema: schema)
      assert %Error{reason: :invalid_type} = error
      assert error.value == "other"
    end

    test "string" do
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
      assert {:error, error} = cast(value: "hello", schema: schema)
      assert error.reason == :invalid_format
      assert error.value == "hello"
      assert error.format == ~r/\d-\d/
    end
  end
end
