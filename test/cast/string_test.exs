defmodule OpenApiSpex.CastStringTest do
  use ExUnit.Case
  alias OpenApiSpex.{Cast, Schema}
  alias OpenApiSpex.Cast.{Error, String}

  defp cast(ctx), do: String.cast(struct(Cast, ctx))

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

    test "string with format (date time)" do
      schema = %Schema{type: :string, format: :"date-time"}
      time_string = DateTime.utc_now() |> DateTime.to_string()
      assert {:ok, %DateTime{}} = cast(value: time_string, schema: schema)
      assert {:error, [error]} = cast(value: "hello", schema: schema)
      assert error.reason == :invalid_format
      assert error.value == "hello"
      assert error.format == :"date-time"
    end

    test "string with format (date)" do
      schema = %Schema{type: :string, format: :date}
      date_string = DateTime.utc_now() |> DateTime.to_date() |> Date.to_string()
      assert {:ok, %Date{}} = cast(value: date_string, schema: schema)
      assert {:error, [error]} = cast(value: "hello", schema: schema)
      assert error.reason == :invalid_format
      assert error.value == "hello"
      assert error.format == :date
    end

    test "file upload" do
      schema = %Schema{type: :string, format: :binary}
      upload = %Plug.Upload{}
      assert {:ok, %Plug.Upload{}} = cast(value: upload, schema: schema)
      # There is no error case when a regular string is passed
    end

    # Note: we measure length of string after trimming leading and trailing whitespace
    test "minLength" do
      schema = %Schema{type: :string, minLength: 1}
      assert {:ok, "a"} = cast(value: "a", schema: schema)
      assert {:error, [error]} = cast(value: "", schema: schema)
      assert %Error{} = error
      assert error.reason == :min_length
    end

    # Note: we measure length of string after trimming leading and trailing whitespace
    test "maxLength" do
      schema = %Schema{type: :string, maxLength: 1}
      assert {:ok, "a"} = cast(value: "a", schema: schema)
      assert {:error, [error]} = cast(value: "aa", schema: schema)
      assert %Error{} = error
      assert error.reason == :max_length
    end

    test "maxLength and minLength" do
      schema = %Schema{type: :string, minLength: 1, maxLength: 2}
      assert {:error, [error]} = cast(value: "", schema: schema)
      assert %Error{} = error
      assert error.reason == :min_length
      assert {:error, [error]} = cast(value: "aaa", schema: schema)
      assert %Error{} = error
      assert error.reason == :max_length
    end

    test "minLength and pattern" do
      schema = %Schema{type: :string, minLength: 1, pattern: ~r/\d-\d/}
      assert {:error, errors} = cast(value: "", schema: schema)
      assert length(errors) == 2
      assert Enum.map(errors, & &1.reason) == [:invalid_format, :min_length]
    end
  end
end
