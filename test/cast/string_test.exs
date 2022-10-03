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

    test "preserves atom values" do
      schema = %Schema{type: :string}

      assert cast(value: :hello, schema: schema) == {:ok, :hello}
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

    test "string with format (byte)" do
      schema = %Schema{type: :string, format: :byte}
      date_string = Base.encode64("hello")
      assert {:ok, "hello"} = cast(value: date_string, schema: schema)
      assert {:error, [error]} = cast(value: "not-a-base64-string", schema: schema)
      assert error.reason == :invalid_format
      assert error.value == "not-a-base64-string"
      assert error.format == :base64
    end

    test "casts a string with valid uuid format" do
      schema = %Schema{type: :string, format: :uuid}

      assert {:ok, "02ef9c5f-29e6-48fc-9ec3-7ed57ed351f6"} =
               cast(value: "02ef9c5f-29e6-48fc-9ec3-7ed57ed351f6", schema: schema)

      assert {:ok, "02EF9C5F-29E6-48FC-9EC3-7ED57ED351F6"} =
               cast(value: "02EF9C5F-29E6-48FC-9EC3-7ED57ED351F6", schema: schema)
    end

    test "returns a cast error with an invalid uuid string" do
      schema = %Schema{type: :string, format: :uuid}

      assert {:error, [%{reason: :invalid_format, value: "string", format: :uuid}]} =
               cast(value: "string", schema: schema)

      assert {:error,
              [
                %{
                  reason: :invalid_format,
                  value: "????????-$$$$-@@@@-9ec3-7ed57ed351f6",
                  format: :uuid
                }
              ]} = cast(value: "????????-$$$$-@@@@-9ec3-7ed57ed351f6", schema: schema)
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
      assert {:error, [%Error{reason: :max_length}]} = cast(value: "aa", schema: schema)

      assert {:ok, :a} = cast(value: :a, schema: schema)
      assert {:error, [%Error{reason: :max_length}]} = cast(value: :aa, schema: schema)
    end

    test "maxLength and minLength" do
      schema = %Schema{type: :string, minLength: 1, maxLength: 2}

      assert {:error, [%Error{reason: :min_length}]} = cast(value: "", schema: schema)
      assert {:error, [%Error{reason: :max_length}]} = cast(value: "aaa", schema: schema)

      assert {:error, [%Error{reason: :min_length}]} = cast(value: :"", schema: schema)
      assert {:error, [%Error{reason: :max_length}]} = cast(value: :aaa, schema: schema)
    end

    test "minLength and pattern" do
      schema = %Schema{type: :string, minLength: 1, pattern: ~r/\d-\d/}

      assert {:error, [%Error{reason: :invalid_format}, %Error{reason: :min_length}]} =
               cast(value: "", schema: schema)

      assert {:error, [%Error{reason: :invalid_format}, %Error{reason: :min_length}]} =
               cast(value: :"", schema: schema)
    end
  end
end
