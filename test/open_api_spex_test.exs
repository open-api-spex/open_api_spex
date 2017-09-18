defmodule OpenApiSpexTest do
  use ExUnit.Case
  alias OpenApiSpexTest.ApiSpec

  describe "OpenApi" do
    test "compete" do
      spec = ApiSpec.spec()
      assert spec
    end

    test "asdfafd" do
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
        |> Plug.Conn.put_req_header("content-type", "application/json")

      conn = OpenApiSpexTest.Router.call(conn, [])
      assert conn.params == %{
        user: %{
          id: 123,
          name: "asdf",
          email: "foo@bar.com",
          updated_at: ~N[2017-09-12T14:44:55Z] |> DateTime.from_naive!("Etc/UTC")
        }
      }
    end
  end
end