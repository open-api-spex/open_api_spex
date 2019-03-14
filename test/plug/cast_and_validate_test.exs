defmodule OpenApiSpex.Plug.CastAndValidateTest do
  use ExUnit.Case, async: true

  describe "query params - basics" do
    test "Valid Param" do
      conn =
        :get
        |> Plug.Test.conn("/api/cast_and_validate_test/users?validParam=true")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
    end

    @tag :capture_log
    test "Invalid value" do
      conn =
        :get
        |> Plug.Test.conn("/api/cast_and_validate_test/users?validParam=123")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 422
    end

    @tag :capture_log
    test "Invalid Param" do
      conn =
        :get
        |> Plug.Test.conn(
          "/api/cast_and_validate_test/users?validParam=123&inValidParam=123&inValid2=hi"
        )
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 422

      assert conn.resp_body ==
               "{\"errors\":[{\"message\":\"Unexpected field: inValid2\",\"source\":{\"pointer\":\"/inValid2\"},\"title\":\"Invalid value\"}]}"
    end

    @tag :capture_log
    test "with requestBody" do
      body =
        Poison.encode!(%{
          phone_number: "123-456-789",
          postal_address: "123 Lane St"
        })

      conn =
        :post
        |> Plug.Test.conn("/api/cast_and_validate_test/users/123/contact_info", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
    end
  end

  describe "body params" do
    # TODO Fix this test. The datetime should be parsed, but it isn't.
    # https://github.com/open-api-spex/open_api_spex/issues/90
    @tag :skip
    test "Valid Request" do
      request_body = %{
        "user" => %{
          "id" => 123,
          "name" => "asdf",
          "email" => "foo@bar.com",
          "updated_at" => "2017-09-12T14:44:55Z"
        }
      }

      conn =
        :post
        |> Plug.Test.conn("/api/cast_and_validate_test/users", Poison.encode!(request_body))
        |> Plug.Conn.put_req_header("content-type", "application/json; charset=UTF-8")
        |> OpenApiSpexTest.Router.call([])

      assert conn.body_params == %OpenApiSpexTest.Schemas.UserRequest{
               user: %OpenApiSpexTest.Schemas.User{
                 id: 123,
                 name: "asdf",
                 email: "foo@bar.com",
                 updated_at: ~N[2017-09-12T14:44:55Z] |> DateTime.from_naive!("Etc/UTC")
               }
             }

      assert Poison.decode!(conn.resp_body) == %{
               "data" => %{
                 "email" => "foo@bar.com",
                 "id" => 1234,
                 "inserted_at" => nil,
                 "name" => "asdf",
                 "updated_at" => "2017-09-12T14:44:55Z"
               }
             }
    end

    @tag :capture_log
    test "Invalid Request" do
      request_body = %{
        "user" => %{
          "id" => 123,
          "name" => "*1234",
          "email" => "foo@bar.com",
          "updated_at" => "2017-09-12T14:44:55Z"
        }
      }

      conn =
        :post
        |> Plug.Test.conn("/api/cast_and_validate_test/users", Poison.encode!(request_body))
        |> Plug.Conn.put_req_header("content-type", "application/json")

      conn = OpenApiSpexTest.Router.call(conn, [])
      assert conn.status == 422

      resp_body = Poison.decode!(conn.resp_body)

      assert resp_body == %{
               "errors" => [
                 %{
                   "message" => "Invalid format. Expected ~r/[a-zA-Z][a-zA-Z0-9_]+/",
                   "source" => %{"pointer" => "/user/name"},
                   "title" => "Invalid value"
                 }
               ]
             }
    end
  end
end
