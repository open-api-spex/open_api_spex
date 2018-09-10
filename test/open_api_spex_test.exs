defmodule OpenApiSpexTest do
  use ExUnit.Case
  alias OpenApiSpexTest.ApiSpec

  describe "OpenApi" do
    test "compete" do
      spec = ApiSpec.spec()
      assert spec
    end

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
        |> Plug.Test.conn("/api/users", Poison.encode!(request_body))
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
        |> Plug.Test.conn("/api/users", Poison.encode!(request_body))
        |> Plug.Conn.put_req_header("content-type", "application/json")

      conn = OpenApiSpexTest.Router.call(conn, [])
      assert conn.status == 422
      assert conn.resp_body == "#/user/name: Value does not match pattern: [a-zA-Z][a-zA-Z0-9_]+"
    end
  end
end
