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
      cast_context = %Cast{value: 1.100, schema: schema}

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

  describe "assert_raw_schema/3" do
    test "success" do
      schema = %Schema{
        type: :object,
        properties: %{
          name: %Schema{type: :string}
        }
      }

      TestAssertions.assert_raw_schema(%{name: "valid"}, schema, %{})
    end

    test "failure" do
      schema = %Schema{
        type: :object,
        properties: %{
          name: %Schema{type: :string}
        }
      }

      try do
        TestAssertions.assert_raw_schema(%{name: 1234}, schema, %{})
        raise RuntimeError, "Should flunk"
      rescue
        e in ExUnit.AssertionError ->
          assert e.message =~ "Value does not conform to schema"
      end
    end
  end

  describe "assert_operation_response/2" do
    test "success with a manually specified operationId" do
      conn =
        :get
        |> Plug.Test.conn("/api/pets")
        |> Plug.Conn.put_req_header("content-type", "application/json")

      conn = OpenApiSpexTest.Router.call(conn, [])

      assert conn.status == 200
      TestAssertions.assert_operation_response(conn, "listPets")
    end

    test "success with only conn" do
      conn =
        :get
        |> Plug.Test.conn("/api/pets")
        |> Plug.Conn.put_req_header("content-type", "application/json")

      conn = OpenApiSpexTest.Router.call(conn, [])

      assert conn.status == 200
      TestAssertions.assert_operation_response(conn)
    end

    test "missing operation id" do
      conn =
        :get
        |> Plug.Test.conn("/api/openapi")
        |> Plug.Conn.put_req_header("content-type", "application/json")

      conn = OpenApiSpexTest.Router.call(conn, [])
      assert conn.status == 200

      assert_raise(
        ExUnit.AssertionError,
        ~r/Failed to resolve a response schema for operation_id: not_a_real_operation_id for status code: 200/,
        fn -> TestAssertions.assert_operation_response(conn, "not_a_real_operation_id") end
      )
    end

    test "invalid schema" do
      conn =
        :get
        |> Plug.Test.conn("/api/pets")
        |> Plug.Conn.put_req_header("content-type", "application/json")

      conn = OpenApiSpexTest.Router.call(conn, [])

      assert conn.status == 200

      assert_raise(
        ExUnit.AssertionError,
        ~r/Value does not conform to schema PetResponse: Failed to cast value to one of: no schemas validate at/,
        fn -> TestAssertions.assert_operation_response(conn, "showPetById") end
      )
    end

    test "returns an error when the response content-type does not match the schema" do
      conn =
        :get
        |> Plug.Test.conn("/api/pets")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.put_resp_header("content-type", "unexpected-content-type")

      conn = OpenApiSpexTest.Router.call(conn, [])

      assert conn.status == 200

      assert_raise(
        ExUnit.AssertionError,
        ~r/Failed to resolve a response schema for operation_id: showPetById for status code: 200 and content type: unexpected-content-type/,
        fn -> TestAssertions.assert_operation_response(conn, "showPetById") end
      )
    end
  end
end
