defmodule ParamTest do
  use ExUnit.Case

  describe "Param" do
    test "Valid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/users?validParam=true")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
    end

    test "Invalid value" do
      conn =
        :get
        |> Plug.Test.conn("/api/users?validParam=123")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 422
    end

    test "Invalid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/users?validParam=123&inValidParam=123&inValid2=hi")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 422
      assert conn.resp_body == "Undefined query parameter: \"inValid2\""
    end

    test "with requestBody" do
      body = Poison.encode!(%{
        phone_number: "123-456-789",
        postal_address: "123 Lane St"
      })

      conn =
        :post
        |> Plug.Test.conn("/api/users/123/contact_info", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
    end
  end

  describe "Param with custom error handling" do
    test "Valid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/custom_error_users?validParam=true")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
    end

    test "Invalid value" do
      conn =
        :get
        |> Plug.Test.conn("/api/custom_error_users?validParam=123")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 400
    end

    test "Invalid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/custom_error_users?validParam=123&inValidParam=123&inValid2=hi")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 400
      assert conn.resp_body == "Undefined query parameter: \"inValid2\""
    end
  end

end
