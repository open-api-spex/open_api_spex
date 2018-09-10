defmodule ParamTest do
  use ExUnit.Case

  describe "Param" do
    test "Valid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/users?validParam=true")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
    end

    test "Invalid value" do
      conn =
        :get
        |> Plug.Test.conn("/api/users?validParam=123")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 422
    end

    test "Invalid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/users?validParam=123&inValidParam=123&inValid2=hi")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 422
      assert conn.resp_body == "Undefined query parameter: \"inValid2\""
    end
  end

  describe "Param with custom error handling" do
    test "Valid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/custom_error_users?validParam=true")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
    end

    test "Invalid value" do
      conn =
        :get
        |> Plug.Test.conn("/api/custom_error_users?validParam=123")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 400
    end

    test "Invalid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/custom_error_users?validParam=123&inValidParam=123&inValid2=hi")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 400
      assert conn.resp_body == "Undefined query parameter: \"inValid2\""
    end
  end

end
