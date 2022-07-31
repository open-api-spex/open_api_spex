defmodule OpenApiSpex.Plug.CastTest do
  use ExUnit.Case

  import OpenApiSpex.TestAssertions

  alias OpenApiSpexTest.ApiSpec

  describe "valid operation (not annotated)" do
    test "does not raise an error when the operation is nil set with the operation macro" do
      conn =
        :get
        |> Plug.Test.conn("/api/noapi")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
    end

    test "does not raise an error when the operation is nil set with the open_api_operation function" do
      conn =
        :get
        |> Plug.Test.conn("/api/noapi_with_struct")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
    end
  end

  describe "query params - basics" do
    test "valid param" do
      conn =
        :get
        |> Plug.Test.conn("/api/users?validParam=true")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
      assert conn.private.open_api_spex.params == conn.params

      assert OpenApiSpex.params(conn) == %{validParam: true}
    end

    test "valid param with replace_params false" do
      conn =
        :get
        |> Plug.Test.conn("/api/users_no_replace?validParam=true")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
      assert conn.private.open_api_spex.params == %{validParam: true}
      assert conn.params == %{"validParam" => "true"}

      assert OpenApiSpex.params(conn) == %{validParam: true}
    end

    @tag :capture_log
    test "invalid value" do
      conn =
        :get
        |> Plug.Test.conn("/api/users?validParam=123")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 422
    end

    @tag :capture_log
    test "invalid param" do
      conn =
        :get
        |> Plug.Test.conn("/api/users?validParam=123")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 422
      error_resp = Jason.decode!(conn.resp_body)
      assert %{"errors" => [error]} = error_resp

      assert error == %{
               "detail" => "Invalid boolean. Got: string",
               "source" => %{"pointer" => "/validParam"},
               "title" => "Invalid value"
             }
    end

    test "error response matches JsonErrorResponse" do
      api_spec = ApiSpec.spec()

      conn =
        :get
        |> Plug.Test.conn("/api/users?validParam=123")
        |> OpenApiSpexTest.Router.call([])

      error_resp = Jason.decode!(conn.resp_body)
      assert_schema(error_resp, "JsonErrorResponse", api_spec)
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

    test "reference params" do
      conn =
        :get
        |> Plug.Test.conn("/api/users/12/payment_details")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
      assert conn.private.open_api_spex.params == conn.params
    end
  end

  describe "query params - param with custom error handling" do
    test "valid param" do
      conn =
        :get
        |> Plug.Test.conn("/api/custom_error_users?validParam=true")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 200
      assert conn.private.open_api_spex.params == conn.params
    end

    @tag :capture_log
    test "invalid value" do
      conn =
        :get
        |> Plug.Test.conn("/api/custom_error_users?validParam=123")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 400
    end

    @tag :capture_log
    test "invalid param" do
      conn =
        :get
        |> Plug.Test.conn("/api/custom_error_users?validParam=123")
        |> OpenApiSpexTest.Router.call([])

      assert conn.status == 400
      assert conn.resp_body == "Invalid boolean. Got: string"
    end
  end

  describe "body params" do
    test "valid request" do
      request_body = %{
        "user" => %{
          "id" => 123,
          "name" => "asdf",
          "email" => "foo@bar.com",
          "password" => "0123456789",
          "updated_at" => "2017-09-12T14:44:55Z"
        }
      }

      casted_body = %OpenApiSpexTest.Schemas.UserRequest{
        user: %OpenApiSpexTest.Schemas.User{
          id: 123,
          name: "asdf",
          email: "foo@bar.com",
          password: "0123456789",
          updated_at: ~N[2017-09-12T14:44:55Z] |> DateTime.from_naive!("Etc/UTC")
        }
      }

      conn =
        :post
        |> Plug.Test.conn("/api/users", Jason.encode!(request_body))
        |> Plug.Conn.put_req_header("content-type", "application/json; charset=UTF-8")
        |> OpenApiSpexTest.Router.call([])

      assert conn.body_params == casted_body

      assert conn.private.open_api_spex.body_params == conn.body_params

      assert Jason.decode!(conn.resp_body) == %{
               "data" => %{
                 "email" => "foo@bar.com",
                 "id" => 1234,
                 "inserted_at" => nil,
                 "name" => "asdf",
                 "updated_at" => "2017-09-12T14:44:55Z",
                 "age" => nil
               }
             }

      assert OpenApiSpex.body_params(conn) == casted_body
    end

    @tag :capture_log
    test "invalid request" do
      request_body = %{
        "user" => %{
          "id" => 123,
          "name" => "*1234",
          "email" => "foo@bar.com",
          "password" => "0123456789",
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
      assert %{"errors" => [error]} = resp_data

      assert error == %{
               "detail" => "Invalid format. Expected ~r/[a-zA-Z][a-zA-Z0-9_]+/",
               "source" => %{"pointer" => "/user/name"},
               "title" => "Invalid value"
             }
    end

    test "valid request with replace_params false" do
      request_body = %{
        "user" => %{
          "id" => 123,
          "name" => "asdf",
          "email" => "foo@bar.com",
          "password" => "0123456789",
          "updated_at" => "2017-09-12T14:44:55Z"
        }
      }

      casted_body = %OpenApiSpexTest.Schemas.UserRequest{
        user: %OpenApiSpexTest.Schemas.User{
          id: 123,
          name: "asdf",
          email: "foo@bar.com",
          password: "0123456789",
          updated_at: ~N[2017-09-12T14:44:55Z] |> DateTime.from_naive!("Etc/UTC")
        }
      }

      conn =
        :post
        |> Plug.Test.conn("/api/users_no_replace", Jason.encode!(request_body))
        |> Plug.Conn.put_req_header("content-type", "application/json; charset=UTF-8")
        |> OpenApiSpexTest.Router.call([])

      assert conn.private.open_api_spex.body_params == casted_body

      assert conn.body_params == request_body

      assert Jason.decode!(conn.resp_body) == %{
               "data" => %{
                 "email" => "foo@bar.com",
                 "id" => 1234,
                 "inserted_at" => nil,
                 "name" => "asdf",
                 "updated_at" => "2017-09-12T14:44:55Z",
                 "age" => nil
               }
             }

      assert OpenApiSpex.body_params(conn) == casted_body
    end
  end

  describe "oneOf body params" do
    test "valid request" do
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

      assert conn.private.open_api_spex.body_params == conn.body_params

      assert Jason.decode!(conn.resp_body) == %{
               "data" => %{
                 "pet_type" => "Dog",
                 "bark" => "woof"
               }
             }
    end

    @tag :capture_log
    test "invalid request" do
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
      assert %{"errors" => errors} = resp_body

      assert errors == [
               %{
                 "detail" => "Failed to cast value to one of: no schemas validate",
                 "source" => %{"pointer" => "/pet"},
                 "title" => "Invalid value"
               },
               %{
                 "detail" =>
                   "Failed to cast value as object. Value must be castable using `allOf` schemas listed.",
                 "source" => %{"pointer" => "/pet"},
                 "title" => "Invalid value"
               },
               %{
                 "detail" => "Missing field: meow",
                 "source" => %{"pointer" => "/pet/meow"},
                 "title" => "Invalid value"
               },
               %{
                 "detail" =>
                   "Failed to cast value as object. Value must be castable using `allOf` schemas listed.",
                 "source" => %{"pointer" => "/pet"},
                 "title" => "Invalid value"
               },
               %{
                 "detail" => "Missing field: bark",
                 "source" => %{"pointer" => "/pet/bark"},
                 "title" => "Invalid value"
               }
             ]
    end

    test "header params" do
      conn =
        :post
        |> Plug.Test.conn("/api/pets/1/adopt")
        |> Plug.Conn.put_req_header("content-type", "application/json; charset=UTF-8")
        |> Plug.Conn.put_req_header("x-user-id", "123456")
        |> OpenApiSpexTest.Router.call([])

      assert Jason.decode!(conn.resp_body) == %{
               "data" => %{
                 "pet_type" => "Dog",
                 "bark" => "woof"
               }
             }
    end

    test "optional param" do
      conn =
        :post
        |> Plug.Test.conn("/api/pets/1/adopt?status=adopted")
        |> Plug.Conn.put_req_header("content-type", "application/json; charset=UTF-8")
        |> Plug.Conn.put_req_header("x-user-id", "123456")
        |> OpenApiSpexTest.Router.call([])

      assert Jason.decode!(conn.resp_body) == %{
               "data" => %{
                 "pet_type" => "Dog",
                 "bark" => "woof"
               }
             }
    end

    test "cookie params" do
      conn =
        :post
        |> Plug.Test.conn("/api/pets/1/adopt")
        |> Plug.Conn.put_req_header("content-type", "application/json; charset=UTF-8")
        |> Plug.Conn.put_req_header("x-user-id", "123456")
        |> Plug.Conn.put_req_header("cookie", "debug=1")
        |> OpenApiSpexTest.Router.call([])

      assert Jason.decode!(conn.resp_body) == %{
               "data" => %{
                 "pet_type" => "Debug-Dog",
                 "bark" => "woof"
               }
             }
    end

    test "discriminator with mapping" do
      body =
        Jason.encode!(%{
          appointment_type: "grooming",
          hair_trim: true,
          nail_clip: false
        })

      conn =
        :post
        |> Plug.Test.conn("/api/pets/appointment", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> OpenApiSpexTest.Router.call([])

      assert Jason.decode!(conn.resp_body) == %{
               "data" => [%{"pet_type" => "Dog", "bark" => "bow wow"}]
             }
    end

    test "freeForm params" do
      conn =
        :get
        |> Plug.Test.conn("/api/utility/echo/any?one=this&two=cam&three=be&anything=true")
        |> OpenApiSpexTest.Router.call([])

      assert Jason.decode!(conn.resp_body) == %{
               "one" => "this",
               "two" => "cam",
               "three" => "be",
               "anything" => "true"
             }
    end

    test "send request body as json array is validated correctly" do
      request_body = [%{"one" => "this"}]

      conn =
        :post
        |> Plug.Test.conn("/api/utility/echo/body_params", Jason.encode!(request_body))
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> OpenApiSpexTest.Router.call([])

      # Phoenix parses json body params that start with array as structs starting with _json key
      # https://hexdocs.pm/plug/Plug.Parsers.JSON.html
      assert Jason.decode!(conn.resp_body) == %{"_json" => [%{"one" => "this"}]}
    end
  end
end
