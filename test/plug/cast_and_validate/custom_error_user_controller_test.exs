defmodule OpenApiSpex.Plug.CastAndValidate.CustomErrorUserControllerTest do
  use ExUnit.Case, async: true

  describe "index - query params - param with custom error handling" do
    test "Valid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/cast_and_validate_test/custom_error_users?validParam=true")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
    end

    @tag :capture_log
    test "Invalid value" do
      conn =
        :get
        |> Plug.Test.conn("/api/cast_and_validate_test/custom_error_users?validParam=123")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 400

      assert conn.resp_body == "Invalid boolean. Got: string"
    end

    @tag :capture_log
    test "Invalid Param" do
      conn =
        :get
        |> Plug.Test.conn(
          "/api/cast_and_validate_test/custom_error_users?validParam=123&inValidParam=123&inValid2=hi"
        )
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 400
      assert conn.resp_body == "Unexpected field: inValid2"
    end
  end

  describe "create" do
    @tag :capture_log
    test "missing content-type when body is required" do
      body = "{}"

      conn =
        :post
        |> Plug.Test.conn("/api/cast_and_validate_test/custom_error_users", body)
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 400

      assert conn.resp_body == "missing_content_type"
    end

    @tag :capture_log
    test "validation error" do
      body = "{}"

      conn =
        :post
        |> Plug.Test.conn("/api/cast_and_validate_test/custom_error_users", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 400

      assert conn.resp_body == "Missing field: user"
    end

    test "happy path" do
      body = "{\"user\": {\"name\": \"Jane\", \"email\": \"test@example.com\"}}"

      conn =
        :post
        |> Plug.Test.conn("/api/cast_and_validate_test/custom_error_users", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 201

      assert conn.resp_body ==
               "{\"data\":[{\"updated_at\":null,\"name\":\"joe user\",\"inserted_at\":null,\"id\":123,\"email\":\"joe@gmail.com\"}]}"
    end
  end
end
