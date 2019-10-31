defmodule OpenApiSpex.Plug.CastTest do
  use ExUnit.Case

  describe "query params - basics" do
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
        |> Plug.Test.conn("/api/users?validParam=123")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 422
      error_resp = Jason.decode!(conn.resp_body)

      assert error_resp == %{
               "errors" => [
                 %{
                   "message" => "Invalid boolean. Got: string",
                   "source" => %{"pointer" => "/validParam"},
                   "title" => "Invalid value"
                 }
               ]
             }
    end

    test "with requestBody" do
      body =
        Jason.encode!(%{
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

  describe "query params - param with custom error handling" do
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
        |> Plug.Test.conn("/api/custom_error_users?validParam=123")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 400
      assert conn.resp_body == "Invalid boolean. Got: string"
    end
  end

  describe "body params" do
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
        |> Plug.Test.conn("/api/users", Jason.encode!(request_body))
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

      assert Jason.decode!(conn.resp_body) == %{
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
        |> Plug.Test.conn("/api/users", Jason.encode!(request_body))
        |> Plug.Conn.put_req_header("content-type", "application/json")

      conn = OpenApiSpexTest.Router.call(conn, [])
      assert conn.status == 422

      resp_data = Jason.decode!(conn.resp_body)

      assert resp_data ==
               %{
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

  describe "oneOf body params" do
    test "Valid Request" do
      request_body = %{
        "pet" => %{
          "pet_type" => "Dog",
          "bark" => "woof"
        }
      }

      conn =
        :post
        |> Plug.Test.conn("/api/pets", Jason.encode!(request_body))
        |> Plug.Conn.put_req_header("content-type", "application/json; charset=UTF-8")
        |> OpenApiSpexTest.Router.call([])

      assert conn.body_params == %OpenApiSpexTest.Schemas.PetRequest{
               pet: %OpenApiSpexTest.Schemas.Dog{
                 pet_type: "Dog",
                 bark: "woof"
               }
             }

      assert Jason.decode!(conn.resp_body) == %{
               "data" => %{
                 "pet_type" => "Dog",
                 "bark" => "woof"
               }
             }
    end

    @tag :capture_log
    test "Invalid Request" do
      request_body = %{
        "pet" => %{
          "pet_type" => "Human",
          "says" => "yes"
        }
      }

      conn =
        :post
        |> Plug.Test.conn("/api/pets", Jason.encode!(request_body))
        |> Plug.Conn.put_req_header("content-type", "application/json")

      conn = OpenApiSpexTest.Router.call(conn, [])
      assert conn.status == 422

      resp_body = Jason.decode!(conn.resp_body)

      assert resp_body == %{
               "errors" => [
                 %{
                   "source" => %{
                     "pointer" => "/pet"
                   },
                   "title" => "Invalid value",
                   "message" => "Failed to cast value to one of: [] (no schemas provided)"
                 }
               ]
             }
    end
  end
end
