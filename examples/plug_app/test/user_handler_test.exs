defmodule UserHandlerTest do
  use PlugApp.ConnCase

  alias PlugApp.Accounts
  alias PlugApp.Schemas
  alias PlugApp.Router

  @opts Router.init([])

  describe "GET /api/users" do
    setup do
      {:ok, user} = Accounts.create_user(%{name: "Joe", email: "joe@example.com"})

      %{user: user}
    end

    test "responds with 200 OK and a JSON body matching the API schema", %{
      user: %{id: user_id},
      api_spec: api_spec
    } do
      %{resp_body: body} =
        conn =
        conn(:get, "/api/users")
        |> Router.call(@opts)

      assert %{status: 200} = conn

      json_response = Jason.decode!(body)

      assert %{"data" => [%{"id" => ^user_id}]} = json_response

      assert_schema(json_response, "UsersResponse", api_spec)
    end
  end

  describe "GET /api/users/:id" do
    setup do
      {:ok, user} = Accounts.create_user(%{name: "Joe", email: "joe@example.com"})

      %{user: user}
    end

    test "responds with 200 OK and a JSON body matching the API schema", %{
      user: %{id: user_id},
      api_spec: api_spec
    } do
      %{resp_body: body} =
        conn =
        conn(:get, "/api/users/#{user_id}?foo=asd")
        |> Router.call(@opts)

      assert %{status: 200} = conn

      json_response = Jason.decode!(body)

      assert %{"data" => %{"id" => ^user_id}} = json_response

      assert_schema(json_response, "UserResponse", api_spec)
    end

    test "responds with 422 when there is no either foo nor bar in query params", %{
      user: %{id: user_id},
      api_spec: _api_spec
    } do
      %{resp_body: body} =
        conn =
        conn(:get, "/api/users/#{user_id}")
        |> Router.call(@opts)

      assert %{status: 422} = conn

      json_response = Jason.decode!(body)

      IO.inspect(json_response)
      # assert %{} = json_response

      # assert_schema(json_response, "UserResponse", api_spec)
    end
  end

  describe "POST /api/users" do
    @payload example(Schemas.UserRequest)

    test "responds with 201 Created and a JSON body matching the API schema", %{
      api_spec: api_spec
    } do
      %{resp_body: body} =
        conn =
        conn(:post, "/api/users", Jason.encode!(@payload))
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert %{status: 201} = conn

      json_response = Jason.decode!(body)

      assert_schema(json_response, "UserResponse", api_spec)
    end
  end

  describe "POST /api/users with invalid payload" do
    @payload %{
      user: %{
        email: "joe@example.com"
      }
    }

    test "responds with 422 Unprocessable Entity and a JSON body matching the API schema when ",
         %{
           api_spec: api_spec
         } do
      %{resp_body: body} =
        conn =
        conn(:post, "/api/users", Jason.encode!(@payload))
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert %{status: 422} = conn

      json_response = Jason.decode!(body)

      assert_schema(json_response, "JsonErrorResponse", api_spec)
    end
  end
end
