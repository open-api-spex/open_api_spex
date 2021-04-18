defmodule OpenApiSpex.TestAssertionsTest do
  use ExUnit.Case, async: true

  alias OpenApiSpex.{Cast, Schema, TestAssertions}
  alias OpenApiSpexTest.ApiSpec

  describe "assert_schema/1" do
    test "success" do
      schema = %Schema{type: :string}
      cast_context = %Cast{value: "hello", schema: schema}
      TestAssertions.assert_schema(cast_context)
    end

    test "failure" do
      schema = %Schema{type: :string}
      cast_context = %Cast{value: :nope, schema: schema}

      try do
        TestAssertions.assert_schema(cast_context)
        raise RuntimeError, "Should flunk"
      rescue
        e in ExUnit.AssertionError ->
          assert e.message =~ "Value does not conform to schema"
      end
    end

    test "required object property, but different read_write_scope" do
      schema = %Schema{
        type: :object,
        properties: %{publish: %Schema{type: :boolean, writeOnly: true}},
        required: [:publish]
      }

      value = %{}
      cast_context = %Cast{value: value, schema: schema, read_write_scope: :read}

      TestAssertions.assert_schema(cast_context)
    end
  end

  describe "assert_response_schema/3" do
    test "ignore required field when read_write_scope is different" do
      schema = %Schema{
        type: :object,
        title: "MySchema",
        properties: %{publish: %Schema{type: :boolean, writeOnly: true}},
        required: [:publish]
      }

      value = %{}
      api_spec = ApiSpec.empty_spec()
      api_spec = put_in(api_spec.components.schemas, %{schema.title => schema})

      TestAssertions.assert_response_schema(value, schema.title, api_spec)
    end
  end

  describe "assert_request_schema/3" do
    test "success" do
      schema = %Schema{type: :string}
      value = "hello"
      api_spec = ApiSpec.empty_spec()
      api_spec = put_in(api_spec.components.schemas, %{schema.title => schema})
      TestAssertions.assert_request_schema(value, schema.title, api_spec)
    end
  end
end
