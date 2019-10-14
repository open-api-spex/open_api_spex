defmodule OpenApiSpex.Plug.CastAndValidate.CustomErrorUserControllerTest do
  use ExUnit.Case, async: true

  describe "query params - param with custom error handling" do
    test "Valid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/custom_error_users?validParam=true")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
    end

    @tag :capture_log
    test "Invalid value" do
      conn =
        :get
        |> Plug.Test.conn("/api/custom_error_users?validParam=123")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 400

      assert conn.resp_body == "Invalid boolean. Got: string"
    end

    @tag :capture_log
    test "Invalid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/custom_error_users?validParam=123&inValidParam=123&inValid2=hi")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 400
      assert conn.resp_body == "Unexpected field: inValid2"
    end
  end
end
